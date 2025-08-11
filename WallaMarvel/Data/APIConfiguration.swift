import Foundation

/// Protocol for API configuration providers
protocol APIConfiguration {
    var publicKey: String { get }
    var privateKey: String { get }
}

/// Reads Marvel API keys from Info.plist for secure configuration
struct InfoPlistAPIConfiguration: APIConfiguration {
    private let publicKeyKey: String
    private let privateKeyKey: String

    /// Initialize with custom key names or use defaults
    init(publicKeyKey: String = "MARVEL_PUBLIC_KEY",
         privateKeyKey: String = "MARVEL_PRIVATE_KEY"
    ) {
        self.publicKeyKey = publicKeyKey
        self.privateKeyKey = privateKeyKey
    }

    /// Marvel API public key from app bundle
    var publicKey: String { Bundle.main.object(forInfoDictionaryKey: publicKeyKey) as? String ?? "" }
    /// Marvel API private key from app bundle
    var privateKey: String { Bundle.main.object(forInfoDictionaryKey: privateKeyKey) as? String ?? "" }
}