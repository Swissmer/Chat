import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

class MainScreenViewModel: ObservableObject {
    @Published var chatUser: ChatUser?
    @Published var recentMessages = [LastMessage]()
    @Published var isUserCurrentlyLoggedOut = false
    
    private var timer: Timer?
    private var firestoreListener: ListenerRegistration?
    
    init() {
        self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        getCurrentUser()
        getLastMessages()
    }
    
    deinit {
        firestoreListener?.remove()
        DispatchQueue.main.async {
            self.stopTimer()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            self.updateTimeAgo()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateTimeAgo() {
        self.recentMessages = self.recentMessages.map { message in
            let updatedMessage = LastMessage(
                documentId: message.documentId,
                data: [
                    "fromId": message.fromId,
                    "toId": message.toId,
                    "profileImageUrl": message.profileImageUrl,
                    "email": message.email,
                    "timestamp": message.timestamp
                ]
            )
            return updatedMessage
        }
    }
    
    func getLastMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        firestoreListener?.remove()
        self.recentMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore.collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Ошибка в загрузке последних сообщений: \(error)")
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: { $0.documentId == docId }) {
                        self.recentMessages.remove(at: index)
                    }
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                })
            }
    }
    
    func getCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Не удалось найти пользователя")
            return
        }
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Не удалось получить пользователя: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }
            self.chatUser = .init(data: data)
            FirebaseManager.shared.currentUser = self.chatUser
        }
    }
    
    func signOut() {
        DispatchQueue.main.async {
            self.stopTimer()
        }
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
        firestoreListener?.remove()
    }
}

