import Foundation
import ImageIO
import Vision

/// 사진 속 글자 읽기 (GH-144 R-1, R-8). ViewModel 은 이 protocol 만 안다
protocol PhotoTextRecognizing {
    /// 고른 사진 원본에서 글자 줄을 읽는다. 읽지 못하면 빈 배열. completion 은 메인 스레드에서 부른다
    func recognizeText(imageData: Data, completion: @escaping ([RecognizedTextLine]) -> Void)
}

/// Apple Vision(`VNRecognizeTextRequest`)으로 기기 안에서만 읽는다. 네트워크·저장 없음 (GH-144 서버 저장: 없음)
final class PhotoTextRecognizer: PhotoTextRecognizing {
    /// 스크린샷 글자를 읽기에 충분하고 메모리를 덜 쓰는 긴 변 크기
    private static let maxPixelSize = 2048
    /// 긴 변을 줄여도 짧은 변은 이만큼 남긴다. 세로로 긴 캡처가 글자를 못 읽을 만큼 작아지지 않게 (2048 로 줄이면 1179×12000 이 200px 폭)
    private static let minShortSide = 1080
    /// 그래도 메모리를 넘지 않게 긴 변 상한
    private static let maxLongSide = 12_000
    private let queue = DispatchQueue(label: "seep.photo-text-recognizer", qos: .userInitiated)

    func recognizeText(imageData: Data, completion: @escaping ([RecognizedTextLine]) -> Void) {
        let languages = Self.recognitionLanguages(appLanguage: AppLanguage.shared.code)
        queue.async {
            let lines = Self.recognize(imageData: imageData, languages: languages)
            DispatchQueue.main.async { completion(lines) }
        }
    }

    /// 앱 언어 + 영어 (R-7)
    static func recognitionLanguages(appLanguage: String) -> [String] {
        let primary: String
        switch appLanguage {
        case "ko": primary = "ko-KR"
        case "ja": primary = "ja-JP"
        case "zh-Hans": primary = "zh-Hans"
        case "zh-Hant": primary = "zh-Hant"
        default: primary = "en-US"
        }
        return primary == "en-US" ? ["en-US"] : [primary, "en-US"]
    }

    private static func recognize(imageData: Data, languages: [String]) -> [RecognizedTextLine] {
        guard let image = orientedImage(data: imageData) else { return [] }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        let usable = languages.filter(supported.contains)
        if !usable.isEmpty {
            request.recognitionLanguages = usable
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return RecognizedTextLine(text: candidate.string, height: Double(observation.boundingBox.height))
        }
    }

    /// 사진 방향(EXIF)을 반영해 줄인 이미지. 옆으로 누운 사진도 글자 줄 높이가 맞게 나온다
    private static func orientedImage(data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailMaxPixelSize(source: source)
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// 보통은 긴 변 2048. 세로로 아주 긴 캡처는 짧은 변을 `minShortSide`까지 남기도록 긴 변을 더 둔다
    static func thumbnailMaxPixelSize(width: Int, height: Int) -> Int {
        let long = max(width, height)
        let short = min(width, height)
        guard long > 0, short > 0 else { return maxPixelSize }
        var target = min(long, maxPixelSize)
        if short * target / long < minShortSide {
            target = min(long, minShortSide * long / short, maxLongSide)
        }
        return target
    }

    private static func thumbnailMaxPixelSize(source: CGImageSource) -> Int {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0
        return thumbnailMaxPixelSize(width: width, height: height)
    }
}
