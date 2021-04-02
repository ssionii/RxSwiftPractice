//
//  ViewController.swift
//  Wundercast
//
//  Created by  60117280 on 2021/03/31.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation
import MapKit

class ViewController: UIViewController {

    
    @IBOutlet weak var cityNameTextField: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    private let locationManager = CLLocationManager()
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapButton.rx.tap
            .subscribe(onNext: {
                self.mapView.isHidden.toggle()
            })
            .disposed(by: bag)
        
        mapView.rx
            .setDelegate(self)
            .disposed(by: bag)
        
        
        let currentLocation = locationManager.rx.didUpdateLocations
            .map { location in
                return location[0]
            }
            .filter { location in
                return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
            }
        
        let geoInput = geoLocationButton.rx.tap.asObservable()
            .do(onNext: { _ in
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
        
        let geoLocation = geoInput.flatMap {
            return currentLocation.take(1)
        }
        
        let geoSearch = geoLocation.flatMap { location in
            return ApiController.shared.currentWeather(at: location.coordinate )
                .catchAndReturn(.empty)
            
        }
        
        // textField에 입력되는 검색할 도시 이름
        let searchInput = cityNameTextField.rx
            .controlEvent(.editingDidEndOnExit)
            .map { self.cityNameTextField.text ?? "" }
            .filter { !$0.isEmpty }
        
        // 입력된 도시 이름을 바탕으로 검색
        // 검색 결과가 search로 들어옴
        let textSearch = searchInput.flatMap { text in
            return ApiController.shared.currentWeather(city: text)
                .catchAndReturn(.empty)
        }
        
        let mapInput = mapView.rx.regionDidChangeAnimated
            .skip(1)
            .map { _ in self.mapView.centerCoordinate }
        
        let mapSearch = mapInput.flatMap { location in
            return ApiController.shared.currentWeather(at: location)
                .catchAndReturn(.empty)
        }
    
        
        let search = Observable.from([
            geoSearch, textSearch, mapSearch
        ])
        .merge()
        .asDriver(onErrorJustReturn: .empty)
        
        
        let running = Observable.from([
            searchInput.map { _ in true },
            geoInput.map { _ in true },
            mapInput.map { _ in true },
            search.map { _ in false }.asObservable()
        ])
        .merge()
        .startWith(true)
        .asDriver(onErrorJustReturn: false)
        
        running
            .skip(1)
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: bag)
        
        running
        .drive(tempLabel.rx.isHidden)
        .disposed(by: bag)
            
        running
            .drive(humidityLabel.rx.isHidden)
            .disposed(by: bag)
        
        running
            .drive(iconLabel.rx.isHidden)
            .disposed(by: bag)
        
        running
            .drive(cityNameLabel.rx.isHidden)
            .disposed(by: bag)
        
        search.map { "\($0.temperature)° C" }
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
        
        search.map { $0.overlay() }
            .drive(mapView.rx.overlay)
            .disposed(by: bag)
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? Weather.Overlay {
            let overlayView = Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
            return overlayView
        }
        return MKOverlayRenderer()
    }
}
