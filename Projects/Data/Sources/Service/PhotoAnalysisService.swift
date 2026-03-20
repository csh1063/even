//
//  PhotoAnalysisService.swift
//  Data
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Vision
import CoreML
import Domain

//public final class PhotoAnalysisService {
//    
//    // MARK: - Properties
//    
//    private let model: VNCoreMLModel?
//    
//    // MARK: - Init
//    
//    public init() {
//        if let mlModel = try? MobileNetV2(configuration: MLModelConfiguration()).model {
//            self.model = try? VNCoreMLModel(for: mlModel)
//        } else {
//            self.model = nil
//        }
//    }
//    
//    // MARK: - Public
//    
//    /// 단일 사진 분석 → 라벨 반환
//    public func analyze(image: CGImage) async -> [PhotoLabel]? {
//        return await performAnalysis(image)
//    }
//    
//    // MARK: - Private
//    private func performAnalysis(_ cgImage: CGImage) async -> [PhotoLabel]? {
//        guard let model else { return nil }
//        
//        return await withCheckedContinuation { continuation in
//            let request = VNCoreMLRequest(model: model) { request, error in
//                guard error == nil,
//                      let results = request.results as? [VNClassificationObservation] else {
//                    continuation.resume(returning: [])
//                    return
//                }
//                
//                let labels = results
//                    .filter { $0.confidence >= 0.1 }
//                    .map { PhotoLabel(name: $0.identifier, confidence: Float($0.confidence)) }
//                
//                continuation.resume(returning: labels)
//            }
//            
//            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//            try? handler.perform([request])
//        }
//    }
//}

import Vision
import CoreImage
import CoreGraphics

public final class PhotoAnalysisService {
    
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
        async let barcodeLabels = detectBarcode(image)  // 방법 2 - 바코드 감지
        
        let all = try await objectLabels + faceLabels + textLabels + barcodeLabels
        
        // 중복 제거 (같은 name이면 confidence 높은 것 유지)
        return deduplicated(all)
    }
    
    // MARK: - Private
    /// Vision 이미지 분류기 (Apple 기본 - 더 다양한 카테고리)
    private func classifyImage(_ image: CGImage) async throws -> [PhotoLabel] {
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
                        .filter { $0.confidence >= 0.3 }
                        .map { PhotoLabel(name: $0.identifier, confidence: Float($0.confidence)) }
                    continuation.resume(returning: labels)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
    }
    
    /// 얼굴 감지
    private func detectFace(_ image: CGImage) async throws -> [PhotoLabel] {
        return await withCheckedContinuation { continuation in
            faceQueue.async {
                
                let request = VNDetectFaceRectanglesRequest { request, error in
                    guard error == nil,
                          let results = request.results as? [VNFaceObservation],
                          !results.isEmpty else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    // 얼굴 수에 따라 라벨 구분
                    let label = results.count > 1 ? "people_group" : "people"
                    continuation.resume(returning: [
                        PhotoLabel(name: label, confidence: 1.0),
                        PhotoLabel(name: "portrait", confidence: 1.0)
                    ])
                }
                
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                }
                catch {
                    print("Vision detectFace 에러:", error)  // 여기 찍히나요?
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    /// 텍스트 감지
    private func detectText(_ image: CGImage) async throws -> [PhotoLabel] {
        return await withCheckedContinuation { continuation in
            textQueue.async {
                let request = VNRecognizeTextRequest { request, error in
                    guard error == nil,
                          let results = request.results as? [VNRecognizedTextObservation],
                          !results.isEmpty else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    // 텍스트 양에 따라 라벨 구분
                    let label = results.count > 10 ? "document" : "text"
                    continuation.resume(returning: [
                        PhotoLabel(name: label, confidence: 1.0)
                    ])
                }
                request.recognitionLevel = .fast  // 분류용이라 fast로 충분
                
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                }
                catch {
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
                let request = VNDetectBarcodesRequest { request, error in
                    guard error == nil,
                          let results = request.results as? [VNBarcodeObservation],
                          !results.isEmpty else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let hasQR = results.contains { $0.symbology == .qr }
                    var labels = [PhotoLabel(name: "barcode", confidence: 1.0)]
                    if hasQR { labels.append(PhotoLabel(name: "qrcode", confidence: 1.0)) }
                    
                    continuation.resume(returning: labels)
                }
                
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                }
                catch {
                    print("Vision detectBarcode 에러:", error)
                    continuation.resume(returning: [])
                }
            }
        }
    }
//
//    public func fetchLocation(localIdentifier: String) async -> [PhotoLabel] {
//        let assets = PHAsset.fetchAssets(
//            withLocalIdentifiers: [localIdentifier],
//            options: nil
//        )
//        guard let asset = assets.firstObject,
//              let location = asset.location else { return [] }
//        
//        guard let address = await fetchAddress(from: location) else { return [] }
//        return [PhotoLabel(name: address, confidence: 1.0)]
//    }
//    
    /// 중복 라벨 제거 - 같은 name이면 confidence 높은 것 유지
    private func deduplicated(_ labels: [PhotoLabel]) -> [PhotoLabel] {
        return Dictionary(grouping: labels, by: { $0.name })
            .compactMap { $0.value.max(by: { $0.confidence < $1.confidence }) }
            .sorted { $0.confidence > $1.confidence }
    }
}
