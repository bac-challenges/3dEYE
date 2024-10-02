//
//  LocationService.swift
//
//  Created by emile.
//

import CoreLocation

// MARK: - Protocol Definition
@MainActor
protocol LocationServiceProtocol {
    func getCurrentCityName() async -> Result<String, LocationError>
}

// MARK: - Error Definition
enum LocationError: Error {
    case locationServicesDisabled
    case failedToGetLocation
    case failedToGetCityName
}

// MARK: - Mock Behavior Definition
enum LocationServiceMockBehavior {
    case success(cityName: String)
    case failure(LocationError)
}

// MARK: - Location Service Implementation
@Observable
final class LocationService: NSObject, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Request Location with async/await
    func requestLocation() async throws -> CLLocation {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.locationServicesDisabled
        }

        locationManager.requestWhenInUseAuthorization()
        
        return try await withCheckedThrowingContinuation { continuation in
            locationManager.delegate = self
            locationManager.requestLocation()
            self.continuation = continuation
        }
    }
    
    // MARK: - Fetch City Name from Coordinates
    func fetchCityName(from location: CLLocation) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let city = placemarks?.first?.locality {
                    continuation.resume(returning: city)
                } else {
                    continuation.resume(throwing: LocationError.failedToGetCityName)
                }
            }
        }
    }
    
    // MARK: - Combined Function to Get Current City Name
    func getCurrentCityName() async -> Result<String, LocationError> {
        do {
            let location = try await requestLocation()
            let city = try await fetchCityName(from: location)
            return .success(city)
        } catch let error as LocationError {
            return .failure(error)
        } catch {
            return .failure(.failedToGetLocation)
        }
    }
}

// MARK: - CLLocationManagerDelegate Methods
extension LocationService: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            continuation?.resume(returning: location)
            continuation = nil
        } else {
            continuation?.resume(throwing: LocationError.failedToGetLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}

// MARK: - Mock Location Service for Testing
@Observable
final class LocationServiceMock: LocationServiceProtocol {
    private let shouldFail: Bool
    private let failureType: LocationError?
    private let city: String
    
    init(shouldFail: Bool = false, failureType: LocationError? = nil, city: String = "Sofia") {
        self.shouldFail = shouldFail
        self.failureType = failureType
        self.city = city
    }
    
    func getCurrentCityName() async -> Result<String, LocationError> {
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            if shouldFail {
                if let failureType = failureType {
                    throw failureType
                } else {
                    throw LocationError.failedToGetCityName
                }
            }
            return .success(city)
        } catch let error as LocationError {
            return .failure(error)
        } catch {
            return .failure(.failedToGetCityName)
        }
    }
}
