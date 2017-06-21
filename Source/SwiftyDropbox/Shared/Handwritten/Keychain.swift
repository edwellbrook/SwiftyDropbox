//
//  Keychain.swift
//  SwiftyDropbox
//
//  Created by Edward Wellbrook on 22/06/2017.
//  Copyright © 2017 Dropbox. All rights reserved.
//

import Foundation

class Keychain {
    static let checkAccessibilityMigrationOneTime: () = {
        Keychain.checkAccessibilityMigration()
    }()

    class func queryWithDict(_ query: [String : AnyObject]) -> CFDictionary {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        var queryDict = query

        queryDict[kSecClass as String]       = kSecClassGenericPassword
        queryDict[kSecAttrService as String] = "\(bundleId).dropbox.authv2" as AnyObject?

        return queryDict as CFDictionary
    }

    class func set(_ key: String, value: String) -> Bool {
        if let data = value.data(using: String.Encoding.utf8) {
            return set(key, value: data)
        } else {
            return false
        }
    }

    class func set(_ key: String, value: Data) -> Bool {
        let query = Keychain.queryWithDict([
            (kSecAttrAccount as String): key as AnyObject,
            (  kSecValueData as String): value as AnyObject
            ])

        SecItemDelete(query)

        return SecItemAdd(query, nil) == noErr
    }

    class func getAsData(_ key: String) -> Data? {
        let query = Keychain.queryWithDict([
            (kSecAttrAccount as String): key as AnyObject,
            ( kSecReturnData as String): kCFBooleanTrue,
            ( kSecMatchLimit as String): kSecMatchLimitOne
            ])

        var dataResult: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataResult)

        if status == noErr {
            return dataResult as? Data
        }

        return nil
    }

    class func getAll() -> [String] {
        let query = Keychain.queryWithDict([
            ( kSecReturnAttributes as String): kCFBooleanTrue,
            (       kSecMatchLimit as String): kSecMatchLimitAll
            ])

        var dataResult: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataResult)

        if status == noErr {
            let results = dataResult as? [[String : AnyObject]] ?? []
            return results.map { d in d["acct"] as! String }

        }
        return []
    }



    class func get(_ key: String) -> String? {
        if let data = getAsData(key) {
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
        } else {
            return nil
        }
    }

    class func delete(_ key: String) -> Bool {
        let query = Keychain.queryWithDict([
            (kSecAttrAccount as String): key as AnyObject
            ])

        return SecItemDelete(query) == noErr
    }

    class func clear() -> Bool {
        let query = Keychain.queryWithDict([:])
        return SecItemDelete(query) == noErr
    }

    class func checkAccessibilityMigration() {
        let kAccessibilityMigrationOccurredKey = "KeychainAccessibilityMigration"
        let MigrationOccurred = UserDefaults.standard.string(forKey: kAccessibilityMigrationOccurredKey)

        if (MigrationOccurred != "true") {
            let bundleId = Bundle.main.bundleIdentifier ?? ""
            let queryDict = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "\(bundleId).dropbox.authv2" as AnyObject?]
            let attributesToUpdateDict = [kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
            SecItemUpdate(queryDict as CFDictionary, attributesToUpdateDict as CFDictionary)
            UserDefaults.standard.set("true", forKey: kAccessibilityMigrationOccurredKey)
        }
    }
}

