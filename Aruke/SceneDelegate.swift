//
//  SceneDelegate.swift
//  Aruke
//
//  Created by ttanaka on 2022/03/11.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let _ = (scene as? UIWindowScene) else { return }
        
        SessionManager.shared.renewAuth { error in
            SessionManager.shared.retrieveProfile { error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.showTopViewController()
                    } else {
                        self.showLoginViewController()
                    }
                }
            }
        }
    }

    // 既存の関数 必要であれば編集
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
    
    // 以下追加した関数
    private func showTopViewController() {// TopViewControllerを表示
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let rootViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        self.window?.rootViewController = rootViewController
//            self.window?.backgroundColor = UIColor.white 念のため残した
        self.window?.makeKeyAndVisible()
    }
    
    // LoginViewControllerを表示
    private func showLoginViewController() {
        let storyboard = UIStoryboard(name: "Login", bundle: Bundle.main)
        let rootViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        self.window?.rootViewController = rootViewController
//            self.window?.backgroundColor = UIColor.white 念のため残した
        self.window?.makeKeyAndVisible()
    }

}

