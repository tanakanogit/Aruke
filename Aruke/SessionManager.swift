//
//  SessionManager.swift
//  Aruke
//
//  Created by mshimomura on 2022/03/19.
//

import Foundation
import SimpleKeychain
import Auth0

class SessionManager {
    static let shared = SessionManager()
    private let authentication = Auth0.authentication()
    let credentialsManager: CredentialsManager!
    var credentials: Credentials?
    
    private init () {
        self.credentialsManager = CredentialsManager(authentication: Auth0.authentication())
         _ = self.authentication.logging(enabled: true) // API Logging
    }
    
    func retrieveProfile(_ callback: @escaping (Error?) -> ()) {
        guard let accessToken = self.credentials?.accessToken else {
            return callback(CredentialsManagerError.noCredentials)
        }
        
        print(accessToken)
        
        self.authentication
            .userInfo(withAccessToken: accessToken)
            .start { result in
                switch(result) {
                case .success(_):
                    callback(nil)
                case .failure(let error):
                    callback(error)
                }
            }
    }
    
    func renewAuth(_ callback: @escaping (Error?) -> ()) {
        guard self.credentialsManager.hasValid() else {
            return callback(CredentialsManagerError.noCredentials)
        }
        self.credentialsManager.credentials { error, credentials in
            guard error == nil, let credentials = credentials else {
                return callback(error)
            }
            self.credentials = credentials
            callback(nil)
        }
    }
    
    func logout() {
        self.credentials = nil
        self.credentialsManager.revoke { error in
            guard error == nil else {
                return
            }
        }
    }
    
    // func 関数名(パラメータ1: パラメータ1の方)
    func store(credentials: Credentials) -> Bool {
        // 作成されたcredentials(資格情報)をSessionManagerのcredentialsに格納
        self.credentials = credentials
        // KeyChainにクレデンシャルを保存する
        return self.credentialsManager.store(credentials: credentials)
    }
    
}
