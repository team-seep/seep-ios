import Foundation

@testable import seep_ios

/// PhotoTextRecognizing 스파이 (GH-144). 기본은 바로(동기) 응답한다. `isDeferred` 면 `complete(at:with:)`로 나중에 응답한다
final class MockPhotoTextRecognizer: PhotoTextRecognizing {
    var result: [RecognizedTextLine] = []
    var isDeferred = false
    private(set) var recognizedImages: [Data] = []
    private var pendingCompletions: [([RecognizedTextLine]) -> Void] = []

    func recognizeText(imageData: Data, completion: @escaping ([RecognizedTextLine]) -> Void) {
        recognizedImages.append(imageData)
        if isDeferred {
            pendingCompletions.append(completion)
        } else {
            completion(result)
        }
    }

    func complete(at index: Int, with lines: [RecognizedTextLine]) {
        pendingCompletions[index](lines)
    }
}
