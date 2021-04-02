//
//  CLLocationManager+Rx.swift
//  Wundercast
//
//  Created by  60117280 on 2021/04/01.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

extension CLLocationManager: HasDelegate {}

class RxCLLocationMangerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
    
    weak public private(set) var locationManager: CLLocationManager?
    
    public init(locationManager: ParentObject) {
        self.locationManager = locationManager
        super.init(
            parentObject: locationManager,
            delegateProxy: RxCLLocationMangerDelegateProxy.self
        )
    }
    
    
    static func registerKnownImplementations() {
        register { RxCLLocationMangerDelegateProxy(locationManager: $0) }
    }
    
}

extension Reactive where Base: CLLocationManager {
    var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        RxCLLocationMangerDelegateProxy.proxy(for: base)
    }
    
    var didUpdateLocations: Observable<[CLLocation]> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:))).map { parameters in
            return parameters[1] as! [CLLocation]
        }
    }
}
