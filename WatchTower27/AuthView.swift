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
                .frame(height: 200) // Set the height of the banner
                .clipped() // Clips the image to ensure it doesn't overflow
                .edgesIgnoringSafeArea(.top)
                .offset(y: -110)
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8.0)
                .offset(y: -110)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8.0)
                .offset(y: -110)

            HStack(spacing: 20) { // HStack arranges the buttons horizontally within the Vstack
                Button(action: signUp) {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8.0)
                        .offset(y: -110)
                }

                Button(action: signIn) {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8.0)
                        .offset(y: -110)
                }
            }
            .padding(.top, 10)
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
                errorMessage = error.localizedDescription
                showAlert = true
                return
            }

            guard let user = authResult?.user else { return }

            user.sendEmailVerification { error in
                if let error = error {
                    errorMessage = error.localizedDescription
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
                errorMessage = error.localizedDescription
                showAlert = true
                return
            }

            guard let user = authResult?.user else { return }

            // Check if email verification is required using custom claim
            user.getIDTokenResult { tokenResult, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showAlert = true
                    return
                }

                if let tokenResult = tokenResult, let bypassEmailVerification = tokenResult.claims["bypassEmailVerification"] as? Bool, bypassEmailVerification {
                    // User can bypass email verification
                    isSignedIn = true
                } else if !user.isEmailVerified {
                    errorMessage = "Please verify your email before signing in."
                    showAlert = true
                    try? Auth.auth().signOut()
                } else {
                    // Successfully signed in
                    isSignedIn = true
                }
            }
        }
    }
}


//#Preview {
//    AuthView()
//}
