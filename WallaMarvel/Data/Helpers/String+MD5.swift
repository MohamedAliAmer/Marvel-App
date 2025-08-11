import Foundation
import CryptoKit

/// Extension to generate MD5 hash for Marvel API authentication
extension String {
    /// Computes MD5 hash using Apple's CryptoKit
    var md5: String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.map { .init(format: "%02hhx", $0) }.joined()
    }
}