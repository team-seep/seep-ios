//
//  BundleExtensions.swift
//  seep-ios
//
//  Created by Hyun Sik Yoo on 2021/12/02.
//

import Foundation

extension Bundle {
    static var realmName: String {
        guard let realmName = Self.main.object(
            forInfoDictionaryKey: "REALM_NAME"
        ) as? String else {
            fatalError("REALM_NAME를 로드할 수 없습니다.")
        }
        return realmName
    }
}
