import SwiftUI
import FirebaseStorage
import PhotosUI
import Firebase
import FirebaseFirestore

struct ContentView: View {
    @State var key = false
    @State var mail = ""
    @State var password = ""
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    init () {
        FirebaseApp.configure()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                VStack {
                    Picker(selection: $key, label: Text("something")) {
                        Text("Login").tag(true)
                        Text("Create").tag(false)
                        
                    }.pickerStyle(SegmentedPickerStyle())
                        .padding()
                    
                    if !key {
                        Button(action: {
                        }, label: {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let image = selectedImageData {
                                    Image(uiImage: UIImage(data: image)!)
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person").font(.system(size: 64)).padding()
                                }
                            }
                            .onChange(of: selectedItem) { newItem in
                                if let newItem = newItem {
                                    Task {
                                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                                            selectedImageData = data
                                        }
                                    }
                                }
                            }
                            
                        })
                    }
                    
                    TextField("mail", text: $mail)
                        .keyboardType(.emailAddress)
                        .padding(15)
                        .background(Color.white)
                    TextField("password", text: $password)
                        .padding(15)
                        .background(Color.white)
                    
                    Button(action: {
                        handleAction()
                    }, label: {
                        Text(key ? "Log In" : "Create account")
                    }).padding()
                }.padding()
                
            }
            .navigationTitle(key ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
    }
    
    private func handleAction() {
        if key {
            loginUser()
            //            print("Log In")
        } else {
            createNewAccount()
            //            print("Register")
        }
    }
    
    private func createNewAccount() {
        Auth.auth().createUser(withEmail: mail, password: password) {
            result, error in
            if let err = error {
                print("Failed to create user(", err)
                return
            }
            
            persistImageToStorage()
            print("Successfully created user!")
        }
    }
    
    private func loginUser() {
        Auth.auth().signIn(withEmail: mail, password: password) {
            result, error in
            if let err = error {
                print("Failed to sign In user(", err)
                return
            }
            
            print("Successfully sign In!")
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Storage.storage().reference(withPath: uid)
        if selectedImageData == nil { return }
        guard let imageData = selectedImageData else { return }
        ref.putData(imageData, metadata: nil) {
            metadata, err in
            if let err = err {
                print("Faild to push image to Storage: \(err)")
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    print("Faild to downloadURL: \(err)")
                    return
                }
                
//                print(url?.absoluteString ?? "")
                guard let url = url else { return }
                storeUserInformation(imageProfileUrl: url)
            }
            
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userData = ["uid": uid, "email": self.mail, "profileImageUrl": imageProfileUrl.absoluteString]
        Firestore.firestore().collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    return
                }
                
                print("seccuss")
            }
    }
}

#Preview {
    ContentView()
}
