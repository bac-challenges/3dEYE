//
//  WeatherViewModel.swift
//
//  Created by emile.
//

import Foundation

// MARK: - WeatherViewState
enum WeatherViewState {
    case loading
    case success(WeatherLocation)
    case failure(String)
    case noData
    case idle
}

// MARK: - WeatherViewModel
@MainActor
@Observable
final class WeatherViewModel {
    
    // MARK: - Properties
    var state: WeatherViewState = .idle
    private var weatherService: WeatherServiceProtocol
    private var locationService: LocationServiceProtocol
    
    // MARK: - Initialization
    init(weatherService: WeatherServiceProtocol, locationService: LocationServiceProtocol) {
        self.weatherService = weatherService
        self.locationService = locationService
    }
    
    // MARK: - Load Weather Data
    func loadWeather() async {
        self.state = .loading
        let cityNameResult = await locationService.getCurrentCityName()
        
        switch cityNameResult {
        case .success(let cityName):
            do {
                let weatherLocation = try await weatherService.fetch(for: cityName)
                self.state = .success(weatherLocation)
            } catch let weatherServiceError as WeatherServiceError {
                handleWeatherServiceError(weatherServiceError)
            } catch {
                self.state = .failure("An unexpected error occurred: \(error.localizedDescription)")
            }
            
        case .failure(let locationError):
            handleLocationServiceError(locationError)
        }
    }
    
    // MARK: - Error Handling
    private func handleWeatherServiceError(_ error: WeatherServiceError) {
        switch error {
        case .invalidURL:
            self.state = .failure("The weather service URL is invalid.")
        case .requestFailed(let networkError):
            self.state = .failure("Network request failed: \(networkError.localizedDescription)")
        case .invalidResponse:
            self.state = .failure("The weather service returned an invalid response.")
        case .decodingError(let decodingError):
            self.state = .failure("Failed to decode weather data: \(decodingError.localizedDescription)")
        case .unknownError:
            self.state = .failure("An unknown error occurred.")
        }
    }
    
    private func handleLocationServiceError(_ error: LocationError) {
        switch error {
        case .locationServicesDisabled:
            self.state = .failure("Location services are disabled.")
        case .failedToGetLocation:
            self.state = .failure("Failed to get the current location.")
        case .failedToGetCityName:
            self.state = .failure("Failed to get the city name.")
        }
    }
}
