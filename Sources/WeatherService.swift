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
        let queryParameters = "today?unitGroup=metric&elements=\(elements)"
        let contentType = "&contentType=json"
        
        let urlString = "\(baseURL)/\(location)/\(queryParameters)&key=\(apiKey)\(contentType)"
        return URL(string: urlString)
    }
}

// MARK: - WeatherServiceMock
final class WeatherServiceMock: WeatherServiceProtocol {
    enum MockBehavior {
        case success(WeatherLocation)            // Simulates a successful weather fetch with location and 10 days of weather data.
        case failure(WeatherServiceError)        // Simulates a failure in fetching weather data.
    }
    
    private var behavior: MockBehavior           // Stores the predefined behavior (success or failure).
    
    init(behavior: MockBehavior) {
        self.behavior = behavior
    }
    
    // MARK: - Fetch Weather Data
    func fetch(for location: String) async throws -> WeatherLocation {
        switch behavior {
        case .success(let mockWeatherLocation):
            return mockWeatherLocation  // Return the mock weather location data on success.
        case .failure(let error):
            throw error  // Throw the predefined error on failure.
        }
    }
}

// MARK: - WeatherServiceMock Extension (Helper Methods)
extension WeatherServiceMock {

    // MARK: - Random Data Generation
    static func withRandomData() -> WeatherServiceMock {
        let randomWeatherData = (0..<10).map { _ in
            WeatherData(
                datetime: randomDateString(),
                datetimeEpoch: randomEpoch(),
                tempmax: Double.random(in: 15...35),
                tempmin: Double.random(in: 5...15),
                temp: Double.random(in: 10...25),
                feelslikemax: Double.random(in: 15...35),
                feelslikemin: Double.random(in: 5...15),
                feelslike: Double.random(in: 10...25),
                dew: Double.random(in: 5...20),
                humidity: Double.random(in: 50...100),
                sunrise: randomTime(),
                sunset: randomTime()
            )
        }
        
        let randomWeatherLocation = WeatherLocation(
            queryCost: 1,                                  // Random query cost.
            latitude: Double.random(in: -90...90),         // Random latitude.
            longitude: Double.random(in: -180...180),      // Random longitude.
            resolvedAddress: randomCityName(),             // Random city name.
            address: randomCityName(),                     // Random short address.
            timezone: "Europe/\(randomCityName())",        // Random timezone.
            tzoffset: Int.random(in: -12...12),            // Random timezone offset.
            days: randomWeatherData                        // The array of 10 days of weather data.
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
    private static func randomCityName() -> String {
        let cities = ["New York", "London", "Tokyo", "Paris", "Berlin", "Sydney"]
        return cities.randomElement() ?? "Unknown City"
    }
    
    private static func randomDateString() -> String {
        let randomDays = Int.random(in: 0...10)
        let currentDate = Calendar.current.date(byAdding: .day, value: randomDays, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currentDate)
    }
    
    private static func randomEpoch() -> Int {
        let randomDays = Int.random(in: 0...10)
        let currentDate = Calendar.current.date(byAdding: .day, value: randomDays, to: Date())!
        return Int(currentDate.timeIntervalSince1970)
    }
    
    private static func randomTime() -> String {
        let hour = Int.random(in: 5...7)
        let minute = Int.random(in: 0...59)
        let second = Int.random(in: 0...59)
        return String(format: "%02d:%02d:%02d", hour, minute, second)
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
