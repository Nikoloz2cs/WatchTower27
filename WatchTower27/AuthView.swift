//
//  AuthView.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/4/24.
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isSignedIn = false

    var body: some View {
        VStack {
            Image("URSpider")
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .edgesIgnoringSafeArea(.top)
            
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8.0)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8.0)

                HStack(spacing: 20) {
                    Button(action: signUp) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8.0)
                    }

                    Button(action: signIn) {
                        Text("Sign In")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8.0)
                    }
                }
            }
            .padding()
            
            Spacer() // Adds flexible space below the fields and buttons
                .frame(height: 40)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .fullScreenCover(isPresented: $isSignedIn, content: {
            ContentView()
        })
    }

    private func signUp() {
        let emailPattern = #"^[A-Z0-9a-z._%+-]+@richmond\.edu$"#
        let result = email.range(of: emailPattern, options: .regularExpression)

        guard result != nil else {
            errorMessage = "Please use a valid UR email address."
            showAlert = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = customErrorMessage(for: error)
                showAlert = true
                return
            }

            guard let user = authResult?.user else { return }

            user.sendEmailVerification { error in
                if let error = error {
                    errorMessage = customErrorMessage(for: error)
                    showAlert = true
                    return
                }

                errorMessage = "A verification email has been sent to \(user.email!). Please verify your email."
                showAlert = true
            }
        }
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = customErrorMessage(for: error)
                showAlert = true
                return
            }

            guard let user = authResult?.user else { return }

            user.getIDTokenResult { tokenResult, error in
                if let error = error {
                    errorMessage = customErrorMessage(for: error)
                    showAlert = true
                    return
                }

                if let tokenResult = tokenResult, let bypassEmailVerification = tokenResult.claims["bypassEmailVerification"] as? Bool, bypassEmailVerification {
                    isSignedIn = true
                } else if !user.isEmailVerified {
                    errorMessage = "Please verify your email before signing in."
                    showAlert = true
                    try? Auth.auth().signOut()
                } else {
                    isSignedIn = true
                }
            }
        }
    }
}

// Custom error messages
extension AuthView {
    func customErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        // Use Firebase's AuthErrorCode to get specific error codes
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .invalidEmail:
                return "The email address is badly formatted."
            case .emailAlreadyInUse:
                return "The email address is already in use by another account."
            case .weakPassword:
                return "The password is too weak. Please choose a stronger password."
            case .wrongPassword:
                return "The password you entered is incorrect."
            case .userNotFound:
                return "There is no account associated with this email."
            case .userDisabled:
                return "This user account has been disabled."
            case .networkError:
                return "Network error. Please check your internet connection."
            case .tooManyRequests:
                return "Too many requests. Please try again later."
            case .invalidCredential:
                return "The supplied credentials are malformed or have expired. Please try again."
            default:
                return "An unknown error occurred. Please try again."
            }
        }
        
        // Return the default error message if it's not a known error code
        return error.localizedDescription
    }
}


//#Preview {
//    AuthView()
//}
