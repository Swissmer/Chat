import SwiftUI
import SDWebImageSwiftUI

struct MainScreenView: View {
    
    @ObservedObject private var viewModel = MainScreenViewModel()
    
    @State private var shouldShowLogOutOption = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowNewMessageScreen = false
    @State private var chatUser: ChatUser?
    @State private var showAlert = false
    
    private var chatLogViewModel = ChatViewModel(chatUser: nil)
    
    var body: some View {
        NavigationView {
            VStack {
                userInfoView
                Divider()
                messagesListView
                newMessageButton
            }
            .fullScreenCover(isPresented: $viewModel.isUserCurrentlyLoggedOut, onDismiss: nil, content: {
                AuthView(didCompleteLoginProcess: {
                    viewModel.startTimer()
                    viewModel.isUserCurrentlyLoggedOut = false
                    viewModel.getCurrentUser()
                    viewModel.getLastMessages()
                })
            })
            .onAppear {
                if !viewModel.isUserCurrentlyLoggedOut {
                    viewModel.startTimer()
                }
            }
            .onDisappear {
                viewModel.stopTimer()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Информация"),
                    message: Text("Если вы видите в чате - @#!?, значит, кто-то из пользователей сменил устройство."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var userInfoView: some View {
        HStack {
            WebImage(url: URL(string: viewModel.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.chatUser?.username ?? "User")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundStyle(Color.green)
                        .frame(width: 10, height: 10)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.lightGray))
                }
            }
            Spacer()
            infoButton
            logOutButton
        }
        .padding()
    }
    
    private var infoButton: some View {
        Button(action: {
            showAlert.toggle()
        }) {
            Image(systemName: "info.circle")
                .padding()
                .foregroundColor(.green)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var messagesListView: some View {
        ScrollView {
            ForEach(viewModel.recentMessages) { recentMessage in
                VStack {
                    Button {
                        handleSelectMessage(recentMessage: recentMessage)
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            Text(recentMessage.username)
                                .foregroundColor(.black)
                            Spacer()
                            Text(recentMessage.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                }
                .padding(.horizontal)
            }
        }
        .background(
            NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                ChatView(vm: chatLogViewModel)
            }
            .hidden()
        )
    }
    
    private var newMessageButton: some View {
        Button(action: {
            shouldShowNewMessageScreen.toggle()
            DispatchQueue.main.async {
                self.viewModel.stopTimer()
            }
        }) {
            Text("+ New Message")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen, onDismiss: nil, content: {
            NewMessageView(didSelectNewUser: { user in
                self.shouldNavigateToChatLogView = true
                self.chatUser = user
                self.chatLogViewModel.chatUser = user
                self.chatLogViewModel.getMessages()
            })
        })
    }
    
    private var logOutButton: some View {
        Button {
            shouldShowLogOutOption.toggle()
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.forward")
                .foregroundStyle(Color.green)
        }
        .buttonStyle(PlainButtonStyle())
        .actionSheet(isPresented: $shouldShowLogOutOption) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Log Out"), action: {
                    viewModel.signOut()
                    print("Log out!")
                }),
                .cancel()
            ])
        }
    }
    
    private func handleSelectMessage(recentMessage: LastMessage) {
        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Не удалось получить пользователя: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }
            self.chatUser = .init(data: data)
            self.chatLogViewModel.chatUser = self.chatUser
            self.chatLogViewModel.getMessages()
            self.shouldNavigateToChatLogView = true
        }
    }
}
