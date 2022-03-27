//
//  DisplayGoalViewController.swift
//  Aruke
//
//  Created by mshimomura on 2022/03/24.
//

import UIKit

class DisplayGoalViewController: UIViewController {
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var termLabel: UILabel!
    @IBOutlet weak var penaltiesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func test(steps: Int, term: String, penalties: Int) {
        self.stepsLabel.text = "目標歩数: \(steps) 歩"
        self.termLabel.text = "目標達成期限: \(term)"
        self.penaltiesLabel.text = "決心の金額: \(penalties) 円"
    }
    
    
}
