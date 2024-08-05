//
//  RootView.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/4/24.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var isUserAuthenticated = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Checking authentication status...") // Show a loading indicator
            } else {
                if isUserAuthenticated {
                    ContentView()
                } else {
                    AuthView()
                }
            }
        }
        .onAppear(perform: checkAuthentication)
    }

    private func checkAuthentication() {
        // Check if a user is already signed in
        if let user = Auth.auth().currentUser {
            user.reload { error in
                if let error = error {
                    print("Error reloading user: \(error.localizedDescription)")
                    isUserAuthenticated = false
                } else {
                    isUserAuthenticated = user.isEmailVerified
                }
                isLoading = false
            }
        } else {
            isUserAuthenticated = false
            isLoading = false
        }
    }
}

