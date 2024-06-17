import FirebaseFirestore
import Foundation

// Структура для описания последнего сообщения
struct LastMessage: Identifiable {
    
    var id: String { documentId }
    let documentId: String
    let fromId, toId: String
    let timestamp: Timestamp
    let email, profileImageUrl: String
    
    var timeAgo: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.profileImageUrl = data[FirebaseConstants.profileImageUrl] as? String ?? ""
        self.email = data[FirebaseConstants.email] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
    }
}
