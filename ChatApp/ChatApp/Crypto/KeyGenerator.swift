import Foundation
import CryptoKit

// Генерация случайного закрытого ключа
func generatePrivateKey() -> String {
    let privateKey = P256.KeyAgreement.PrivateKey()
    return exportPrivateKey(privateKey)
}

// Генерация открытого ключа на основе закрытого ключа
func generatePublicKey(privateKey: String) throws -> String {
    let privateKeyObject = try importPrivateKey(privateKey)
    let publicKeyObject = privateKeyObject.publicKey
    return exportPublicKey(publicKeyObject)
}

// Экспорт закрытого ключа в строку
func exportPrivateKey(_ privateKey: P256.KeyAgreement.PrivateKey) -> String {
    let rawPrivateKey = privateKey.rawRepresentation
    let privateKeyBase64 = rawPrivateKey.base64EncodedString()
    let percentEncodedPrivateKey = privateKeyBase64.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    return percentEncodedPrivateKey
}

// Экспорт открытого ключа в строку
func exportPublicKey(_ publicKey: P256.KeyAgreement.PublicKey) -> String {
    let rawPublicKey = publicKey.rawRepresentation
    let publicKeyBase64 = rawPublicKey.base64EncodedString()
    let percentEncodedPublicKey = publicKeyBase64.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    return percentEncodedPublicKey
}

// Экспорт симметричного ключа в строку
func exportSymmetricKey(_ symmetricKey: SymmetricKey) -> String {
    let rawSymmetricKey = symmetricKey.withUnsafeBytes { Data(Array($0)) }
    return rawSymmetricKey.base64EncodedString()
}

// Импорт закрытого ключа из строки
func importPrivateKey(_ privateKey: String) throws -> P256.KeyAgreement.PrivateKey {
    let privateKeyBase64 = privateKey.removingPercentEncoding!
    let rawPrivateKey = Data(base64Encoded: privateKeyBase64)!
    return try P256.KeyAgreement.PrivateKey(rawRepresentation: rawPrivateKey)
}

// Импорт открытого ключа из строки
func importPublicKey(_ publicKey: String) throws -> P256.KeyAgreement.PublicKey {
    let publicKeyBase64 = publicKey.removingPercentEncoding!
    let rawPublicKey = Data(base64Encoded: publicKeyBase64)!
    return try P256.KeyAgreement.PublicKey(rawRepresentation: rawPublicKey)
}

// Импорт симметричного ключа из строки
func importSymmetricKey(_ keyString: String) -> SymmetricKey {
    let rawSymmetricKey = Data(base64Encoded: keyString)!
    return SymmetricKey(data: rawSymmetricKey)
}

// Вычисление симметричного ключа на основе закрытого и открытого ключей
func deriveSymmetricKey(privateKey: String, publicKey: String) throws -> String {
    let privateKeyObject = try importPrivateKey(privateKey)
    let publicKeyObject = try importPublicKey(publicKey)
    let sharedSecret = try privateKeyObject.sharedSecretFromKeyAgreement(with: publicKeyObject)
    let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
        using: SHA256.self,
        salt: "salt for key".data(using: .utf8)!,
        sharedInfo: Data(),
        outputByteCount: 32
    )
    return exportSymmetricKey(symmetricKey)
}
