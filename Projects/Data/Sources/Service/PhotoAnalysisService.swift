//
//  PhotoAnalysisService.swift
//  Data
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import Vision
import CoreGraphics

public final class PhotoAnalysisService { // : @unchecked Sendable {

    private var removeKeywords: [String] = {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "RemoveKeywords", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let array = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return array
    }()

    private let classifyQueue = DispatchQueue(label: "com.app.analysis.classify")
    private let faceQueue = DispatchQueue(label: "com.app.analysis.face")
    private let textQueue = DispatchQueue(label: "com.app.analysis.text")
    private let barcodeQueue = DispatchQueue(label: "com.app.analysis.barcode")

    public init() { }

    // MARK: - Public

    public func analyze(image: CGImage) async throws -> [PhotoLabel] {
        async let objectLabels = classifyImage(image)   // 방법 3 - Vision 분류기
        async let faceLabels = detectFace(image)        // 방법 2 - 얼굴 감지
        async let textLabels = detectText(image)        // 방법 2 - 텍스트 감지
//        async let barcodeLabels = detectBarcode(image)  // 방법 2 - 바코드 감지

        let all = try await objectLabels + faceLabels + textLabels // + barcodeLabels

        // 중복 제거 (같은 name이면 confidence 높은 것 유지)
        return deduplicated(all)
    }

    // MARK: - Private
    /// Vision 이미지 분류기 (Apple 기본 - 더 다양한 카테고리)
    private func classifyImage(_ image: CGImage) async throws -> [PhotoLabel] {
        let removeKeywords = self.removeKeywords
        return try await withCheckedThrowingContinuation { continuation in
            classifyQueue.async {
                let request = VNClassifyImageRequest()
                do {
                    let handler = VNImageRequestHandler(cgImage: image, options: [:])
                    try handler.perform([request])

                    guard let results = request.results else {
                        continuation.resume(returning: [])
                        return
                    }

                    let labels = results
                        .filter { $0.confidence >= 0.1 }
                        .filter {

                            return !removeKeywords.contains($0.identifier)
                        }
                        .map { PhotoLabel(name: $0.identifier, confidence: Float($0.confidence)) }
                    continuation.resume(returning: labels)

                } catch {
                    print("Vision classifyImage 에러:", error)
                    continuation.resume(returning: [])
                }
            }
        }

    }

    /// 얼굴 감지
    private func detectFace(_ image: CGImage) async throws -> [PhotoLabel] {
        return try await withCheckedThrowingContinuation { continuation in
            faceQueue.async {
                let request = VNDetectFaceRectanglesRequest()
                let handler = VNImageRequestHandler(cgImage: image, options: [:])

                do {
                    try handler.perform([request])

                    let validFaces = request.results?.filter {
                        $0.boundingBox.width >= 0.05 && $0.boundingBox.height >= 0.05
                    } ?? []

                    guard !validFaces.isEmpty else {
                        continuation.resume(returning: [])
                        return
                    }

                    var labels: [PhotoLabel] = []

                    // 사람 존재 여부 (binary)
                    labels.append(PhotoLabel(name: "people", confidence: 1.0))

                    // 다수 여부 (binary)
                    if validFaces.count >= 2 {
                        labels.append(PhotoLabel(name: "peoples", confidence: 1.0))
                    }

                    // 가장 큰 얼굴 기준 부각 정도
                    if let maxFace = validFaces.max(by: {
                        ($0.boundingBox.width * $0.boundingBox.height)
                        < ($1.boundingBox.width * $1.boundingBox.height)
                    }) {

                        let area = maxFace.boundingBox.width * maxFace.boundingBox.height
                        let focusConfidence = min(1.0, Float(sqrt(area)) * 3.5)
                        labels.append(PhotoLabel(name: "person_focus", confidence: focusConfidence))
                    }

                    continuation.resume(returning: labels)

                } catch {
                    print("Vision detectFace 에러:", error)
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// 텍스트 감지
    private func detectText(_ image: CGImage) async throws -> [PhotoLabel] {
        return await withCheckedContinuation { continuation in
            textQueue.async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .fast  // 분류용이라 fast로 충분
                let handler = VNImageRequestHandler(cgImage: image, options: [:])

                do {
                    try handler.perform([request])

                    guard let results = request.results?.filter({
                        $0.boundingBox.width >= 0.05 && $0.boundingBox.height >= 0.05
                    }),
                          !results.isEmpty else {
                        continuation.resume(returning: [])
                        return
                    }

                    // 텍스트 양에 따라 라벨 구분
                    let label = results.count > 10 ? "document" : "text"
                    continuation.resume(returning: [
                        PhotoLabel(name: label, confidence: 1.0)
                    ])
                } catch {
                    print("Vision detectText 에러:", error)
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// 바코드 / QR코드 감지
    private func detectBarcode(_ image: CGImage) async throws -> [PhotoLabel] {
        return await withCheckedContinuation { continuation in
            barcodeQueue.async {
                let request = VNDetectBarcodesRequest()
                let handler = VNImageRequestHandler(cgImage: image, options: [:])

                do {
                    try handler.perform([request])

                    guard let results = request.results,
                          !results.isEmpty else {
                        continuation.resume(returning: [])
                        return
                    }

                    let hasQR = results.contains { $0.symbology == .qr }
                    var labels = [PhotoLabel(name: "barcode", confidence: 1.0)]
                    if hasQR { labels.append(PhotoLabel(name: "qrcode", confidence: 1.0)) }

                    continuation.resume(returning: labels)
                } catch {
                    print("Vision detectBarcode 에러:", error)
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// 중복 라벨 제거 - 같은 name이면 confidence 높은 것 유지
    private func deduplicated(_ labels: [PhotoLabel]) -> [PhotoLabel] {
        return Dictionary(grouping: labels, by: { $0.name })
            .compactMap { $0.value.max(by: { $0.confidence < $1.confidence }) }
            .sorted { $0.confidence > $1.confidence }
    }
}
