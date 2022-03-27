//
//  SettingButtonViewController.swift
//  Aruke
//
//  Created by mshimomura on 2022/03/24.
//

import UIKit

class SettingButtonViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func SettingButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "SettingGoal", bundle: nil)
        let nextView = storyboard.instantiateViewController(identifier: "SettingGoalView")
        nextView.modalPresentationStyle = .fullScreen
        nextView.modalTransitionStyle = .coverVertical
        self.present(nextView, animated: true, completion: nil)
    }
}
