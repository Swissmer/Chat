import FirebaseFirestore
import Foundation

struct RecentMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let text, fromId, toId: String
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
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}
