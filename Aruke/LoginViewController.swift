//
//  LoginViewController.swift
//  Aruke
//
//  Created by mshimomura on 2022/03/19.
//

import UIKit
import Auth0

class LoginViewController: UIViewController {
    
    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    override func viewDidLoad() {
        super.viewDidLoad()

        print("== Login Controller ==")
    }
    
    @IBAction func tapLogin(_ sender: UIButton) {
        showLogin()
    }
    
    private func showLogin() {
        let APIIdentifier = "https://backend"
        
        Auth0
            .webAuth()
            .scope("openid profile offline_access")
            .audience(APIIdentifier)
            .start {
                switch $0 {
                case .failure(let error):
                    print("Error: \(error)")
                case .success(let credentials):
                    if(!SessionManager.shared.store(credentials: credentials)) {
                        print("Failed to store credentials")
                    } else {
                        SessionManager.shared.retrieveProfile { error in
                            DispatchQueue.main.async {
                                guard error == nil else {
                                    print("Failed to retrieve profile: \(String(describing: error))")
                                    return
                                }
                            }
                        }
                    }
                }
        }
    }
    
}
