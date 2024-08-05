//
//  WatchTower27App.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/3/24.
//

import SwiftUI
import Firebase

@main
struct WatchTower27App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
