import Foundation

/// External links for an airport.
public struct AirportLinks: Equatable, Sendable {
    public let website: String?
    public let wikipedia: String?
    public let flightradar24: String?
    public let radarbox: String?
    public let flightaware: String?
}

/// Statistics about airports in a country.
public struct AirportCountryStats: Equatable, Sendable {
    public let total: Int
    public let byType: [String: Int]
    public let withScheduledService: Int
    public let averageRunwayLength: Double
    public let averageElevation: Double
    public let timezones: [String]
}

/// Statistics about airports on a continent.
public struct AirportContinentStats: Equatable, Sendable {
    public let total: Int
    public let byType: [String: Int]
    public let byCountry: [String: Int]
    public let withScheduledService: Int
    public let averageRunwayLength: Double
    public let averageElevation: Double
    public let timezones: [String]
}

/// Distance matrix result between multiple airports.
public struct DistanceMatrix: Equatable, Sendable {
    /// Information about each airport in the matrix.
    public struct AirportInfo: Equatable, Sendable {
        public let code: String
        public let name: String
        public let iata: String
        public let icao: String
    }

    public let airports: [AirportInfo]
    public let distances: [String: [String: Double]]
}

/// Filters for advanced airport search.
public struct AirportFilter: Sendable {
    public var countryCode: String?
    public var continent: String?
    public var type: String?
    public var hasScheduledService: Bool?
    public var minRunwayFt: Int?

    public init(
        countryCode: String? = nil,
        continent: String? = nil,
        type: String? = nil,
        hasScheduledService: Bool? = nil,
        minRunwayFt: Int? = nil
    ) {
        self.countryCode = countryCode
        self.continent = continent
        self.type = type
        self.hasScheduledService = hasScheduledService
        self.minRunwayFt = minRunwayFt
    }
}

/// Filters for finding the nearest airport.
public struct NearestAirportFilter: Sendable {
    public var type: String?
    public var countryCode: String?
    public var hasScheduledService: Bool?

    public init(
        type: String? = nil,
        countryCode: String? = nil,
        hasScheduledService: Bool? = nil
    ) {
        self.type = type
        self.countryCode = countryCode
        self.hasScheduledService = hasScheduledService
    }
}

/// An airport with an additional distance field (used for nearby/nearest results).
public struct AirportWithDistance: Sendable {
    public let airport: Airport
    /// Distance in kilometers from the reference point.
    public let distance: Double
}
