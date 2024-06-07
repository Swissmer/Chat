import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

// MARK: - MainMessagesViewModel

class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var recentMessages = [RecentMessage]()
    @Published var isUserCurrentlyLoggedOut = false
    
    private var timer: Timer?
    private var firestoreListener: ListenerRegistration?
    
    init() {
        //        FirebaseManager.shared.auth.signIn(withEmail: "Swissmer@yandex.ru", password: "123456") {
        //            res, err in
        //            if let _ = err {
        //                print("ошибка входа")
        //                return
        //            }
        //        }
        
        
        self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        fetchCurrentUser()
        fetchRecentMessages()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            self.updateTimeAgo()
        }
    }
    
    func updateTimeAgo() {
        self.recentMessages = self.recentMessages.map { message in
            let updatedMessage = RecentMessage(
                documentId: message.documentId,
                data: [
                    "text": message.text,
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
    
    func fetchRecentMessages() {
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
    
    func fetchCurrentUser() {
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
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    
    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var shouldShowLogOutOprion = false
    
    @State var shouldNavigateToChatLogView = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    private var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    @State var chatUser: ChatUser?
    
    var body: some View {
        NavigationView {
            
            VStack {
                HStack {
                    WebImage(url: URL(string: "\(vm.chatUser?.profileImageUrl ?? "")"))
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    VStack(alignment:.leading) {
                        Text("\(vm.chatUser?.email ?? "user")").font(.system(size: 24, weight: .bold))
                    }
                    Spacer()
                    Button {
                        shouldShowLogOutOprion.toggle()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                    }
                }
                .padding()
                .actionSheet(isPresented: $shouldShowLogOutOprion, content: {
                    .init(title: Text("Settings"), message: Text("What do you want to Do?"), buttons: [
                        .destructive(Text("Log Out"), action: {
                            vm.handleSignOut()
                            print("Log out!")
                        }),
                        .cancel()])
                })
                        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil, content: {
//                            Text("Cover")
                            ContentView(didComleteLoginProcess: {
                                self.vm.isUserCurrentlyLoggedOut = false
                                self.vm.fetchCurrentUser()
                                self.vm.fetchRecentMessages()
                            })
                        })
                ScrollView {
                    ForEach(vm.recentMessages) {
                        recentMessage in
                        VStack {
                            Button {
                                let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                                self.chatUser = .init(data: [
                                    FirebaseConstants.email: recentMessage.email,
                                    FirebaseConstants.profileImageUrl: recentMessage.profileImageUrl,
                                    "uid": uid
                                ])
                                self.chatLogViewModel.chatUser = self.chatUser
                                
                                self.chatLogViewModel.fetchMessage()
                                self.shouldNavigateToChatLogView.toggle()
//                                ChatLogView()
                            } label: {
                                HStack(spacing: 16) {
                                    WebImage(url: URL(string: recentMessage.profileImageUrl))
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading) {
                                        Text(recentMessage.username).foregroundStyle(Color.black)
                                        
                                        
                                        
                                        Text(recentMessage.text)
                                            .foregroundStyle(Color.init(.lightGray))
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Text(recentMessage.timeAgo)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.label))
                                }
                            }
                            Divider()
                        }.padding(.horizontal)
                    }
                }
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: chatLogViewModel)
                }
                
                Button(action: {
                    shouldShowNewMessageScreen.toggle()
                }, label: {
                    Text("+ New Message")
                }).fullScreenCover(isPresented: $shouldShowNewMessageScreen, onDismiss: nil, content: {
                    CreateNewMassage(didSelectNewUser: {
                        user in
                        self.shouldNavigateToChatLogView.toggle()
                        self.chatUser = user
                        self.chatLogViewModel.chatUser = user
                        self.chatLogViewModel.fetchMessage()
                    })
                })
            }
        }
    }
    
    @State var shouldShowNewMessageScreen = false
    
}

#Preview {
    MainMessagesView()
//        .preferredColorScheme(.dark)
}
