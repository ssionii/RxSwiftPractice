//
//  ViewController.swift
//  Wundercast
//
//  Created by  60117280 on 2021/03/31.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    
    @IBOutlet weak var cityNameTextField: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textSearch = cityNameTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        let temperature = tempSwitch.rx.controlEvent(.valueChanged).asObservable()
    
        let search = Observable
            .merge(textSearch, temperature)
            .map { self.cityNameTextField.text ?? "" }
            .filter { !$0.isEmpty }
            .flatMapLatest { text in
                ApiController.shared
                    .currentWeather(city: text)
                    .catchAndReturn(.empty)
            }
            .asDriver(onErrorJustReturn: .empty)
        
        search.map { w in
            if self.tempSwitch.isOn {
                let value = String(format: "%.1f", w.temperature * 1.8 + 32)
                return "\(value)° F"
            } else {
                let value = String(format: "%.1f", w.temperature)
                return "\(value)° C"
            }
        }
        .drive(tempLabel.rx.text)
        .disposed(by: bag)
            
        search.map { "\($0.humidity)%" }
            .drive(humidityLabel.rx.text)
            .disposed(by: bag)
        
        search.map { $0.icon }
            .drive(iconLabel.rx.text)
            .disposed(by: bag)
        
        search.map { $0.cityName }
            .drive(cityNameLabel.rx.text)
            .disposed(by: bag)
    }
}

