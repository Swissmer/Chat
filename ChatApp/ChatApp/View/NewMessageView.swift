import SwiftUI
import SDWebImageSwiftUI

struct NewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel = NewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(viewModel.users) { user in
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    }) {
                        UserRow(user: user)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("❮ Cancel")
                            .foregroundStyle(Color.green)
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct UserRow: View {
    let user: ChatUser
    var body: some View {
        HStack {
            WebImage(url: URL(string: user.profileImageUrl))
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            Text(user.email)
                .foregroundStyle(Color.black)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}
