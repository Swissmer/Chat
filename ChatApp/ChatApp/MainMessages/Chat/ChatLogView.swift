//
//  ChatLogView.swift
//  ChatApp
//
//  Created by Даниил Семёнов on 07.06.2024.
//

import SwiftUI
import FirebaseFirestore

struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let profileImageUrl = "profileImageUrl"
    static let email = "email"
    static let recentMessages = "recent_messages"
    static let messages = "messages"
}

struct ChatMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let fromId, toId, text: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var count = 0
    @Published var chatMessages = [ChatMessage]()
    
    var chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessage()
    }
    
    var firestoreListener: ListenerRegistration?
    
    func fetchMessage() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        firestoreListener?.remove()
        
        self.chatMessages.removeAll()
        print("Пустой")
        
        
        firestoreListener = FirebaseManager.shared.firestore as? ListenerRegistration
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                
                snapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        if change.document.documentID != self.chatMessages.last?.documentId {
                            self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                            print(self.chatMessages)
                        }
                    }
                })
                
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: chatText, FirebaseConstants.timestamp: Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print("Проблема в отпрвке", error)
            }
            
            print("Успешно сохранили сообщение у себя")
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                print("Проблема в отправке", error)
                return
            }
            
            print("Успешно сохранили сообщение у получателя")
        }
        
        self.persistRecentMessage()
        self.chatText = ""
        self.count += 1
    }
    
    private func persistRecentMessage() {
        
        guard let chatUser = chatUser else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .document(toId)
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ] as [String : Any]
        
        document.setData(data) { error in
            if let error = error {
                print("Ошибка в сохранении", error)
                return
            }
        }
        
        guard let currentUser = FirebaseManager.shared.currentUser else {
            return }
        let recipientRecentMessageDictionary = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: currentUser.profileImageUrl,
            FirebaseConstants.email: currentUser.email
        ] as [String : Any]
        
        FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(toId)
            .collection(FirebaseConstants.messages)
            .document(currentUser.uid)
            .setData(recipientRecentMessageDictionary) { error in
                if let error = error {
                    print("Failed to save recipient recent message: \(error)")
                    return
                }
                print("сохранили для 2-го участиника")
        }
    }
    
}

struct ChatLogView: View {
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(vm.chatMessages) { message in
                            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                                HStack {
                                    Spacer()
                                    HStack {
                                        Text(message.text).foregroundStyle(Color.white)
                                    }.padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }.padding()
                                
                            } else {
                                HStack {
                                    HStack {
                                        Text(message.text).foregroundStyle(Color.blue)
                                    }.padding()
                                        .background(Color.white)
                                        .cornerRadius(8)
                                    Spacer()
                                }.padding()
                            }
                        }
                        HStack { Spacer() }.id("Empty")
                    }
                    .onReceive(vm.$count, perform: { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            proxy.scrollTo("Empty", anchor: .bottom)
                        }
                    })
                }
            }
            .background(Color(.init(white: 0.95, alpha: 1)))
            
            HStack {
                //                TextEditor(text: $chatText)
                TextField("Message", text: $vm.chatText)
                Button {
                    vm.handleSend()
                    print(self.vm.chatMessages)
                } label: {
                    Text("Send")
                }
                
            }
            .padding()
        }
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }
}

#Preview {
    MainMessagesView()
    //    NavigationView {
    //        ChatLogView(chatUser: .init(data: ["email": "fake@gmail.com"]))
    //    }
}
