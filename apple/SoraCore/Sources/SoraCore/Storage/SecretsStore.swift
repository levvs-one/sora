import Foundation

/// Credential storage boundary: private keys and passwords live here,
/// never in profiles.json (which the extension reads and logs may touch).
public protocol SecretsStoring {
    func secret(forKey key: String) throws -> String?
    func setSecret(_ value: String?, forKey key: String) throws
}

/// In-memory implementation for tests and non-Apple platforms. This is
/// the ONLY implementation compiled on Linux — see the boundary note on
/// `KeychainSecretsStore`.
public final class InMemorySecretsStore: SecretsStoring {
    private var values: [String: String] = [:]
    public init() {}
    public func secret(forKey key: String) throws -> String? { values[key] }
    public func setSecret(_ value: String?, forKey key: String) throws {
        values[key] = value // assigning nil removes, like the keychain
    }
}

#if canImport(Security)
import Security

/// Keychain-backed secrets store (Apple platforms only).
///
/// Boundary, stated honestly: this type exists only where the Security
/// framework exists. On Linux it is not compiled at all — callers there
/// use `SecretsStoring` with `InMemorySecretsStore`, and no keychain
/// behaviour is claimed or tested off Apple platforms. The access group
/// comes from `SoraSharedIdentifiers` so the app and the extension share
/// one group by construction.
public final class KeychainSecretsStore: SecretsStoring {
    public init() {}

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "io.github.levvs-one.sora.secrets",
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: SoraSharedIdentifiers.keychainAccessGroup,
        ]
    }

    public func secret(forKey key: String) throws -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        return String(decoding: data, as: UTF8.self)
    }

    public func setSecret(_ value: String?, forKey key: String) throws {
        let query = baseQuery(forKey: key)
        SecItemDelete(query as CFDictionary)
        guard let value else { return }
        var add = query
        add[kSecValueData as String] = Data(value.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
#endif
