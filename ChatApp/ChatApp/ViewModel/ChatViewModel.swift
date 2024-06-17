import SwiftUI
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var count = 0
    @Published var chatMessages = [ChatMessage]()
    
    var chatUser: ChatUser?
    var firestoreListener: ListenerRegistration?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        getMessages()
    }
    
    func getMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid,
              let toId = chatUser?.uid else { return }
        firestoreListener?.remove()
        chatMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Failed to fetch messages:", error)
                    return
                }
                snapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        self.processMessageChange(change)
                    }
                }
            }
    }
    
    private func processMessageChange(_ change: DocumentChange) {
        var dataChat = change.document.data()
        
        fetchChatUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatUser):
                self.chatUser = chatUser
                
                guard let privateKey = UserDefaults.standard.string(forKey: "userPrivateKey") else {
                    print("Не удалось получить приватный ключ!")
                    return
                }
                
                do {
                    let keyString = try deriveSymmetricKey(privateKey: privateKey, publicKey: chatUser.publicKey)
                    
                    if let ciphertext = dataChat["text"] as? [UInt8] {
                        let decryptedText = Cipher.shared.encryptDecrypt(data: ciphertext, key: Array(keyString.utf8))
                        dataChat["text"] = Cipher.shared.stringFromBytes(decryptedText)
                        
                        DispatchQueue.main.async {
                            self.chatMessages.append(ChatMessage(documentId: change.document.documentID, data: dataChat))
                            self.count += 1
                        }
                    }
                } catch {
                    print(error)
                }
                
            case .failure(let error):
                print("Failed to fetch user:", error)
            }
        }
    }
    
    func handleSend() {
        guard !self.chatText.isEmpty,
              let fromId = FirebaseManager.shared.auth.currentUser?.uid,
              let toId = chatUser?.uid else { return }
        
        fetchChatUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatUser):
                self.chatUser = chatUser
                
                guard let privateKey = UserDefaults.standard.string(forKey: "userPrivateKey") else {
                    print("Не удалось получить приватный ключ!")
                    return
                }
                
                do {
                    let keyString = try deriveSymmetricKey(privateKey: privateKey, publicKey: chatUser.publicKey)
                    let ciphertext = Cipher.shared.encryptDecrypt(data: Array(self.chatText.utf8), key: Array(keyString.utf8))
                    
                    let messageData: [String: Any] = [
                        FirebaseConstants.fromId: fromId,
                        FirebaseConstants.toId: toId,
                        FirebaseConstants.text: ciphertext,
                        FirebaseConstants.timestamp: Timestamp()
                    ]
                    
                    self.sendMessage(messageData, fromId: fromId, toId: toId)
                    self.saveLastMessage(with: messageData)
                    
                    DispatchQueue.main.async {
                        self.chatText = ""
                        self.count += 1
                    }
                } catch {
                    print("Failed to send message:", error)
                }
                
            case .failure(let error):
                print("Failed to fetch user:", error)
            }
        }
    }
    
    private func sendMessage(_ messageData: [String: Any], fromId: String, toId: String) {
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        document.setData(messageData) { error in
            if let error = error {
                print("Failed to send message:", error)
            } else {
                print("Message sent successfully.")
            }
        }
        
        let recipientDocument = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientDocument.setData(messageData) { error in
            if let error = error {
                print("Failed to send message to recipient:", error)
            } else {
                print("Message sent to recipient successfully.")
            }
        }
    }
    
    private func saveLastMessage(with messageData: [String: Any]) {
        guard let chatUser = chatUser,
              let uid = FirebaseManager.shared.auth.currentUser?.uid,
              let toId = self.chatUser?.uid else { return }
        
        var recentMessageData = messageData
        recentMessageData[FirebaseConstants.profileImageUrl] = chatUser.profileImageUrl
        recentMessageData[FirebaseConstants.email] = chatUser.email
        
        let recentMessageDocument = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .document(toId)
        
        recentMessageDocument.setData(recentMessageData) { error in
            if let error = error {
                print("Failed to save recent message:", error)
            }
        }
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        var recipientRecentMessageData = messageData
        recipientRecentMessageData[FirebaseConstants.profileImageUrl] = currentUser.profileImageUrl
        recipientRecentMessageData[FirebaseConstants.email] = currentUser.email
        
        let recipientRecentMessageDocument = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(toId)
            .collection(FirebaseConstants.messages)
            .document(currentUser.uid)
        
        recipientRecentMessageDocument.setData(recipientRecentMessageData) { error in
            if let error = error {
                print("Failed to save recipient recent message:", error)
            }
        }
    }
    
    private func fetchChatUser(completion: @escaping (Result<ChatUser, Error>) -> Void) {
        guard let chatUserId = chatUser?.uid else {
            completion(.failure(NSError(domain: "ChatViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chat user ID not found."])))
            return
        }
        
        FirebaseManager.shared.firestore.collection("users").document(chatUserId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "ChatViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "User data not found."])))
                return
            }
            let chatUser = ChatUser(data: data)
            completion(.success(chatUser))
        }
    }
    
    deinit {
        firestoreListener?.remove()
    }
}
