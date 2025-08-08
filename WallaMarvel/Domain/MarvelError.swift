import Foundation

enum MarvelError: Error, LocalizedError {
    case heroNotFound
    var errorDescription: String? { "Hero not found" }
}
