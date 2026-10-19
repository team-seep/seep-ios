import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@testable import seep_ios_dev

/// 위시 사진 파일 저장소 실제 구현 (GH-36 R-3, R-5, R-7, R-8). 임시 폴더에 쓰고 지운다.
final class WishPhotoStorageTests: XCTestCase {
    private var directory: URL!
    private var sut: WishPhotoStorageImpl!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WishPhotoStorageTests-\(UUID().uuidString)", isDirectory: true)
        sut = WishPhotoStorageImpl(directory: directory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        sut = nil
        directory = nil
        super.tearDown()
    }

    private func makeJPEGData(width: Int, height: Int) -> Data {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        context?.setFillColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1)
        context?.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let data = NSMutableData()
        guard let image = context?.makeImage(),
              let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            XCTFail("테스트 이미지를 만들지 못했다")
            return Data()
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    private func save(_ data: Data, wishId: String) -> Result<String, WishPhotoStorageError>? {
        let expectation = expectation(description: "save")
        var result: Result<String, WishPhotoStorageError>?
        sut.savePhoto(imageData: data, wishId: wishId) {
            result = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result
    }

    private func pixelSize(of url: URL) -> (width: Int, height: Int, type: String?) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return (0, 0, nil)
        }
        return (
            properties[kCGImagePropertyPixelWidth] as? Int ?? 0,
            properties[kCGImagePropertyPixelHeight] as? Int ?? 0,
            CGImageSourceGetType(source) as String?
        )
    }

    // MARK: GH-36 TC2

    func test_GH36_TC2_큰사진을저장하면_긴변1080이하JPEG로_위시id접두파일이생긴다() throws {
        // Given
        let data = makeJPEGData(width: 3000, height: 2000)

        // When
        let fileName = try XCTUnwrap(try save(data, wishId: "wish-1")?.get())

        // Then
        XCTAssertTrue(fileName.hasPrefix("wish-1-"))
        XCTAssertTrue(fileName.hasSuffix(".jpg"))
        let url = try XCTUnwrap(sut.photoURL(fileName: fileName))
        let size = pixelSize(of: url)
        XCTAssertEqual(size.width, 1080)
        XCTAssertEqual(size.height, 720)
        XCTAssertEqual(size.type, UTType.jpeg.identifier)
    }

    func test_GH36_TC2_이미지가아닌데이터는_invalidImage로실패하고_파일을남기지않는다() {
        // Given
        let data = Data("not an image".utf8)

        // When
        let result = save(data, wishId: "wish-1")

        // Then
        guard case .failure(.invalidImage) = result else {
            return XCTFail("invalidImage 실패가 아니다: \(String(describing: result))")
        }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        XCTAssertTrue(files.isEmpty)
    }

    // MARK: GH-36 TC5

    func test_GH36_TC5_위시사진을지우면_그위시id의파일만모두지워진다() throws {
        // Given
        let data = makeJPEGData(width: 200, height: 100)
        let first = try XCTUnwrap(try save(data, wishId: "wish-1")?.get())
        let second = try XCTUnwrap(try save(data, wishId: "wish-1")?.get())
        let other = try XCTUnwrap(try save(data, wishId: "wish-10")?.get())

        // When
        sut.deletePhotos(wishId: "wish-1")

        // Then
        XCTAssertNil(sut.photoURL(fileName: first))
        XCTAssertNil(sut.photoURL(fileName: second))
        XCTAssertNotNil(sut.photoURL(fileName: other))
    }

    // MARK: GH-36 TC6

    func test_GH36_TC6_파일이없으면_URL과썸네일이nil이다() {
        // Given
        let fileName = "wish-1-restored.jpg"

        // When
        let url = sut.photoURL(fileName: fileName)
        let expectation = expectation(description: "thumbnail")
        var thumbnail: CGImage?
        sut.loadThumbnail(fileName: fileName, maxPixelSize: 300) {
            thumbnail = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        // Then
        XCTAssertNil(url)
        XCTAssertNil(thumbnail)
        XCTAssertNil(sut.photoURL(fileName: ""))
        XCTAssertNil(sut.photoURL(fileName: "../escape.jpg"))
    }

    // MARK: GH-36 TC7

    func test_GH36_TC7_그리드썸네일은_요청한크기이하로디코딩된다() throws {
        // Given
        let fileName = try XCTUnwrap(try save(makeJPEGData(width: 1600, height: 900), wishId: "wish-1")?.get())

        // When
        let expectation = expectation(description: "thumbnail")
        var thumbnail: CGImage?
        sut.loadThumbnail(fileName: fileName, maxPixelSize: 300) {
            thumbnail = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        // Then
        let image = try XCTUnwrap(thumbnail)
        XCTAssertLessThanOrEqual(max(image.width, image.height), 300)
    }
}
