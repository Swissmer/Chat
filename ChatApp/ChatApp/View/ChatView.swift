import SwiftUI

struct ChatView: View {
    
    @ObservedObject var vm: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(vm.chatMessages) { message in
                            MessageView(message: message)
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
            messageInputView
        }
        .navigationTitle(vm.chatUser?.username ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("❮ Back")
                        .foregroundColor(.green)
                }
            }
        }
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }
    
    private var messageInputView: some View {
        HStack {
            TextField("Message", text: $vm.chatText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: vm.handleSend) {
                Text("Send").foregroundStyle(Color.black)
            }
        }
        .padding()
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                Spacer()
                HStack {
                    Text(message.text)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            } else {
                HStack {
                    Text(message.text)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
