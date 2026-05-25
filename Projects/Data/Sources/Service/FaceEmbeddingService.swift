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
//
//public actor FaceEmbeddingService {
//
//    private let inputSize = CGSize(width: 112, height: 112)
//
//    private lazy var model: MLModel? = {
//        if let resourcePath = Bundle.module.resourcePath {
//            let files = try? FileManager.default.contentsOfDirectory(atPath: resourcePath)
//            print("현재 모듈 번들 내부 파일 목록: \(files ?? [])")
//        }
//        
//        guard let url = Bundle.module.url(forResource: "AdaFace_IR18", withExtension: "mlmodelc") else {
//            print("FaceEmbeddingService: AdaFace_IR18.mlpackage를 찾을 수 없음")
//            return nil
//        }
//        return try? MLModel(contentsOf: url)
//    }()
//
//    public init() { }
//
//    // MARK: - Public
//
//    public func extractEmbeddings(from image: CGImage) -> [FaceEmbedding] {
//        print("extractEmbeddings")
//        guard let observations = detectFaces(in: image), !observations.isEmpty else {
//            return []
//        }
//        print("extractEmbeddings", observations.count)
//        return observations.compactMap { extractEmbedding(from: image, observation: $0) }
//    }
//
//    // MARK: - Private
//
//    private func detectFaces(in image: CGImage) -> [VNFaceObservation]? {
//        let request = VNDetectFaceRectanglesRequest()
//        let handler = VNImageRequestHandler(cgImage: image, options: [:])
//        do {
//            try handler.perform([request])
//            return request.results?
////                .filter { $0.faceCaptureQuality ?? 0 >= 0.3 }
//                .filter { $0.boundingBox.width >= 0.05 && $0.boundingBox.height >= 0.05 }
//        } catch {
//            print("FaceEmbeddingService detectFaces 에러:", error)
//            return nil
//        }
//    }
//
//    private func extractEmbedding(from image: CGImage, observation: VNFaceObservation) -> FaceEmbedding? {
//        guard let cropped = cropFace(from: image, boundingBox: observation.boundingBox),
//              let resized = resize(image: cropped, to: inputSize),
//              let embedding = runModel(on: resized) else {
//            return nil
//        }
//        return FaceEmbedding(embedding: embedding, boundingBox: observation.boundingBox)
//    }
//
//    private func cropFace(from image: CGImage, boundingBox: CGRect) -> CGImage? {
//        let width = CGFloat(image.width)
//        let height = CGFloat(image.height)
//        let rect = CGRect(
//            x: boundingBox.minX * width,
//            y: (1 - boundingBox.maxY) * height,
//            width: boundingBox.width * width,
//            height: boundingBox.height * height
//        )
//        return image.cropping(to: rect)
//    }
//
//    private func resize(image: CGImage, to size: CGSize) -> CGImage? {
//        let context = CGContext(
//            data: nil,
//            width: Int(size.width),
//            height: Int(size.height),
//            bitsPerComponent: image.bitsPerComponent,
//            bytesPerRow: 0,
//            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
//            bitmapInfo: image.bitmapInfo.rawValue
//        )
//        context?.draw(image, in: CGRect(origin: .zero, size: size))
//        return context?.makeImage()
//    }
//
//    private func runModel(on image: CGImage) -> [Float]? {
//        guard let model,
//              let pixelBuffer = image.toPixelBuffer(),
//              let input = try? MLDictionaryFeatureProvider(dictionary: ["face_image": pixelBuffer]),
//              let output = try? model.prediction(from: input),
//              let multiArray = output.featureValue(for: "embedding")?.multiArrayValue else {
//            return nil
//        }
//
//        let count = multiArray.count
//        var result = [Float](repeating: 0, count: count)
//        for i in 0..<count {
//            result[i] = multiArray[i].floatValue
//        }
//        return l2Normalize(result)
//    }
//
//    private func l2Normalize(_ vector: [Float]) -> [Float] {
//        let norm = sqrt(vector.map { $0 * $0 }.reduce(0, +))
//        guard norm > 0 else { return vector }
//        return vector.map { $0 / norm }
//    }
//}
//
//// MARK: - CGImage Extension
//private extension CGImage {
//    func toPixelBuffer() -> CVPixelBuffer? {
//        let width = self.width
//        let height = self.height
//
//        var pixelBuffer: CVPixelBuffer?
//        let status = CVPixelBufferCreate(
//            kCFAllocatorDefault,
//            width, height,
//            kCVPixelFormatType_32ARGB,
//            [kCVPixelBufferCGImageCompatibilityKey: true,
//             kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary,
//            &pixelBuffer
//        )
//        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
//
//        CVPixelBufferLockBaseAddress(buffer, [])
//        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
//
//        let context = CGContext(
//            data: CVPixelBufferGetBaseAddress(buffer),
//            width: width,
//            height: height,
//            bitsPerComponent: 8,
//            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
//            space: CGColorSpaceCreateDeviceRGB(),
//            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
//        )
//        context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
//        return buffer
//    }
//}

import UIKit

public actor FaceEmbeddingService {

    private let inputSize = CGSize(width: 112, height: 112)

    private lazy var model: MLModel? = {
        guard let url = Bundle.module.url(forResource: "AdaFace_IR18", withExtension: "mlmodelc") else {
            print("FaceEmbeddingService: AdaFace_IR18.mlmodelc를 찾을 수 없음")
            return nil
        }
        return try? MLModel(contentsOf: url, configuration: MLModelConfiguration())
    }()

    public init() { }

    // MARK: - Public

    public func extractEmbeddings(from image: CGImage) async -> [FaceEmbedding] {
        guard let observations = detectFacesWithLandmarks(in: image),
              !observations.isEmpty else {
            return []
        }

        var embeddings: [FaceEmbedding] = []
        for observation in observations {
//            if Int.random(in: 1...10) == 4 {
//                saveDebugCrop(image, boundingBox: observation.boundingBox)
//            }
            if let embedding = extractEmbedding(from: image, observation: observation) {
                embeddings.append(embedding)
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
//                print("faceCaptureQuality", $0.faceCaptureQuality ?? "???")
//                print("yaw", $0.yaw ?? "???")
                return $0.boundingBox.width >= 0.05 && $0.boundingBox.height >= 0.05
                && abs($0.yaw?.floatValue ?? 1.0) < 0.5
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
        return FaceEmbedding(embedding: embedding, boundingBox: observation.boundingBox)
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
        
        let scale: CGFloat = 1.1
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
//    private func cropFace(from image: CGImage, boundingBox: CGRect) -> CGImage? {
//        let width = CGFloat(image.width)
//        let height = CGFloat(image.height)
//        let rect = CGRect(
//            x: boundingBox.minX * width,
//            y: (1.0 - boundingBox.minY - boundingBox.height) * height,
//            width: boundingBox.width * width,
//            height: boundingBox.height * height
//        )
//        return image.cropping(to: rect)
//    }

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
