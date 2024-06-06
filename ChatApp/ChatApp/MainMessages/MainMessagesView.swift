import SwiftUI

struct MainMessagesView: View {
    @State var shouldShowLogOutOprion = false
    
    var body: some View {
        NavigationView {
            
            VStack {
                
                HStack {
                    Image(systemName: "person.fill").font(.system(size: 32))
                    
                    VStack(alignment:.leading) {
                        Text("USERNAME").font(.system(size: 24, weight: .bold))
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
                            print("Log out!")
                        }),
                        .cancel()])
                })
                ScrollView {
                    ForEach(0..<10, id: \.self) {
                        num in
                        VStack {
                            HStack(spacing: 16) {
                                Image(systemName: "person").font(.system(size: 32))
                                VStack(alignment: .leading) {
                                    Text("Username")
                                    Text("Message sent to user")
                                }
                                Spacer()
                                Text("22d").font(.system(size: 14, weight: .semibold))
                            }
                            Divider()
                        }.padding(.horizontal)
                    }
                }
                Button(action: {
                    
                }, label: {
                    Text("+ New Message")
                })
            }
        }
    }
}

#Preview {
    MainMessagesView()
//        .preferredColorScheme(.dark)
}
