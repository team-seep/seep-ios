import SwiftUI

/// 앱에 들어간 오픈소스 하나
struct OpenSourceLicense: Identifiable, Equatable {
    let name: String
    let license: String
    let url: String

    var id: String { name }
}

/// 오픈소스 라이선스 (R-28). `Package.resolved`의 패키지 목록이고, GH-64 P3에서 지운 의존성은 여기서도 뺀다
struct LicenseScreen: View {
    static let licenses: [OpenSourceLicense] = [
        OpenSourceLicense(name: "Abseil", license: "Apache License 2.0", url: "https://github.com/google/abseil-cpp-binary"),
        OpenSourceLicense(name: "Firebase", license: "Apache License 2.0", url: "https://github.com/firebase/firebase-ios-sdk"),
        OpenSourceLicense(name: "Firebase App Check", license: "Apache License 2.0", url: "https://github.com/google/app-check"),
        OpenSourceLicense(name: "GoogleAppMeasurement", license: "Apache License 2.0", url: "https://github.com/google/GoogleAppMeasurement"),
        OpenSourceLicense(name: "GoogleDataTransport", license: "Apache License 2.0", url: "https://github.com/google/GoogleDataTransport"),
        OpenSourceLicense(name: "GoogleUtilities", license: "Apache License 2.0", url: "https://github.com/google/GoogleUtilities"),
        OpenSourceLicense(name: "gRPC", license: "Apache License 2.0", url: "https://github.com/google/grpc-binary"),
        OpenSourceLicense(name: "GTMSessionFetcher", license: "Apache License 2.0", url: "https://github.com/google/gtm-session-fetcher"),
        OpenSourceLicense(name: "Interop for Google SDKs", license: "Apache License 2.0", url: "https://github.com/google/interop-ios-for-google-sdks"),
        OpenSourceLicense(name: "leveldb", license: "BSD 3-Clause License", url: "https://github.com/firebase/leveldb"),
        OpenSourceLicense(name: "nanopb", license: "zlib License", url: "https://github.com/firebase/nanopb"),
        OpenSourceLicense(name: "Promises", license: "Apache License 2.0", url: "https://github.com/google/promises"),
        OpenSourceLicense(name: "Realm", license: "Apache License 2.0", url: "https://github.com/realm/realm-swift"),
        OpenSourceLicense(name: "SwiftProtobuf", license: "Apache License 2.0", url: "https://github.com/apple/swift-protobuf")
    ]

    var body: some View {
        SettingsDetailLayout(title: Strings.License.title, screenName: .license) {
            Text(Strings.License.description)
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            VStack(spacing: 0) {
                ForEach(Array(Self.licenses.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.tagBg)
                            .frame(height: 1)
                            .padding(.leading, 14)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: item.name)
                            .font(.appleMedium(size: 16))
                            .foregroundStyle(Color.gray5)
                        Text(verbatim: item.license)
                            .font(.appleRegular(size: 12))
                            .foregroundStyle(Color.gray4)
                        Text(verbatim: item.url)
                            .font(.appleRegular(size: 12))
                            .foregroundStyle(Color.gray4)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color.gray1, in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, 16)
        }
    }
}
