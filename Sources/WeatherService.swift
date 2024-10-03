//
//  WeatherService.swift
//
//  Created by emile.
//

import Foundation

// MARK: - WeatherServiceError
enum WeatherServiceError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case unknownError
}

// MARK: - WeatherServiceProtocol

@MainActor
protocol WeatherServiceProtocol {
    func fetch(for location: String) async throws -> WeatherLocation
}

// MARK: - WeatherService
final class WeatherService: WeatherServiceProtocol {
    private let apiKey = Bundle.main.apiKey
    private let baseURL = Bundle.main.apiURL
    private let elements = Bundle.main.apiElements
    
    // MARK: - Fetch Weather Data
    func fetch(for location: String) async throws -> WeatherLocation {
        guard let url = constructURL(for: location) else {
            throw WeatherServiceError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw WeatherServiceError.invalidResponse
            }
            
            do {
                let weatherLocation = try JSONDecoder().decode(WeatherLocation.self, from: data)
                return weatherLocation
            } catch {
                throw WeatherServiceError.decodingError(error)
            }
            
        } catch {
            throw WeatherServiceError.requestFailed(error)
        }
    }
    
    // MARK: - URL Construction
    private func constructURL(for location: String) -> URL? {
        let queryParameters = "?unitGroup=metric&elements=\(elements)"
        // sofia?unitGroup=metric&elements=datetime%2Ctempmax%2Ctempmin&include=alerts%2Cdays&key=P5DWQL3AWZWQWBX9NTNSPWPYF&contentType=json
        let contentType = "&contentType=json"
        
        let urlString = "\(baseURL)/\(location)/\(queryParameters)&key=\(apiKey)\(contentType)"
        return URL(string: urlString)
    }
}

// MARK: - WeatherServiceMock
final class WeatherServiceMock: WeatherServiceProtocol {
    enum MockBehavior {
        case success(WeatherLocation)
        case failure(WeatherServiceError)
    }
    
    private var behavior: MockBehavior
    
    init(behavior: MockBehavior) {
        self.behavior = behavior
    }
    
    // MARK: - Fetch Weather Data
    func fetch(for location: String) async throws -> WeatherLocation {
        switch behavior {
        case .success(let mockWeatherLocation):
            return mockWeatherLocation
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - WeatherServiceMock (Helper Methods)
extension WeatherServiceMock {
    
    // MARK: - Random Data Generation
    static func withRandomData() -> WeatherServiceMock {
        let randomWeatherData = (0..<10).map { dayOffset in
            WeatherData(
                datetime: dateString(from: dayOffset),
                datetimeEpoch: epoch(from: dayOffset),
                temp: Double.random(in: 0...20),
                tempmax: Double.random(in: 15...35),
                tempmin: Double.random(in: 5...15),
                dew: Double.random(in: 5...20),
                sunrise: randomTime(),
                sunset: randomTime(),
                description: "Partly cloudy throughout the day.",
                hours: randomHourlyData()
            )
        }
        
        let randomWeatherLocation = WeatherLocation(
            queryCost: 1,
            latitude: Double.random(in: -90...90),
            longitude: Double.random(in: -180...180),
            resolvedAddress: randomResolvedAddress(),
            address: randomAddress(),
            timezone: "Europe/\(randomAddress())",
            tzoffset: Double.random(in: -12...12),
            days: randomWeatherData,
            alerts: [],
            currentConditions: randomCurrentConditions()
        )
        
        return WeatherServiceMock(behavior: .success(randomWeatherLocation))
    }
    
    static func withRandomError() -> WeatherServiceMock {
        let possibleErrors: [WeatherServiceError] = [
            .invalidURL,
            .invalidResponse,
            .decodingError(NSError(domain: "", code: -1, userInfo: nil)),
            .unknownError
        ]
        
        let randomError = possibleErrors.randomElement() ?? .unknownError
        return WeatherServiceMock(behavior: .failure(randomError))
    }
    
    // MARK: - Helper Methods for Random Data Generation
    private static func randomAddress() -> String {
        let address = ["New York",
                      "London",
                      "Tokyo",
                      "Paris",
                      "Berlin",
                      "Sydney"]
        return address.randomElement() ?? "Unknown address"
    }
    
    private static func randomResolvedAddress() -> String {
        let address = ["New York, NY, United States",
                      "London, England, United Kingdom",
                      "Tokyo, Japan",
                      "Paris, ÃŽle-de-France, France",
                      "Berlin, Deutschland",
                      "Sydney, NSW 2000, Australia"]
        return address.randomElement() ?? "Unknown resolved address"
    }
    
    private static func dateString(from dayOffset: Int) -> String {
        let currentDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currentDate)
    }
    
    private static func epoch(from dayOffset: Int) -> Int {
        let currentDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
        return Int(currentDate.timeIntervalSince1970)
    }
    
    private static func randomTime() -> String {
        let hour = Int.random(in: 5...7)
        let minute = Int.random(in: 0...59)
        let second = Int.random(in: 0...59)
        return String(format: "%02d:%02d:%02d", hour, minute, second)
    }
    
    private static func randomHourlyData() -> [WeatherHour] {
        return (0..<24).map { _ in
            WeatherHour(dew: Double.random(in: -5...10))
        }
    }
    
    private static func randomCurrentConditions() -> CurrentConditions {
        return CurrentConditions(
            dew: Double.random(in: 0...20),
            sunrise: randomTime(),
            sunset: randomTime()
        )
    }
}

// MARK: - Bundle Extension
private extension Bundle {
    var apiURL: String {
        guard let url = object(forInfoDictionaryKey: "ServiceURL") as? String else {
            fatalError("Missing API URL in Info.plist")
        }
        return url
    }
    
    var apiKey: String {
        guard let key = object(forInfoDictionaryKey: "ServiceKey") as? String else {
            fatalError("Missing API key in Info.plist")
        }
        return key
    }
    
    var apiElements: String {
        guard let elements = object(forInfoDictionaryKey: "ServiceElements") as? String else {
            fatalError("Missing API Elements in Info.plist")
        }
        return elements
    }
}
