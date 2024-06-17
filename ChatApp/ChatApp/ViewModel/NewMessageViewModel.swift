import SwiftUI
import FirebaseFirestore

class NewMessageViewModel: ObservableObject {
    @Published var users = [ChatUser]()
    init() {
        getAllUsers()
    }
    private func getAllUsers() {
        FirebaseManager.shared.firestore.collection("users").getDocuments { [weak self] documentsSnapshot, error in
            if let err = error {
                print("Ошибка с получением данных", err)
                return
            }
            documentsSnapshot?.documents.forEach({ snapshot in
                let data = snapshot.data()
                let user = ChatUser(data: data)
                if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    self?.users.append(user)
                }
            })
        }
    }
}
