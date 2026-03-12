import Foundation

/// Represents an airport with all associated metadata.
public struct Airport: Equatable, Sendable {
    /// 3-letter IATA code (may be empty for some airports)
    public let iata: String
    /// 4-letter ICAO code (may be empty for some airports)
    public let icao: String
    /// Timezone identifier (e.g. "Asia/Singapore")
    public let time: String
    /// UTC offset in hours
    public let utc: Double
    /// 2-letter ISO country code
    public let countryCode: String
    /// 2-letter continent code (AS, EU, NA, SA, AF, OC, AN)
    public let continent: String
    /// Airport name
    public let airport: String
    /// Latitude coordinate
    public let latitude: Double
    /// Longitude coordinate
    public let longitude: Double
    /// Elevation in feet (nil if not available)
    public let elevationFt: Int?
    /// Airport type (large_airport, medium_airport, small_airport, heliport, seaplane_base)
    public let type: String
    /// Whether the airport has scheduled commercial service
    public let scheduledService: Bool
    /// Wikipedia URL (may be empty)
    public let wikipedia: String
    /// Airport website URL (may be empty)
    public let website: String
    /// Longest runway length in feet (nil if not available)
    public let runwayLength: Int?
    /// Flightradar24 tracking URL
    public let flightradar24Url: String
    /// RadarBox tracking URL
    public let radarboxUrl: String
    /// FlightAware tracking URL
    public let flightawareUrl: String

    public init(
        iata: String,
        icao: String,
        time: String,
        utc: Double,
        countryCode: String,
        continent: String,
        airport: String,
        latitude: Double,
        longitude: Double,
        elevationFt: Int?,
        type: String,
        scheduledService: Bool,
        wikipedia: String,
        website: String,
        runwayLength: Int?,
        flightradar24Url: String,
        radarboxUrl: String,
        flightawareUrl: String
    ) {
        self.iata = iata
        self.icao = icao
        self.time = time
        self.utc = utc
        self.countryCode = countryCode
        self.continent = continent
        self.airport = airport
        self.latitude = latitude
        self.longitude = longitude
        self.elevationFt = elevationFt
        self.type = type
        self.scheduledService = scheduledService
        self.wikipedia = wikipedia
        self.website = website
        self.runwayLength = runwayLength
        self.flightradar24Url = flightradar24Url
        self.radarboxUrl = radarboxUrl
        self.flightawareUrl = flightawareUrl
    }
}
