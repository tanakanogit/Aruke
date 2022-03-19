//
//  ViewController.swift
//  Aruke
//
//  Created by ttanaka on 2022/03/11.
//

import UIKit
import Auth0

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("== Main Controller ==")
    }
    
    @IBAction func tapLogout(_ sender: UIButton) {
        self.logout()
    }
    
    private func logout() {
        SessionManager.shared.logout()
        Auth0
            .webAuth()
            .clearSession(federated: false) { result in
                guard result else {return}
            }
    }

}

