//
//  IsraFoodApp.swift
//  IsraFood
//
//  Created by Alex Vaiman on 12/11/2023.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct ItemsClientApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        _ = LocationManager.sharedInstance
        
        return true
    }
}
