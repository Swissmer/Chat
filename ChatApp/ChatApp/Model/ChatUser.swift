import Foundation

struct ChatUser: Identifiable {
    var id: String { uid }
    // Характеристики пользователя
    let uid, email, profileImageUrl, publicKey: String
    // Получение имени без @
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    init(data: [String: Any]) {
        self.uid = data[FirebaseConstants.uid] as? String ?? ""
        self.email = data[FirebaseConstants.email] as? String ?? ""
        self.profileImageUrl = data[FirebaseConstants.profileImageUrl] as? String ?? ""
        self.publicKey = data[FirebaseConstants.publicKey] as? String ?? ""
    }
}
