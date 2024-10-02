//
//  WeatherModel.swift
//
//  Created by emile.
//

import Foundation

// MARK: - WeatherLocation
struct WeatherLocation: Codable, Identifiable {
    var id: String { resolvedAddress }
    let queryCost: Int
    let latitude: Double
    let longitude: Double
    let resolvedAddress: String
    let address: String
    let timezone: String
    let tzoffset: Int
    let days: [WeatherData]
}

// MARK: - WeatherData
struct WeatherData: Codable, Identifiable {
    var id: Int { datetimeEpoch }
    
    let datetime: String
    let datetimeEpoch: Int
    
    let tempmax: Double
    let tempmin: Double
    let temp: Double
    
    let feelslikemax: Double
    let feelslikemin: Double
    let feelslike: Double
    
    let dew: Double
    let humidity: Double
    
    let sunrise: String
    let sunset: String
}
