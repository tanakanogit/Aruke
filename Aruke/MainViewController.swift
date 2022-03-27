//
//  ViewController.swift
//  Aruke
//
//  Created by ttanaka on 2022/03/11.
//

import UIKit
import Auth0

class MainViewController: UIViewController {
    @IBOutlet weak var ContainerView: UIView!
    @IBOutlet weak var SettingButtonView: UIView!
    @IBOutlet weak var DisplayGoalView: UIView!
    var containers: Array<UIView> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        containers = [
            SettingButtonView,
            DisplayGoalView
        ]
        
        self.callAPI()
    }
    
    override func viewWillAppear(_ animated: Bool) { // 戻ってきた時に実行されます
        super.viewWillAppear(animated)
        self.callAPI()
    }
    
    @IBAction func tapLogout(_ sender: UIButton) {
        self.logout()
    }
    
    struct Goals: Codable {
        let goals: [Goal]
    }
    
    struct Goal: Codable {
        let id: Int
        let steps: Int
        let term: String
        let penalties: Int
        let isAchieved: Bool
        let userId: Int
        let createdAt: String
        let updatedAt: String
        let isDeleted: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case steps
            case term
            case penalties
            case isAchieved = "is_achieved"
            case userId = "user_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case isDeleted = "is_deleted"
        }
    }
    
    private func callAPI() {
        guard let token = SessionManager.shared.credentials?.accessToken else {
            self.ContainerView.bringSubviewToFront(self.SettingButtonView)
            return
        }
        
        let url = URL(string: "https://2cea-2001-268-c0cd-6792-9137-42d2-f28d-c044.ngrok.io/goals")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let jsonData = data else {
                    self.ContainerView.bringSubviewToFront(self.SettingButtonView)
                    return
                }
                
                do{
                    let goals = try JSONDecoder().decode(Goals.self, from: jsonData)
                    let goal = goals.goals.last!
                    // ゴールのisAchievedがfalse && 期限が過ぎていない && 目標が達成されていない
                    if (goal.isAchieved == false) {
                        let targetVC = self.children[1] as! DisplayGoalViewController
                        targetVC.test(steps: goal.steps, term: goal.term, penalties: goal.penalties)
                        
                        self.ContainerView.bringSubviewToFront(self.DisplayGoalView)
                    } else {
                        self.ContainerView.bringSubviewToFront(self.SettingButtonView)
                    }
                }
                catch {
                    print(error)
                }
            }
        }
        task.resume()
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

