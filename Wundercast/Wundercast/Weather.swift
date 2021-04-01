//
//  Weather.swift
//  Wundercast
//
//  Created by  60117280 on 2021/03/31.
//

import Foundation

struct Weather: Decodable {
    let cityName: String
    let temperature: Double
    let humidity: Int
    let icon: String
    
    static let empty = Weather(
        cityName: "Unknown",
        temperature: -1000.0,
        humidity: 0,
        icon: iconNameToChar(icon: "e")
    )
    
    init(cityName: String,
         temperature: Double,
         humidity: Int,
         icon: String) {
        self.cityName = cityName
        self.temperature = temperature
        self.humidity = humidity
        self.icon = icon
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cityName = try values.decode(String.self, forKey: .cityName)
        let info = try values.decode([AdditionalInfo].self, forKey: .weather)
        icon = iconNameToChar(icon: info.first?.icon ?? "")

        let mainInfo = try values.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
        temperature = try mainInfo.decode(Double.self, forKey: .temp)
        humidity = try mainInfo.decode(Int.self, forKey: .humidity)
    }
    
    enum CodingKeys: String, CodingKey {
        case cityName = "name"
        case main
        case weather
    }
    
    enum MainKeys: String, CodingKey {
        case temp
        case humidity
    }
    
    private struct AdditionalInfo: Decodable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
}

/**
 * Maps an icon information from the API to a local char
 * Source: http://openweathermap.org/weather-conditions
 */
public func iconNameToChar(icon: String) -> String {
    switch icon {
    case "01d":
        return "\u{f11b}"
    case "01n":
        return "\u{f110}"
    case "02d":
        return "\u{f112}"
    case "02n":
        return "\u{f104}"
    case "03d", "03n":
        return "\u{f111}"
    case "04d", "04n":
        return "\u{f111}"
    case "09d", "09n":
        return "\u{f116}"
    case "10d", "10n":
        return "\u{f113}"
    case "11d", "11n":
        return "\u{f10d}"
    case "13d", "13n":
        return "\u{f119}"
    case "50d", "50n":
        return "\u{f10e}"
    default:
        return "E"
    }
}
