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
            case .idle: Text("weather_view_ready_to_load_data")
            case .loading: ProgressView("weather_view_fetching_data")
            case .success(let location): successView(location)
            case .noData: Text("weather_view_no_data_available")
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
            Text(location.address).font(.title)
            List(location.days) { day in
                VStack(alignment: .leading) {
                    WeatherDayRow(day: day)
                }
            }
            .listStyle(.plain)
        }
    }

    private func failureView(_ errorMessage: String) -> some View {
        VStack(spacing: 10) {
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
            
            Button("button_retry", action: loadWeather)
        }.padding()
    }
}

// MARK: - WeatherDayRow
private struct WeatherDayRow: View {
    let day: WeatherData
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                if day.dateString() == "Today" {
                    HStack(alignment: .bottom) {
                        Text(day.dateString())
                            .font(.title2)
                        Spacer()
                        Text("\(String(format: "%.0f", day.temp))°")
                            .foregroundColor(.secondary)
                            .font(.largeTitle)
                        Spacer()
                    }
                }
                else {
                    Text(day.dateString()).font(.title2)
                }
                
                Spacer()
                WeatherElement(icon: "arrow.up", text: "\(String(format: "%.0f", day.tempmax))°")
                WeatherElement(icon: "arrow.down", text: "\(String(format: "%.0f", day.tempmin))°")
                WeatherElement(icon: "sunrise", text: day.formattedSunrise)
                WeatherElement(icon: "sunset", text: day.formattedSunset)
            }
            
            Text(day.description)
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color.clear)
        .padding(.vertical, 10)
    }
}

// MARK: - WeatherElement
private struct WeatherElement: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption2)

            Text(text)
                .font(.callout)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - UI Helpers
private extension WeatherData {
    
    func dateString() -> String {
        self.formattedDate(for: TimeInterval(self.datetimeEpoch))
    }
    
    func formattedDate(for forecastEpoch: TimeInterval, dayLimit: Int = 6) -> String {
        let calendar = Calendar.current
        let currentDate = calendar.startOfDay(for: Date())
        let forecastDate = calendar.startOfDay(for: Date(timeIntervalSince1970: forecastEpoch))
        
        let dayDifference = calendar.dateComponents([.day], from: currentDate, to: forecastDate).day ?? 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        switch dayDifference {
        // TODO: Handle time difference in API result, replace with correcting dates for location
        case -1:
            return "Yesterday"
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        default:
            return formatter.string(from: forecastDate)
        }
    }
    
    var formattedSunrise: String {
        removeSeconds(sunrise)
    }
    
    var formattedSunset: String {
        removeSeconds(sunset)
    }
    
    func removeSeconds(_ time: String) -> String {
        let components = time.split(separator: ":")
        guard components.count == 3 else { return time } // Ensure it's in "HH:mm:ss" format
        return "\(components[0]):\(components[1])"  // Return "HH:mm"
    }
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
