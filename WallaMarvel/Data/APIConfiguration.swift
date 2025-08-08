import Foundation

protocol APIConfiguration {
    var publicKey: String { get }
    var privateKey: String { get }
}

struct InfoPlistAPIConfiguration: APIConfiguration {
    private let publicKeyKey: String
    private let privateKeyKey: String

    init(publicKeyKey: String = "MARVEL_PUBLIC_KEY",
         privateKeyKey: String = "MARVEL_PRIVATE_KEY"
    ) {
        self.publicKeyKey = publicKeyKey
        self.privateKeyKey = privateKeyKey
    }

    var publicKey: String { Bundle.main.object(forInfoDictionaryKey: publicKeyKey) as? String ?? "" }
    var privateKey: String { Bundle.main.object(forInfoDictionaryKey: privateKeyKey) as? String ?? "" }
}
