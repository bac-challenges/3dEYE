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
    let tzoffset: Double
    let days: [WeatherData]
    let alerts: [String]
    let currentConditions: CurrentConditions
}

// MARK: - WeatherData
struct WeatherData: Codable, Identifiable {
    var id: Int { datetimeEpoch }
    
    let datetime: String
    let datetimeEpoch: Int
    
    let temp: Double
    let tempmax: Double
    let tempmin: Double
    
    let dew: Double
    let sunrise: String
    let sunset: String
    
    let description: String
    
    let hours: [WeatherHour]
}

// MARK: - WeatherHour
struct WeatherHour: Codable {
    let dew: Double
}

// MARK: - CurrentConditions
struct CurrentConditions: Codable {
    let dew: Double
    let sunrise: String
    let sunset: String
}
