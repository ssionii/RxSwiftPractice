//
//  ViewModel.swift
//  MVVMPractice
//
//  Created by  60117280 on 2021/04/05.
//

import Foundation
import RxSwift
import RxCocoa

protocol ViewModelType {
    var tap: PublishRelay<Void> { get }
    var number: Driver<String> { get }
}

class ViewModel: ViewModelType {
    
    // input
    var tap = PublishRelay<Void>()
    
    // output
    var number: Driver<String>
    
    private let model = BehaviorRelay<Model>(value: .init(number: 100))
    
    let disposeBag = DisposeBag()
    
    init() {
        // model이 바뀌면 거기서 number 값 뽑아와서 number로 넘김
        // number은 driver
        self.number = self.model
            .map {
                return "\($0.number)"
            }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        // tap 이벤트가 들어오면, model 값이 바뀜
        self.tap
            .withLatestFrom(model)
            .map { model -> Model in
                var nextModel = model
                nextModel.number += 1
                return nextModel
            }
            .bind(to: self.model)
            .disposed(by: disposeBag)
    }
    
    // 궁금증.
    // model 자체를 구독할 수는 없나...?
   
}
