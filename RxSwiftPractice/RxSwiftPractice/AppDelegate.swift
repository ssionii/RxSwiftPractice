//
//  AppDelegate.swift
//  RxSwiftPractice
//
//  Created by  60117280 on 2021/03/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window = UIWindow(frame: UIScreen.main.bounds)
                
        let startStoryboard = UIStoryboard(name: "Combinestagram", bundle: nil)
        let viewController = startStoryboard.instantiateViewController(withIdentifier: "StartNavigationController")
                
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }

}

