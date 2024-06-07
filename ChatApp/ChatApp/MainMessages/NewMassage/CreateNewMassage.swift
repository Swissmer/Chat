//
//  CreateNewMassage.swift
//  ChatApp
//
//  Created by Даниил Семёнов on 07.06.2024.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    @Published var users = [ChatUser]()
    
    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection("users").getDocuments { documentsSnapshot, error in
            if let err = error {
                print("Ошибка с получением данных", err)
                return
            }
            
            documentsSnapshot?.documents.forEach({ snapshot in
                let data = snapshot.data()
                let user = ChatUser(data: data)
                if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    self.users.append(.init(data: data))
                }
            })
            
        }
    }
}

struct CreateNewMassage: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                ForEach(vm.users) { user in
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    }, label: {
                        HStack {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            Text(user.email)
                            Spacer()
                        }
                    })
                }
            }.navigationTitle("New Message")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("Cancel")
                        })
                    }
                }
        }
    }
}

#Preview {
//    CreateNewMassage()
    MainMessagesView()
}
