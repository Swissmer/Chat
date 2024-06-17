import SwiftUI
import PhotosUI

struct AuthView: View {
    @ObservedObject private var viewModel: AuthViewModel
    
    init(didCompleteLoginProcess: @escaping () -> ()) {
        self.viewModel = AuthViewModel(didCompleteLoginProcess: didCompleteLoginProcess)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    modePicker
                    if !viewModel.isLoginMode {
                        profileImagePicker
                    }
                    emailTextField
                    passwordTextField
                    actionButton
                    Text(viewModel.messageError)
                        .foregroundStyle(Color.red)
                        .font(.system(size: 10))
                        .padding()
                }
                .padding()
            }
            .navigationTitle(viewModel.isLoginMode ? "Log In" : "Create Account")
        }
    }
    
    private var modePicker: some View {
        Picker(selection: $viewModel.isLoginMode, label: Text("Mode")) {
            Text("Login").tag(true)
            Text("Create").tag(false)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var profileImagePicker: some View {
        Button(action: {}) {
            PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                if let imageData = viewModel.selectedImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person")
                        .font(.system(size: 64))
                        .padding()
                        .foregroundStyle(Color.black)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: viewModel.selectedItem) { newItem in
                if let newItem = newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            viewModel.selectedImageData = data
                        }
                    }
                }
            }
        }
    }
    
    private var emailTextField: some View {
        TextField("Email", text: $viewModel.email)
            .foregroundStyle(Color.black)
            .keyboardType(.emailAddress)
            .padding(15)
            .background(Color(.init(white: 0.95, alpha: 1)))
            .cornerRadius(15)
    }
    
    private var passwordTextField: some View {
        SecureField("Password", text: $viewModel.password)
            .foregroundStyle(Color.black)
            .padding(15)
            .background(Color(.init(white: 0.95, alpha: 1)))
            .cornerRadius(15)
    }
    
    private var actionButton: some View {
        Button(action: viewModel.changeScreen) {
            Text(viewModel.isLoginMode ? "Log In" : "Create Account")
                .foregroundStyle(Color.black)
                .padding()
        }.buttonStyle(PlainButtonStyle())
    }
}
