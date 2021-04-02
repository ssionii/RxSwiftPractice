//
//  Weather.swift
//  Wundercast
//
//  Created by  60117280 on 2021/03/31.
//

import Foundation
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

struct Weather: Decodable {
    let cityName: String
    let temperature: Double
    let humidity: Int
    let icon: String
    let coordinate: CLLocationCoordinate2D
    
    static let empty = Weather(
        cityName: "Unknown",
        temperature: -1000.0,
        humidity: 0,
        icon: iconNameToChar(icon: "e"),
        coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
    )
    
    init(cityName: String,
         temperature: Double,
         humidity: Int,
         icon: String,
         coordinate: CLLocationCoordinate2D) {
        
        self.cityName = cityName
        self.temperature = temperature
        self.humidity = humidity
        self.icon = icon
        self.coordinate = coordinate
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cityName = try values.decode(String.self, forKey: .cityName)
        let info = try values.decode([AdditionalInfo].self, forKey: .weather)
        icon = iconNameToChar(icon: info.first?.icon ?? "")
        
        let mainInfo = try values.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
        temperature = try mainInfo.decode(Double.self, forKey: .temp)
        humidity = try mainInfo.decode(Int.self, forKey: .humidity)
        let coor = try values.decode(Coordinate.self, forKey: .coordinate)
        coordinate = CLLocationCoordinate2D(latitude: coor.lat, longitude: coor.lon)
    }
    
    enum CodingKeys: String, CodingKey {
        case cityName = "name"
        case main
        case weather
        case coordinate = "coord"
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
    
    private struct Coordinate: Decodable {
        let lat: CLLocationDegrees
        let lon: CLLocationDegrees
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

private func imageFromText(text: String, font: UIFont) -> UIImage {
    let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    text.draw(at: CGPoint(x: 0, y: 0), withAttributes: [NSAttributedString.Key.font: font])
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image ?? UIImage()
}

extension Weather {
    func overlay() -> Overlay {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: coordinate.latitude - 0.25,
                                   longitude: coordinate.longitude - 0.25),
            CLLocationCoordinate2D(latitude: coordinate.latitude + 0.25,
                                   longitude: coordinate.longitude + 0.25)
        ]
        
        let points = coordinates.map { MKMapPoint($0) }
        let rects = points.map { MKMapRect(origin: $0, size: MKMapSize(width: 0, height: 0)) }
        let mapRectUnion: (MKMapRect, MKMapRect) -> MKMapRect = { $0.union($1) }
        let fittingRect = rects.reduce(MKMapRect.null, mapRectUnion)
        return Overlay(icon: icon, coordinate: coordinate, boundingMapRect: fittingRect)
    }
    
    class Overlay: NSObject, MKOverlay {
        var coordinate: CLLocationCoordinate2D
        var boundingMapRect: MKMapRect
        let icon: String
        
        init(icon: String, coordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
            self.coordinate = coordinate
            self.boundingMapRect = boundingMapRect
            self.icon = icon
        }
    }
    
    class OverlayView: MKOverlayRenderer {
        var overlayIcon: String
        
        init(overlay:MKOverlay, overlayIcon:String) {
            self.overlayIcon = overlayIcon
            super.init(overlay: overlay)
        }
        
        public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
            let imageReference = imageFromText(text: overlayIcon, font: UIFont.systemFont(ofSize: CGFloat(28))).cgImage
            let theMapRect = overlay.boundingMapRect
            let theRect = rect(for: theMapRect)
            
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0.0, y: -theRect.size.height)
            context.draw(imageReference!, in: theRect)
        }
    }
}
