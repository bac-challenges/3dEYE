//
//  WeatherApp.swift
//
//  Created by emile.
//

import SwiftUI

// MARK: - Main Application Entry Point
@main
struct WeatherApp: App {
    var body: some Scene {
        WindowGroup {
            WeatherView()
                .environment(
                    WeatherViewModel(
                        weatherService: WeatherService(),
                        locationService: LocationServiceMock()
                    )
                )
        }
    }
}


// MARK: - ContentView
struct WeatherView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    var body: some View {
        VStack {
            switch viewModel.state {
            case .idle: Text("Ready to load weather data.")
            case .loading: ProgressView("Fetching weather...")
            case .success(let location): successView(location)
            case .noData: Text("No weather data available.")
            case .failure(let errorMessage): failureView(errorMessage)
            }
        }.onAppear(perform: loadWeather)
    }
    
    // MARK: - Helper Methodes
    private func loadWeather() {
        Task {
            await viewModel.loadWeather()
        }
    }
    
    // MARK: - Helper Views
    private func successView(_ location: WeatherLocation) -> some View {
        VStack {
            Text("City: \(location.resolvedAddress)").font(.title2)
            List(location.days) { day in
                WeatherDayRow(day: day)
            }
        }
    }

    private func failureView(_ errorMessage: String) -> some View {
        VStack(spacing: 10) {
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
            
            Button("Retry", action: loadWeather)
        }.padding()
    }
}

// MARK: -
private struct WeatherDayRow: View {
    let day: WeatherData
    var body: some View {
        VStack(alignment: .leading) {
            Text(day.dayName).font(.headline)
            Text("Max Temp: \(String(format: "%.1f", day.tempmax))°C")
            Text("Min Temp: \(String(format: "%.1f", day.tempmin))°C")
            Text("Dew: \(String(format: "%.1f", day.dew))")
            Text("Sunrise: \(day.sunrise)")
            Text("Sunset: \(day.sunset)")
        }
        .listRowBackground(Color.clear)
        .padding(.vertical, 4)
    }
}

// MARK: -
private extension WeatherData {
    var dayName: String {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let forecastDate = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(datetimeEpoch)))
        
        let dayDifference = Calendar.current.dateComponents([.day], from: currentDate, to: forecastDate).day ?? 0
        
        switch dayDifference {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default:
            return WeatherData.dayFormatter.string(from: forecastDate)
        }
    }
    
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"  // e.g., "Sunday"
        return formatter
    }()
}

// MARK: - Previews

// Simulate a successful fetch of both location and weather data.
#Preview("Weather Success") {
    WeatherView()
        .environment(
            WeatherViewModel(
                weatherService: WeatherServiceMock.withRandomData(),  // Mock weather service returning valid random data.
                locationService: LocationServiceMock()  // Simulate successful location fetch.
            )
        )
}

// Simulate a scenario where the weather service fails to fetch data (e.g., bad response or network issue).
#Preview("Weather Failure") {
    WeatherView()
        .environment(
            WeatherViewModel(
                weatherService: WeatherServiceMock(behavior: .failure(.invalidResponse)),  // Simulate a weather service failure.
                locationService: LocationServiceMock()  // Simulate a successful location fetch.
            )
        )
}

// Simulate a scenario where the location service fails to fetch the user's location.
#Preview("Location Failure") {
    WeatherView()
        .environment(
            WeatherViewModel(
                weatherService: WeatherServiceMock.withRandomData(),    // Use a mock weather service that returns random data.
                locationService: LocationServiceMock(shouldFail: true)  // Simulate failure in fetching the location.
            )
        )
}
