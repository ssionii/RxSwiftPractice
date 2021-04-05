//
//  ViewController.swift
//  MVVMPractice
//
//  Created by  60117280 on 2021/04/05.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var viewModel = ViewModel()
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bind(viewModel: self.viewModel)
    }
    
    // view와 viewModel을 bind
    private func bind(viewModel: ViewModel) {
        
        // number를 구독하고 label.text에 바인딩
        self.viewModel.number
            .drive(self.label.rx.text)
            .disposed(by: self.disposeBag)
        
        // button 클릭 이벤트와 viewModel.tap을 연결 (input)
        self.button.rx.tap
            .bind(to: viewModel.tap)
            .disposed(by: self.disposeBag)
    }


}

