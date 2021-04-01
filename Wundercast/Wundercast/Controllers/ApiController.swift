//
//  ApiController.swift
//  Wundercast
//
//  Created by  60117280 on 2021/03/31.
//

import UIKit
import RxSwift

class ApiController {
    
    static var shared = ApiController()
    
    let baseURL = URL(string: "https://api.openweathermap.org/data/2.5")!
    private let apiKey = "9f94ce916b3f0cf95e63edb4bf498ca4"
    
    func currentWeather(city: String) -> Observable<Weather> {
        return buildRequest(pathComponent: "weather", params: [("q", city)])
            .map { data in
                try JSONDecoder().decode(Weather.self, from: data)
            }
    }

    private func buildRequest(method: String = "GET", pathComponent: String, params: [(String, String)]) -> Observable<Data> {
        let url = baseURL.appendingPathComponent(pathComponent)
        var request = URLRequest(url: url)
        let keyQueryItem = URLQueryItem(name: "appid", value: apiKey)
        let unitsQueryItem = URLQueryItem(name: "units", value: "metric")
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        if method == "GET" {
            var quertyItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
            quertyItems.append(keyQueryItem)
            quertyItems.append(unitsQueryItem)
            urlComponents.queryItems = quertyItems
        } else {
            urlComponents.queryItems = [keyQueryItem, unitsQueryItem]
            
            let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        }
        
        request.url = urlComponents.url!
        request.httpMethod = method
        
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        
        let session = URLSession.shared
        
        return session.rx.data(request: request)
    }
}
