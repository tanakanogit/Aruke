//
//  SettingGoalViewController.swift
//  Aruke
//
//  Created by mshimomura on 2022/03/24.
//

import UIKit

class SettingGoalViewController: UIViewController {
    @IBOutlet weak var stepsNum: UITextField!
    @IBOutlet weak var penaltiesNum: UITextField!
    @IBOutlet weak var termDate: UIDatePicker!
    
    var semaphore : DispatchSemaphore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func createGoal(_ sender: Any) {
        self.callAPI()
        self.dismiss(animated: true)
    }
    
    private func callAPI() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let json: [String: Any] = [
            "goal": [
                "steps": Int(stepsNum.text!),
                "term": dateFormatter.string(from: termDate.date),
                "penalties": Int(penaltiesNum.text!)
            ]
        ]
        
        semaphore = DispatchSemaphore(value: 0)
        
        let token = SessionManager.shared.credentials?.accessToken
        var request = URLRequest(url: URL(string: "https://2cea-2001-268-c0cd-6792-9137-42d2-f28d-c044.ngrok.io/goals")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: json) // param
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: requestCompleteHandler).resume()
        semaphore.wait()
    }
    
    func requestCompleteHandler(data:Data?,res:URLResponse?,err:Error?) {
        if let err = err {
            print(err.localizedDescription)
            return
        }
        semaphore.signal()
    }
}
