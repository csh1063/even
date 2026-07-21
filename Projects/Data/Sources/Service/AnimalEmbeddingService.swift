//
//  AnimalEmbeddingService.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  FaceEmbeddingService와 같은 역할을 동물(개/고양이)에 대해 한다. 다른 점은:
//  - 탐지: VNRecognizeAnimalsRequest (바운딩 박스 + 종 라벨만 줌, 랜드마크 없음)
//  - 정렬: 랜드마크가 없어서 눈 좌표 기반 정렬(alignToCanonical)이 불가능 — 크롭 + 리사이즈만 한다
//  - 화질 신호: VNDetectFaceCaptureQualityRequest 같은 전용 API가 없어서 탐지 confidence로 대신한다
//  - 모델: AnimalReID_DINOv2 (384차원, 입력 224x224) — AdaFace_IR50과 마찬가지로 원시 임베딩을 반환하고
//    L2 정규화는 여기서 Accelerate로 처리한다 (모델 출력 자체는 정규화 전 상태)

import CoreML
import Vision
import CoreGraphics
import Foundation
import Domain
import Accelerate

public actor AnimalEmbeddingService {

    private let inputSize = CGSize(width: 224, height: 224)

    private lazy var model: MLModel? = {
        guard let url = Bundle.module.url(forResource: "AnimalReID_DINOv2", withExtension: "mlmodelc") else {
            print("AnimalEmbeddingService: AnimalReID_DINOv2.mlmodelc를 찾을 수 없음")
            return nil
        }
        return try? MLModel(contentsOf: url, configuration: MLModelConfiguration())
    }()

    private lazy var fallbackModel: MLModel? = {
        guard let url = Bundle.module.url(forResource: "AnimalReID_DINOv2", withExtension: "mlmodelc") else {
            return nil
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndGPU
        return try? MLModel(contentsOf: url, configuration: configuration)
    }()

    public init() { }

    // MARK: - Public

    public func extractEmbeddings(from image: CGImage) async -> [AnimalEmbedding] {
        guard let observations = detectAnimals(in: image), !observations.isEmpty else {
            return []
        }

        var embeddings: [AnimalEmbedding] = []
        for (index, observation) in observations.enumerated() {
            let otherBoxes = observations.enumerated()
                .filter { $0.offset != index }
                .map { $0.element.boundingBox }
            if let embedding = extractEmbedding(from: image, observation: observation, otherBoxes: otherBoxes) {
                embeddings.append(embedding)
            }
        }
        return embeddings
    }

    // MARK: - Private: Detection

    private struct AnimalDetection {
        let boundingBox: CGRect
        let species: AnimalSpecies
        let confidence: Float
    }

    private func detectAnimals(in image: CGImage) -> [AnimalDetection]? {
        let request = VNRecognizeAnimalsRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            return request.results?.compactMap { observation -> AnimalDetection? in
                guard let topLabel = observation.labels.first else { return nil }
                let species: AnimalSpecies
                switch topLabel.identifier {
                case VNAnimalIdentifier.dog.rawValue: species = .dog
                case VNAnimalIdentifier.cat.rawValue: species = .cat
                default: return nil
                }
                guard topLabel.confidence >= 0.6,
                      observation.boundingBox.width >= 0.05 && observation.boundingBox.height >= 0.05,
                      observation.boundingBox.width * CGFloat(image.width) >= 100.0
                else { return nil }
                return AnimalDetection(boundingBox: observation.boundingBox, species: species, confidence: topLabel.confidence)
            }
        } catch {
            print("AnimalEmbeddingService detectAnimals 에러:", error)
            return nil
        }
    }

    // MARK: - Private: Embedding

    private func extractEmbedding(from image: CGImage, observation: AnimalDetection, otherBoxes: [CGRect]) -> AnimalEmbedding? {
        guard let cropped = cropAnimal(from: image, boundingBox: observation.boundingBox, otherBoxes: otherBoxes),
              let resized = resize(image: cropped, to: inputSize),
              let embedding = runModel(on: resized) else {
            return nil
        }
        return AnimalEmbedding(
            embedding: embedding,
            boundingBox: observation.boundingBox,
            species: observation.species,
            detectionConfidence: observation.confidence
        )
    }

    // MARK: - Private: Crop / Resize

    private func cropAnimal(from image: CGImage, boundingBox: CGRect, otherBoxes: [CGRect] = []) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        // 랜드마크 정렬이 없어서 얼굴보다 넉넉하게 여백을 둔다 (동물 전신/머리 박스는 사람 얼굴 박스보다 헐거움)
        let scale: CGFloat = 1
        let expandedWidth = boundingBox.width * scale
        let expandedHeight = boundingBox.height * scale

        var minX = boundingBox.minX - (expandedWidth - boundingBox.width) / 2
        var maxX = minX + expandedWidth
        var minY = boundingBox.minY - (expandedHeight - boundingBox.height) / 2
        var maxY = minY + expandedHeight

        // 같은 사진에 다른 동물이 있으면 그쪽 방향으로는 마진을 확대하지 않는다 — 크롭에 다른 개체가
        // 섞여 들어가면 임베딩이 오염돼서 서로 다른 종/개체가 비슷하게 나오는 원인이 된다.
        // 원본 탐지 박스보다 안쪽으로는 절대 줄이지 않는다(Vision이 준 탐지 결과는 그대로 신뢰)
        for other in otherBoxes {
            let dx = other.midX - boundingBox.midX
            let dy = other.midY - boundingBox.midY

            if abs(dx) >= abs(dy) {
                if dx > 0 {
                    let boundary = max(boundingBox.maxX, (boundingBox.maxX + other.minX) / 2)
                    maxX = min(maxX, boundary)
                } else {
                    let boundary = min(boundingBox.minX, (boundingBox.minX + other.maxX) / 2)
                    minX = max(minX, boundary)
                }
            } else {
                if dy > 0 {
                    let boundary = max(boundingBox.maxY, (boundingBox.maxY + other.minY) / 2)
                    maxY = min(maxY, boundary)
                } else {
                    let boundary = min(boundingBox.minY, (boundingBox.minY + other.maxY) / 2)
                    minY = max(minY, boundary)
                }
            }
        }

        let clampedX = max(0, minX)
        let clampedY = max(0, minY)
        let clampedWidth = min(maxX - minX, 1.0 - clampedX)
        let clampedHeight = min(maxY - minY, 1.0 - clampedY)

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
            "animal_image": MLFeatureValue(cgImage: image, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32BGRA, options: nil)
        ]) else { return nil }

        let output: MLFeatureProvider
        do {
            output = try model.prediction(from: input)
        } catch {
            print("⚠️ AnimalEmbeddingService model.prediction 실패, 같은 모델로 재시도:", error)
            if let retried = try? model.prediction(from: input) {
                output = retried
            } else {
                print("⚠️ AnimalEmbeddingService 재시도 실패, CPU+GPU로 재시도")
                guard let fallbackModel, let fallbackRetried = try? fallbackModel.prediction(from: input) else {
                    print("⚠️ AnimalEmbeddingService 모든 재시도 실패 (임베딩 유실됨)")
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
}
