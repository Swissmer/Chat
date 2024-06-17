import SwiftUI
import PhotosUI
import Firebase

class AuthViewModel: ObservableObject {
    @Published var messageError = ""
    @Published var isLoginMode = true
    @Published var email = ""
    @Published var password = ""
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImageData: Data? = nil
    
    let didCompleteLoginProcess: () -> ()
    
    init(didCompleteLoginProcess: @escaping () -> ()) {
        self.didCompleteLoginProcess = didCompleteLoginProcess
    }
    
    func changeScreen() {
        isLoginMode ? loginUser() : createNewAccount()
    }
    
    private func createNewAccount() {
        guard let selectedImageData = selectedImageData else {
            print("Please select a profile image.")
            self.messageError = "Please select a profile image."
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Failed to create user: \(error)")
                self.messageError = "\(error)"
                return
            }
            
            self.sendImageToStorage(imageData: selectedImageData)
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Failed to sign in user: \(error)")
                self.messageError = "\(error)"
                return
            }
            // Генерация ключей
            let privateKey = generatePrivateKey()
            UserDefaults.standard.set(privateKey, forKey: "userPrivateKey")
            guard let publicKey = try? generatePublicKey(privateKey: privateKey) else {
                print("Failed to generate public key")
                self.messageError = "Failed to generate public key"
                return
            }
            guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
            FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    print("Не удалось получить пользователя: \(error)")
                    self.messageError = "\(error)"
                    return
                }
                guard let data = snapshot?.data() else { return }
                FirebaseManager.shared.currentUser = .init(data: data)
                let userData: [String : Any] = [
                    FirebaseConstants.uid: FirebaseManager.shared.currentUser?.uid as Any,
                    FirebaseConstants.email: FirebaseManager.shared.currentUser?.email as Any,
                    FirebaseConstants.profileImageUrl: FirebaseManager.shared.currentUser?.profileImageUrl as Any,
                    FirebaseConstants.publicKey: publicKey
                ]
                FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) { error in
                    if let error = error {
                        print("Failed to store user information: \(error)")
                        self.messageError = "\(error)"
                        return
                    }
                    self.didCompleteLoginProcess()
                }
            }
        }
    }
    
    private func sendImageToStorage(imageData: Data) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload image to storage: \(error)")
                self.messageError = "\(error)"
                return
            }
            
            ref.downloadURL { url, error in
                if let error = error {
                    print("Failed to retrieve download URL: \(error)")
                    self.messageError = "\(error)"
                    return
                }
                
                guard let url = url else { return }
                self.sendUserInformationToStorage(profileImageUrl: url)
            }
        }
    }
    
    private func sendUserInformationToStorage(profileImageUrl: URL) {
        let privateKey = generatePrivateKey()
        UserDefaults.standard.set(privateKey, forKey: "userPrivateKey")
        guard let publicKey = try? generatePublicKey(privateKey: privateKey) else {
            print("Failed to generate public key")
            self.messageError = "Failed to generate public key"
            return
        }
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData: [String : Any] = [
            FirebaseConstants.uid: uid,
            FirebaseConstants.email: email,
            FirebaseConstants.profileImageUrl: profileImageUrl.absoluteString,
            FirebaseConstants.publicKey: publicKey
        ]
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Failed to store user information: \(error)")
                self.messageError = "\(error)"
                return
            }
            
            self.didCompleteLoginProcess()
        }
    }
}
