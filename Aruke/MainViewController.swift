//
//  ViewController.swift
//  Aruke
//
//  Created by ttanaka on 2022/03/11.
//

import UIKit
import Auth0
import HealthKit
import Stripe

class MainViewController: UIViewController {
    @IBOutlet weak var ContainerView: UIView!
    @IBOutlet weak var SettingButtonView: UIView!
    @IBOutlet weak var DisplayGoalView: UIView!
    var containers: Array<UIView> = []
    
    // stripe用
    var paymentSheet: PaymentSheet?
    let backendCheckoutUrl = URL(string: "https://a2c7-2001-268-c0cf-fd4d-9867-fa9-4a18-5de2.ngrok.io/payment-sheet")!
    
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
    
    var lastGoal: Goal?
    var stepsTotal: Double = 0.0
    var paymentFlag: Bool = false
    var semaphore = DispatchSemaphore(value: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) { // 戻ってきた時に実行されます
        super.viewWillAppear(animated)

        self.fetchGoal()
        
        let readDataTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        
        containers = [
            SettingButtonView,
            DisplayGoalView
        ]
        
        // 目標がない場合
        guard self.lastGoal != nil else {
            self.ContainerView.bringSubviewToFront(self.SettingButtonView)
            return
        }
        
        HKHealthStore().requestAuthorization(toShare: nil, read: readDataTypes) { success, _ in
            if success {
                self.getSteps()
                self.checkResult()
            }
        }
    }
    
    // グローバルな変数 lastGoalに最新の目標を格納するための関数
    private func fetchGoal() {
        guard let token = SessionManager.shared.credentials?.accessToken else {
            self.ContainerView.bringSubviewToFront(self.SettingButtonView)
            return
        }
        var request = URLRequest(url: URL(string: "https://a2c7-2001-268-c0cf-fd4d-9867-fa9-4a18-5de2.ngrok.io/goals")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: requestCompleteHandler).resume()
        semaphore.wait()
    }
    
    func requestCompleteHandler(data:Data?,res:URLResponse?,err:Error?) {
        guard let jsonData = data else { return }
        
        do{
            let goals = try JSONDecoder().decode(Goals.self, from: jsonData)
            if !goals.goals.isEmpty {
                print("==呼ばれた！！==")
                self.lastGoal = goals.goals.last!
            }
            semaphore.signal()
        } catch {
            print(error)
            semaphore.signal()
        }
    }

    // healthkitを使って歩数をグローバルな変数stepsTotalに格納
    private func getSteps() {
        var sampleArray: [Double] = []
        let calendar = Calendar(identifier: .gregorian)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let goaldate = dateFormatter.date(from: self.lastGoal!.createdAt)!
        let date:Date = calendar.date(from: DateComponents(year: goaldate.year, month: goaldate.month, day: goaldate.day))!
        let predicate = HKQuery.predicateForSamples(withStart: date, end: Date(), options: [])
        let query = HKStatisticsCollectionQuery(quantityType: HKObjectType.quantityType(forIdentifier: .stepCount)!,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: date,
                                                intervalComponents: DateComponents(day: 1))
        query.initialResultsHandler = { _, results, _ in
            guard let statsCollection = results else { return }
            statsCollection.enumerateStatistics(from: date, to: Date()) { statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let stepValue = quantity.doubleValue(for: HKUnit.count())
                    sampleArray.append(floor(stepValue))
                } else {
                    sampleArray.append(0.0)
                }
            }
            self.stepsTotal = sampleArray.reduce(0, +)
            self.semaphore.signal()
        }
        HKHealthStore().execute(query)
        semaphore.wait()
    }
    
    // 日付と目標の達成を確認する関数
    private func checkResult() {
        // 日付のフォーマット
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let goalTerm = formatter.date(from: self.lastGoal!.term)!
        
        // 最新の目標が達成されている場合
        if self.lastGoal!.isAchieved == true {
            DispatchQueue.main.sync {
                self.ContainerView.bringSubviewToFront(self.SettingButtonView)
            }
            return
        }
        
        // 目標が達成されていた場合、achievedを1に更新
        if stepsTotal >= Double(self.lastGoal!.steps) {
            self.achievedUpdate()
        }
        
        // 日付が超えていて目標が達成されていない場合
        if Date() >= goalTerm {
            paymentCreate()
        }
        
        // 日付が超えていなくて目標が達成されていない場合、進捗画面を出す
        DispatchQueue.main.sync {
            let targetVC = self.children[1] as! DisplayGoalViewController
            targetVC.test(
                steps: self.lastGoal!.steps,
                term: self.lastGoal!.term,
                penalties: self.lastGoal!.penalties
            )
            self.ContainerView.bringSubviewToFront(self.DisplayGoalView)
        }
    }
    
    private func achievedUpdate() {
        guard let token = SessionManager.shared.credentials?.accessToken else {
            return
        }
        var request = URLRequest(url: URL(string: "https://a2c7-2001-268-c0cf-fd4d-9867-fa9-4a18-5de2.ngrok.io/goals/\(self.lastGoal!.id)")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request).resume()
        self.ContainerView.bringSubviewToFront(self.SettingButtonView)
        return
    }
    
    func paymentCreate() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        let token = SessionManager.shared.credentials?.accessToken
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
          guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                let customerId = json["customer"] as? String,
                let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                let paymentIntentClientSecret = json["paymentIntent"] as? String,
                let self = self else {
            // Handle error
            return
          }

          // MARK: Create a PaymentSheet instance
          var configuration = PaymentSheet.Configuration()
          configuration.merchantDisplayName = "Example, Inc."
          configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
          self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
            self.semaphore.signal()
        
            DispatchQueue.main.async {
                self.didTapCheckoutButton()
            }
        })
        task.resume()
    }
    
    func didTapCheckoutButton() {
      paymentSheet?.present(from: self) { paymentResult in
        switch paymentResult {
        case .completed:
          print("Your order is confirmed")
            self.achievedUpdate()
        case .canceled:
          print("Canceled!")
        case .failed(let error):
          print("Payment failed: \n\(error.localizedDescription)")
        }
      }
    }
    
    //　テストログアウトボタンが押下された時
    @IBAction func tapLogout(_ sender: UIButton) {
        self.logout()
    }
    
    // ログアウト処理
    private func logout() {
        SessionManager.shared.logout()
        Auth0
            .webAuth()
            .clearSession(federated: false) { result in
                guard result else {return}
            }
    }
    
    
    
    
}


// 年だけを取得したい、月だけを取得したい
extension Date {

    var year: Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: self)
        return components.year!
    }

    var month: Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.month], from: self)
        return components.month!
    }

    var day: Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: self)
        return components.day!
    }

}

