//
//  FaceEmbeddingService.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreML
import Vision
import CoreGraphics
import Foundation
import Domain
import UIKit
import Accelerate

public actor FaceEmbeddingService {

    private let inputSize = CGSize(width: 112, height: 112)

    // ArcFace/InsightFace 계열 모델이 학습에 쓰는 표준 112x112 정렬 기준 눈 좌표 (회전만이 아니라 스케일/이동까지 정규화하기 위함).
    // 원본 레퍼런스 값(38.2946, 51.6963 / 73.5318, 51.5014)은 좌상단 원점(Y 아래로 증가) 기준인데,
    // alignToCanonical은 CGContext(좌하단 원점, Y 위로 증가)에 그대로 그리므로 Y를 112 기준으로 뒤집어서 보관한다.
    private let canonicalLeftEye = CGPoint(x: 38.2946, y: 112 - 51.6963)
    private let canonicalRightEye = CGPoint(x: 73.5318, y: 112 - 51.5014)

    private lazy var model: MLModel? = {
        guard let url = Bundle.module.url(forResource: "AdaFace_IR50", withExtension: "mlmodelc") else {
            debugLog("FaceEmbeddingService: AdaFace_IR50.mlmodelc를 찾을 수 없음")
            return nil
        }
        return try? MLModel(contentsOf: url, configuration: MLModelConfiguration())
    }()

    // 기본(ANE 포함) 모델이 정렬 검증 실패 등으로 예측에 실패했을 때만 재시도용으로 쓰는 CPU+GPU 전용 모델.
    // 평소엔 안 쓰이고, 실패한 사진 한 장에 한해서만 느리더라도 안전하게 다시 시도하기 위함
    private lazy var fallbackModel: MLModel? = {
        guard let url = Bundle.module.url(forResource: "AdaFace_IR50", withExtension: "mlmodelc") else {
            return nil
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndGPU
        return try? MLModel(contentsOf: url, configuration: configuration)
    }()

    public init() { }

    // MARK: - Public

    // hasGlass는 더 이상 필터링에 쓰지 않음 — 안경 여부는 얼굴마다 embedding.hasGlasses로 이미 담겨 있고,
    // 실제 제외는 DefaultFaceClusterRepository에서 클러스터링 대상으로 쓸 때 처리한다.
    // 여기서 photo 단위로 걸러버리면 안경 쓴 사람이 한 명이라도 있는 사진에서 다른 사람 얼굴까지 통째로 버려진다.
    public func extractEmbeddings(from image: CGImage, hasGlass: Bool = false) async -> [FaceEmbedding] {
        guard let observations = detectFacesWithLandmarks(in: image),
              !observations.isEmpty else {
            return []
        }

        var embeddings: [FaceEmbedding] = []
        for (observation, captureQuality) in observations {
            if let embedding = extractEmbedding(from: image, observation: observation, captureQuality: captureQuality) {
                embeddings.append(embedding)
            }
        }
        return embeddings
    }

    // MARK: - Private: Detection

    private func detectFacesWithLandmarks(in image: CGImage) -> [(observation: VNFaceObservation, captureQuality: Float)]? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            // VNDetectFaceCaptureQualityRequest도 자체적으로 이미지 전체에서 얼굴을 찾아주므로,
            // 얼굴 후보마다 따로 돌리지 않고 이미지당 한 번만 실행해서 boundingBox로 매칭한다.
            let qualityObservations = faceCaptureQualityObservations(in: image)
            return request.results?.compactMap { observation -> (VNFaceObservation, Float)? in
                let quality = matchedFaceCaptureQuality(for: observation.boundingBox, in: qualityObservations) ?? 0
                guard observation.boundingBox.width >= 0.05 && observation.boundingBox.height >= 0.05
                    && observation.confidence >= 0.6
                    && abs(observation.yaw?.floatValue ?? 1.0) < 0.9
                    && observation.boundingBox.width * CGFloat(image.width) >= 100.0
                    && !isFaceTruncated(observation.boundingBox)
                    && hasCompleteLandmarks(observation)
                    && quality >= 0.2
                else { return nil }
                return (observation, quality)
            }
        } catch {
            debugLog("FaceEmbeddingService detectFacesWithLandmarks 에러: \(error)")
            return nil
        }
    }

    // VNDetectFaceLandmarksRequest의 confidence는 사실상 항상 1.0이라 쓸모없어서,
    // Apple이 얼굴 품질 평가용으로 따로 제공하는 VNDetectFaceCaptureQualityRequest를 이미지당 한 번만 돌려서 대신 쓴다.
    // (regionOfInterest 없이 돌리면 이 요청도 이미지 전체에서 자체적으로 얼굴을 찾아준다)
    private func faceCaptureQualityObservations(in image: CGImage) -> [VNFaceObservation] {
        let request = VNDetectFaceCaptureQualityRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            return request.results ?? []
        } catch {
            return []
        }
    }

    // landmarks 검출기와 quality 검출기는 서로 다른 모델이라 결과가 어긋날 수 있으므로,
    // 실제로 boundingBox가 겹치는 후보 중 가장 많이 겹치는 것만 매칭한다 (엉뚱한 옆 얼굴과 매칭되는 것 방지)
    private func matchedFaceCaptureQuality(for boundingBox: CGRect, in qualityObservations: [VNFaceObservation]) -> Float? {
        qualityObservations
            .filter { $0.boundingBox.intersects(boundingBox) }
            .max(by: {
                let areaA = $0.boundingBox.intersection(boundingBox).width * $0.boundingBox.intersection(boundingBox).height
                let areaB = $1.boundingBox.intersection(boundingBox).width * $1.boundingBox.intersection(boundingBox).height
                return areaA < areaB
            })
            .flatMap { $0.faceCaptureQuality }
    }

    // MARK: - Private: Embedding
    
    private func extractEmbedding(from image: CGImage, observation: VNFaceObservation, captureQuality: Float) -> FaceEmbedding? {
        // 안경 판별용 크롭은 정렬 전 원본 기준으로 — 해상도가 더 높아서 판별에 유리하고, 정렬 방식과 무관하게 일정하게 유지
        guard let cropped = cropFace(from: image, boundingBox: observation.boundingBox) else {
            return nil
        }

//        if isBabyFace(in: cropped) {
//            return nil
//        }

        let hasGlasses = hasGlasses(in: cropped)
        if hasGlasses {
            debugLog("🕶️ 안경 감지")
        }

        // 눈 사이 거리까지 정규화하는 정식 정렬(회전+스케일+이동)이 가능하면 그걸 쓰고,
        // 랜드마크가 부족해서 안 되면 기존 회전만 하는 방식 + crop + resize로 폴백
        let modelInput: CGImage
        if let landmarks = observation.landmarks,
           let canonical = alignToCanonical(image: image, boundingBox: observation.boundingBox, landmarks: landmarks) {
            modelInput = canonical
        } else {
            let alignedImage: CGImage
            if let landmarks = observation.landmarks {
                alignedImage = alignFace(image: image, landmarks: landmarks, boundingBox: observation.boundingBox) ?? image
            } else {
                alignedImage = image
            }
            guard let fallbackCropped = cropFace(from: alignedImage, boundingBox: observation.boundingBox),
                  let resized = resize(image: fallbackCropped, to: inputSize) else {
                return nil
            }
            modelInput = resized
        }

        guard let embedding = runModel(on: modelInput) else {
            return nil
        }

        return FaceEmbedding(embedding: embedding, boundingBox: observation.boundingBox, hasGlasses: hasGlasses, captureQuality: captureQuality)
    }

    // MARK: - Private: Alignment (구조 개편)

    // 회전만 하던 alignFace와 달리, 두 눈 사이 거리를 기준 좌표(canonicalLeftEye/RightEye)에 맞춰
    // 회전+스케일+이동까지 한 번에 정규화한다. 원본 이미지에서 바로 112x112로 워프하므로
    // crop → rotate → resize를 거치며 생기는 손실도 줄어든다.
    private func alignToCanonical(image: CGImage, boundingBox: CGRect, landmarks: VNFaceLandmarks2D) -> CGImage? {
        guard let leftPupil = landmarks.leftPupil ?? landmarks.leftEye,
              let rightPupil = landmarks.rightPupil ?? landmarks.rightEye,
              !leftPupil.normalizedPoints.isEmpty, !rightPupil.normalizedPoints.isEmpty else {
            return nil
        }

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)

        // landmark 좌표는 boundingBox 기준 정규화(0~1, Vision 좌표계=좌하단 원점) → 원본 이미지 픽셀 좌표로 변환.
        // 여기서 나온 좌표는 CGContext/CGAffineTransform(좌하단 원점, Y 위로 증가)에 바로 쓰이므로
        // cropFace(.cropping(to:)용, 좌상단 원점)처럼 Y를 뒤집으면 안 된다 — 뒤집으면 눈 위치가 완전히 어긋난다.
        func toOriginalPixel(_ point: CGPoint) -> CGPoint {
            let actualX = (boundingBox.minX + (point.x * boundingBox.width)) * imageWidth
            let actualY = (boundingBox.minY + (point.y * boundingBox.height)) * imageHeight
            return CGPoint(x: actualX, y: actualY)
        }

        let leftEye = averagePoint(of: leftPupil.normalizedPoints, transform: toOriginalPixel)
        let rightEye = averagePoint(of: rightPupil.normalizedPoints, transform: toOriginalPixel)

        let srcDx = rightEye.x - leftEye.x
        let srcDy = rightEye.y - leftEye.y
        let srcMagSq = srcDx * srcDx + srcDy * srcDy
        guard srcMagSq > 0 else { return nil }

        let dstDx = canonicalRightEye.x - canonicalLeftEye.x
        let dstDy = canonicalRightEye.y - canonicalLeftEye.y

        // (kx, ky) = 두 눈 벡터를 기준 벡터에 맞추는 복소수 곱(회전 + 스케일)
        let kx = (dstDx * srcDx + dstDy * srcDy) / srcMagSq
        let ky = (dstDy * srcDx - dstDx * srcDy) / srcMagSq

        // leftEye를 canonicalLeftEye로 옮기는 이동값
        let tx = canonicalLeftEye.x - (kx * leftEye.x - ky * leftEye.y)
        let ty = canonicalLeftEye.y - (ky * leftEye.x + kx * leftEye.y)

        let transform = CGAffineTransform(a: kx, b: ky, c: -ky, d: kx, tx: tx, ty: ty)

        let outputSize = Int(inputSize.width)
        guard let context = CGContext(
            data: nil,
            width: outputSize,
            height: outputSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        context.concatenate(transform)
        context.draw(image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))

        return context.makeImage()
    }

    private func alignFace(image: CGImage, landmarks: VNFaceLandmarks2D, boundingBox: CGRect) -> CGImage? {
        guard let leftPupil = landmarks.leftPupil ?? landmarks.leftEye,
              let rightPupil = landmarks.rightPupil ?? landmarks.rightEye else {
            return nil
        }

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)

        // rotateImage도 CGContext 기반이라 좌하단 원점(Y 위로 증가) 좌표가 필요하다 — Y를 뒤집으면 안 된다.
        func toOriginalPixel(_ point: CGPoint) -> CGPoint {
            let actualX = (boundingBox.minX + (point.x * boundingBox.width)) * imageWidth
            let actualY = (boundingBox.minY + (point.y * boundingBox.height)) * imageHeight
            return CGPoint(x: actualX, y: actualY)
        }

        let leftCenter = averagePoint(of: leftPupil.normalizedPoints, transform: toOriginalPixel)
        let rightCenter = averagePoint(of: rightPupil.normalizedPoints, transform: toOriginalPixel)

        let dx = rightCenter.x - leftCenter.x
        let dy = rightCenter.y - leftCenter.y
        let angle = atan2(dy, dx)

        guard abs(angle) > .pi / 180 else { return image }

        // 얼굴 중앙 지점을 축으로 삼아 원본을 회전시킵니다.
        let faceCenterX = (boundingBox.minX + boundingBox.width / 2) * imageWidth
        let faceCenterY = (boundingBox.minY + boundingBox.height / 2) * imageHeight

        return rotateImage(image, by: -angle, around: CGPoint(x: faceCenterX, y: faceCenterY))
    }

    private func averagePoint(
        of points: [CGPoint],
        transform: (CGPoint) -> CGPoint
    ) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let transformed = points.map(transform)
        let sum = transformed.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    private func rotateImage(_ image: CGImage, by angle: CGFloat, around center: CGPoint) -> CGImage? {
        let width = image.width
        let height = image.height

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        guard let ctx = context else { return nil }

        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)
        ctx.translateBy(x: -center.x, y: -center.y)

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }

    // MARK: - Private: Crop / Resize
    
    private func cropFace(from image: CGImage, boundingBox: CGRect) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let scale: CGFloat = 1.3
        let expandedWidth = boundingBox.width * scale
        let expandedHeight = boundingBox.height * scale
        let expandedX = boundingBox.minX - (expandedWidth - boundingBox.width) / 2
        let expandedY = boundingBox.minY - (expandedHeight - boundingBox.height) / 2

        let clampedX = max(0, expandedX)
        let clampedY = max(0, expandedY)
        let clampedWidth = min(expandedWidth, 1.0 - clampedX)
        let clampedHeight = min(expandedHeight, 1.0 - clampedY)

        let rect = CGRect(
            x: clampedX * width,
            y: (1.0 - clampedY - clampedHeight) * height,
            width: clampedWidth * width,
            height: clampedHeight * height
        )
        return image.cropping(to: rect)
    }

    private func resize(image: CGImage, to size: CGSize) -> CGImage? {
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        context?.draw(image, in: CGRect(origin: .zero, size: size))
        return context?.makeImage()
    }

    // MARK: - Private: Model
    
    private func runModel(on image: CGImage) -> [Float]? {
        guard let model else { return nil }
        
        guard let input = try? MLDictionaryFeatureProvider(dictionary: [
            "face_image": MLFeatureValue(cgImage: image, pixelsWide: 112, pixelsHigh: 112, pixelFormatType: kCVPixelFormatType_32BGRA, options: nil)
        ]) else { return nil }

        let output: MLFeatureProvider
        do {
            output = try model.prediction(from: input)
        } catch {
            // 수만 장 처리하는 중 순간적으로 나는 문제일 수 있어서, 같은(ANE 포함) 모델로 한 번 더 시도
            debugLog("⚠️ FaceEmbeddingService model.prediction 실패, 같은 모델로 재시도: \(error)")
            if let retried = try? model.prediction(from: input) {
                output = retried
            } else {
                // 그래도 안 되면 CPU+GPU 전용 모델로 마지막 시도
                debugLog("⚠️ FaceEmbeddingService 재시도 실패, CPU+GPU로 재시도")
                guard let fallbackModel, let fallbackRetried = try? fallbackModel.prediction(from: input) else {
                    debugLog("⚠️ FaceEmbeddingService 모든 재시도 실패 (임베딩 유실됨)")
                    return nil
                }
                output = fallbackRetried
            }
        }

        guard let multiArray = output.featureValue(for: "embedding")?.multiArrayValue else {
            return nil
        }

        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        for i in 0..<count {
            result[i] = multiArray[i].floatValue
        }
        return l2Normalize(result)
    }

    // 💡 해결책 3: Accelerate 하드웨어 연산으로 교체하여 속도 극대화
    private func l2Normalize(_ vector: [Float]) -> [Float] {
        var normSquared: Float = 0
        vDSP_svesq(vector, 1, &normSquared, vDSP_Length(vector.count))
        let norm = sqrt(normSquared)
        
        guard norm > 0 else { return vector }
        var result = [Float](repeating: 0, count: vector.count)
        var n = norm
        vDSP_vsdiv(vector, 1, &n, &result, 1, vDSP_Length(vector.count))
        return result
    }

    private func hasGlasses(in image: CGImage) -> Bool {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return false
        }

        let glassesIdentifiers: Set<String> = ["sunglasses", "goggles"]

        return request.results?.contains {
            glassesIdentifiers.contains($0.identifier) && $0.confidence >= 0.25
        } ?? false
    }

    private func isBabyFace(in image: CGImage) -> Bool {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return false
        }

        let babyIdentifiers: Set<String> = ["baby"]

        return request.results?.contains {
            babyIdentifiers.contains($0.identifier) && $0.confidence >= 0.25
        } ?? false
    }

    private func isFaceTruncated(_ boundingBox: CGRect) -> Bool {
        let margin: CGFloat = 0.02
        return boundingBox.minX < margin ||
               boundingBox.minY < margin ||
               boundingBox.maxX > 1.0 - margin ||
               boundingBox.maxY > 1.0 - margin
    }

    private func hasCompleteLandmarks(_ observation: VNFaceObservation) -> Bool {
        guard let landmarks = observation.landmarks else { return false }
        return landmarks.leftEye != nil &&
               landmarks.rightEye != nil &&
               landmarks.nose != nil &&
               landmarks.outerLips != nil
    }
}
