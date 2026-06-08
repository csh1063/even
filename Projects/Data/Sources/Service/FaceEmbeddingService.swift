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

public actor FaceEmbeddingService {

    private let inputSize = CGSize(width: 112, height: 112)

    private lazy var model: MLModel? = {
        guard let url = Bundle.module.url(forResource: "AdaFace_IR50", withExtension: "mlmodelc") else {
            print("FaceEmbeddingService: AdaFace_IR18.mlmodelc를 찾을 수 없음")
            return nil
        }
        return try? MLModel(contentsOf: url, configuration: MLModelConfiguration())
    }()

    public init() { }

    // MARK: - Public

    public func extractEmbeddings(from image: CGImage, hasGlass: Bool = false) async -> [FaceEmbedding] {
        guard let observations = detectFacesWithLandmarks(in: image),
              !observations.isEmpty else {
            return []
        }

        var embeddings: [FaceEmbedding] = []
        for observation in observations {
//            if Int.random(in: 1...10) == 4 {
//                saveDebugCrop(image, boundingBox: observation.boundingBox)
//            }
            if hasGlass {
                if let embedding = extractEmbeddingWithGlass(from: image, observation: observation) {
                    embeddings.append(embedding)
                }
            } else {
                if let embedding = extractEmbedding(from: image, observation: observation) {
                    embeddings.append(embedding)
                }
            }
        }
        return embeddings
    }
    
    private var debugSaveCount = 0
    
    private func saveDebugCrop(_ image: CGImage, boundingBox: CGRect) {
        guard debugSaveCount < 20 else { return }
        guard let cropped = cropFace(from: image, boundingBox: boundingBox) else { return }
        let uiImage = UIImage(cgImage: cropped)
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        debugSaveCount += 1
    }

    // MARK: - Private: Detection

    // VNDetectFaceRectanglesRequest → VNDetectFaceLandmarksRequest 로 교체
    private func detectFacesWithLandmarks(in image: CGImage) -> [VNFaceObservation]? {
        // landmarks 요청은 내부적으로 face detection도 수행함
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            return request.results?.filter {
                $0.boundingBox.width >= 0.05 && $0.boundingBox.height >= 0.05
                && abs($0.yaw?.floatValue ?? 1.0) < 0.9
                && $0.boundingBox.width * CGFloat(image.width) >= 100.0
                && !isFaceTruncated($0.boundingBox)
                && hasCompleteLandmarks($0)
            }
        } catch {
            print("FaceEmbeddingService detectFacesWithLandmarks 에러:", error)
            return nil
        }
    }

    // MARK: - Private: Embedding
    private func extractEmbedding(from image: CGImage, observation: VNFaceObservation) -> FaceEmbedding? {
        guard let cropped = cropFace(from: image, boundingBox: observation.boundingBox) else {
            return nil
        }
        
        let hasGlasses = hasGlasses(in: cropped)
        if hasGlasses {
            print("🕶️ 안경 감지 → 클러스터링 제외")
//            return nil
        }

        // landmark가 있으면 alignment 적용, 없으면 crop만 사용
        let aligned: CGImage
        if let landmarks = observation.landmarks {
            aligned = alignFace(image: cropped, landmarks: landmarks, boundingBox: observation.boundingBox) ?? cropped
        } else {
            aligned = cropped
        }

        guard let resized = resize(image: aligned, to: inputSize),
              let embedding = runModel(on: resized) else {
            return nil
        }
        return FaceEmbedding(embedding: embedding, boundingBox: observation.boundingBox, hasGlasses: hasGlasses)
    }
    
    func extractEmbeddingWithGlass(from image: CGImage, observation: VNFaceObservation) -> FaceEmbedding? {
        guard let cropped = cropFace(from: image, boundingBox: observation.boundingBox) else {
            return nil
        }

        // 크롭 단계에서 안경 체크 (aligned 전)
        let hasGlasses = hasGlasses(in: cropped)
        if hasGlasses {
            print("🕶️ 안경 감지 → 클러스터링 제외")
//            return nil
        }

//        saveDebugCrop(image, boundingBox: observation.boundingBox)
        // 안경 없는 얼굴만 계속 진행
        let aligned: CGImage
        if let landmarks = observation.landmarks {
            aligned = alignFace(image: cropped, landmarks: landmarks, boundingBox: observation.boundingBox) ?? cropped
        } else {
            aligned = cropped
        }
//        saveDebugCrop(image, boundingBox: observation.boundingBox)


        guard let resized = resize(image: aligned, to: inputSize),
              let embedding = runModel(on: resized) else {
            return nil
        }
        return FaceEmbedding(embedding: embedding, boundingBox: observation.boundingBox, hasGlasses: hasGlasses)
    }

    // MARK: - Private: Alignment

    private func alignFace(image: CGImage, landmarks: VNFaceLandmarks2D, boundingBox: CGRect) -> CGImage? {
        // 양쪽 눈 중심점 추출
        guard let leftPupil = landmarks.leftPupil ?? landmarks.leftEye,
              let rightPupil = landmarks.rightPupil ?? landmarks.rightEye else {
            // 눈 랜드마크 없으면 alignment 스킵
            return nil
        }

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)

        // VNFaceLandmarks2D 좌표는 boundingBox 기준 정규화 좌표
        // → crop된 이미지 기준 픽셀 좌표로 변환 필요
        // crop 이미지 크기 = boundingBox 크기 * 원본 이미지 크기
        let cropWidth = boundingBox.width * imageWidth
        let cropHeight = boundingBox.height * imageHeight

        func toPixel(_ point: CGPoint) -> CGPoint {
            // landmark 좌표는 boundingBox 내부 정규화 (0~1)
            // CGImage는 좌상단 기준이므로 Y축 반전
            return CGPoint(
                x: point.x * cropWidth,
                y: (1.0 - point.y) * cropHeight
            )
        }

        // 눈 중심 = 해당 눈의 landmark 포인트들 평균
        let leftCenter = averagePoint(of: leftPupil.normalizedPoints, transform: toPixel)
        let rightCenter = averagePoint(of: rightPupil.normalizedPoints, transform: toPixel)

        // 두 눈 중심을 잇는 각도 계산
        let dx = rightCenter.x - leftCenter.x
        let dy = rightCenter.y - leftCenter.y
        let angle = atan2(dy, dx) // 라디안

        // 회전이 의미있는 경우만 적용 (1도 이상)
        guard abs(angle) > .pi / 180 else { return image }

        return rotateImage(image, by: -angle, around: CGPoint(x: cropWidth / 2, y: cropHeight / 2))
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

        // 중심점 기준 회전 transform
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
        
        // 이미지 경계 벗어나지 않도록 클램핑
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
        
        // CVPixelBuffer 변환 없이 CGImage 직접 사용
        guard let input = try? MLDictionaryFeatureProvider(dictionary: [
            "face_image": MLFeatureValue(cgImage: image, pixelsWide: 112, pixelsHigh: 112, pixelFormatType: kCVPixelFormatType_32BGRA, options: nil)
        ]) else { return nil }
        
        guard let output = try? model.prediction(from: input),
              let multiArray = output.featureValue(for: "embedding")?.multiArrayValue else {
            return nil
        }

        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        for i in 0..<count {
            result[i] = multiArray[i].floatValue
        }
        return l2Normalize(result)
    }

    private func l2Normalize(_ vector: [Float]) -> [Float] {
        let norm = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        guard norm > 0 else { return vector }
        return vector.map { $0 / norm }
    }
    
    private func hasGlasses(in image: CGImage) -> Bool {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return false
        }

        let glassesIdentifiers: Set<String> = ["sunglasses", "goggles"]// ["eyeglasses", "sunglasses", "goggles"]

//        // 로그 — 안정되면 제거
//        request.results?.filter { glassesIdentifiers.contains($0.identifier) }.forEach {
//            print("🔍 glasses label: \($0.identifier), confidence: \($0.confidence)")
//        }

        return request.results?.contains {
            glassesIdentifiers.contains($0.identifier) && $0.confidence >= 0.25
        } ?? false
    }
    
    private func isFaceTruncated(_ boundingBox: CGRect) -> Bool {
        let margin: CGFloat = 0.02 // 2% 여유
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

// MARK: - CGImage Extension

private extension CGImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        let width = self.width
        let height = self.height

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferCGImageCompatibilityKey: true,
             kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            // 수정: 32BGRA에 맞는 올바른 bitmapInfo
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}
