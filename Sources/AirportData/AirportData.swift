import Foundation

/// A comprehensive library for retrieving airport information by IATA codes, ICAO codes,
/// and various other criteria.
///
/// All methods are synchronous and thread-safe. Data is lazily loaded on first access
/// and cached for subsequent calls.
///
/// ## Usage
/// ```swift
/// let airports = try AirportData.getAirportByIata("SIN")
/// let distance = try AirportData.calculateDistance("LHR", "JFK")
/// ```
public enum AirportData {

    private static var store: AirportDataStore { AirportDataStore.shared }

    // MARK: - Core Search Functions

    /// Finds airports by their 3-letter IATA code.
    /// - Parameter iataCode: The IATA code to search for (case-insensitive).
    /// - Returns: An array of airports matching the IATA code.
    /// - Throws: `AirportDataError.noDataFound` if no airports match.
    public static func getAirportByIata(_ iataCode: String) throws -> [Airport] {
        let code = iataCode.uppercased().trimmingCharacters(in: .whitespaces)
        guard let airports = store.iataIndex[code], !airports.isEmpty else {
            throw AirportDataError.noDataFound("No data found for IATA code: \(iataCode)")
        }
        return airports
    }

    /// Finds airports by their 4-character ICAO code.
    /// - Parameter icaoCode: The ICAO code to search for (case-insensitive).
    /// - Returns: An array of airports matching the ICAO code.
    /// - Throws: `AirportDataError.noDataFound` if no airports match.
    public static func getAirportByIcao(_ icaoCode: String) throws -> [Airport] {
        let code = icaoCode.uppercased().trimmingCharacters(in: .whitespaces)
        guard let airports = store.icaoIndex[code], !airports.isEmpty else {
            throw AirportDataError.noDataFound("No data found for ICAO code: \(icaoCode)")
        }
        return airports
    }

    /// Searches for airports by name (case-insensitive, minimum 2 characters).
    /// - Parameter query: The search query.
    /// - Returns: An array of airports whose names contain the query string.
    /// - Throws: `AirportDataError.invalidInput` if the query is less than 2 characters.
    public static func searchByName(_ query: String) throws -> [Airport] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            throw AirportDataError.invalidInput("Search query must be at least 2 characters")
        }
        let lowered = trimmed.lowercased()
        return store.airports.filter { $0.airport.lowercased().contains(lowered) }
    }

    // MARK: - Geographic Functions

    /// Finds airports within a specified radius of given coordinates.
    /// - Parameters:
    ///   - latitude: Latitude of the reference point.
    ///   - longitude: Longitude of the reference point.
    ///   - radiusKm: Radius in kilometers.
    /// - Returns: An array of `AirportWithDistance` sorted by distance.
    public static func findNearbyAirports(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) -> [AirportWithDistance] {
        var results: [AirportWithDistance] = []
        for airport in store.airports {
            let dist = haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: airport.latitude, lon2: airport.longitude
            )
            if dist <= radiusKm {
                results.append(AirportWithDistance(airport: airport, distance: dist))
            }
        }
        return results.sorted { $0.distance < $1.distance }
    }

    /// Calculates the great-circle distance between two airports.
    /// - Parameters:
    ///   - code1: IATA or ICAO code of the first airport.
    ///   - code2: IATA or ICAO code of the second airport.
    /// - Returns: Distance in kilometers.
    /// - Throws: `AirportDataError.noDataFound` if either airport is not found.
    public static func calculateDistance(_ code1: String, _ code2: String) throws -> Double {
        let airport1 = try resolveAirport(code1)
        let airport2 = try resolveAirport(code2)
        return haversineDistance(
            lat1: airport1.latitude, lon1: airport1.longitude,
            lat2: airport2.latitude, lon2: airport2.longitude
        )
    }

    /// Finds the single nearest airport to given coordinates.
    /// - Parameters:
    ///   - latitude: Latitude of the reference point.
    ///   - longitude: Longitude of the reference point.
    ///   - filter: Optional filters to narrow the search.
    /// - Returns: The nearest airport with distance information, or `nil` if none match the filter.
    public static func findNearestAirport(
        latitude: Double,
        longitude: Double,
        filter: NearestAirportFilter? = nil
    ) -> AirportWithDistance? {
        var bestDistance = Double.greatestFiniteMagnitude
        var bestAirport: Airport?

        for airport in store.airports {
            if let f = filter {
                if let t = f.type, airport.type.lowercased() != t.lowercased() { continue }
                if let cc = f.countryCode, airport.countryCode.uppercased() != cc.uppercased() { continue }
                if let hs = f.hasScheduledService, airport.scheduledService != hs { continue }
            }
            let dist = haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: airport.latitude, lon2: airport.longitude
            )
            if dist < bestDistance {
                bestDistance = dist
                bestAirport = airport
            }
        }
        guard let found = bestAirport else { return nil }
        return AirportWithDistance(airport: found, distance: bestDistance)
    }

    // MARK: - Filtering Functions

    /// Finds all airports in a specific country.
    /// - Parameter countryCode: 2-letter ISO country code (case-insensitive).
    /// - Returns: An array of airports in the country.
    /// - Throws: `AirportDataError.noDataFound` if no airports found.
    public static func getAirportByCountryCode(_ countryCode: String) throws -> [Airport] {
        let code = countryCode.uppercased().trimmingCharacters(in: .whitespaces)
        let results = store.airports.filter { $0.countryCode.uppercased() == code }
        guard !results.isEmpty else {
            throw AirportDataError.noDataFound("No data found for country code: \(countryCode)")
        }
        return results
    }

    /// Finds all airports on a specific continent.
    /// - Parameter continentCode: 2-letter continent code (AS, EU, NA, SA, AF, OC, AN).
    /// - Returns: An array of airports on the continent.
    /// - Throws: `AirportDataError.noDataFound` if no airports found.
    public static func getAirportByContinent(_ continentCode: String) throws -> [Airport] {
        let code = continentCode.uppercased().trimmingCharacters(in: .whitespaces)
        let results = store.airports.filter { $0.continent.uppercased() == code }
        guard !results.isEmpty else {
            throw AirportDataError.noDataFound("No data found for continent code: \(continentCode)")
        }
        return results
    }

    /// Finds airports by their type.
    /// - Parameter type: Airport type (large_airport, medium_airport, small_airport, heliport, seaplane_base).
    ///   Use "airport" to match all airport types (large, medium, small).
    /// - Returns: An array of matching airports.
    public static func getAirportsByType(_ type: String) -> [Airport] {
        let lowered = type.lowercased().trimmingCharacters(in: .whitespaces)
        if lowered == "airport" {
            return store.airports.filter {
                let t = $0.type.lowercased()
                return t.contains("airport")
            }
        }
        return store.airports.filter { $0.type.lowercased() == lowered }
    }

    /// Finds all airports within a specific timezone.
    /// - Parameter timezone: Timezone identifier (e.g. "Europe/London").
    /// - Returns: An array of airports in the timezone.
    /// - Throws: `AirportDataError.noDataFound` if no airports found.
    public static func getAirportsByTimezone(_ timezone: String) throws -> [Airport] {
        let results = store.airports.filter { $0.time == timezone }
        guard !results.isEmpty else {
            throw AirportDataError.noDataFound("No data found for timezone: \(timezone)")
        }
        return results
    }

    // MARK: - Advanced Functions

    /// Finds airports matching multiple criteria.
    /// - Parameter filter: An `AirportFilter` with the criteria to match.
    /// - Returns: An array of matching airports.
    public static func findAirports(_ filter: AirportFilter) -> [Airport] {
        return store.airports.filter { airport in
            if let cc = filter.countryCode {
                guard airport.countryCode.uppercased() == cc.uppercased() else { return false }
            }
            if let cont = filter.continent {
                guard airport.continent.uppercased() == cont.uppercased() else { return false }
            }
            if let t = filter.type {
                let loweredFilter = t.lowercased()
                let loweredType = airport.type.lowercased()
                if loweredFilter == "airport" {
                    guard loweredType.contains("airport") else { return false }
                } else {
                    guard loweredType == loweredFilter else { return false }
                }
            }
            if let hs = filter.hasScheduledService {
                guard airport.scheduledService == hs else { return false }
            }
            if let minRunway = filter.minRunwayFt {
                guard let runway = airport.runwayLength, runway >= minRunway else { return false }
            }
            return true
        }
    }

    /// Provides autocomplete suggestions for search interfaces (returns max 10 results).
    /// - Parameter query: The search query (minimum 1 character).
    /// - Returns: Up to 10 airports matching by name or IATA code.
    public static func getAutocompleteSuggestions(_ query: String) -> [Airport] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let lowered = trimmed.lowercased()
        var results: [Airport] = []
        for airport in store.airports {
            if airport.airport.lowercased().contains(lowered) ||
               airport.iata.lowercased().contains(lowered) {
                results.append(airport)
                if results.count >= 10 { break }
            }
        }
        return results
    }

    /// Gets external links for an airport.
    /// - Parameter code: IATA or ICAO code.
    /// - Returns: An `AirportLinks` struct with available external links.
    /// - Throws: `AirportDataError.noDataFound` if the airport is not found.
    public static func getAirportLinks(_ code: String) throws -> AirportLinks {
        let airport = try resolveAirport(code)
        return AirportLinks(
            website: airport.website.isEmpty ? nil : airport.website,
            wikipedia: airport.wikipedia.isEmpty ? nil : airport.wikipedia,
            flightradar24: airport.flightradar24Url.isEmpty ? nil : airport.flightradar24Url,
            radarbox: airport.radarboxUrl.isEmpty ? nil : airport.radarboxUrl,
            flightaware: airport.flightawareUrl.isEmpty ? nil : airport.flightawareUrl
        )
    }

    // MARK: - Statistical & Analytical Functions

    /// Gets comprehensive statistics about airports in a specific country.
    /// - Parameter countryCode: 2-letter ISO country code.
    /// - Returns: An `AirportCountryStats` with comprehensive statistics.
    /// - Throws: `AirportDataError.noDataFound` if no airports found for the country.
    public static func getAirportStatsByCountry(_ countryCode: String) throws -> AirportCountryStats {
        let airports = try getAirportByCountryCode(countryCode)
        return buildCountryStats(airports)
    }

    /// Gets comprehensive statistics about airports on a specific continent.
    /// - Parameter continentCode: 2-letter continent code.
    /// - Returns: An `AirportContinentStats` with comprehensive statistics.
    /// - Throws: `AirportDataError.noDataFound` if no airports found for the continent.
    public static func getAirportStatsByContinent(_ continentCode: String) throws -> AirportContinentStats {
        let airports = try getAirportByContinent(continentCode)
        return buildContinentStats(airports)
    }

    /// Gets the largest airports on a continent by runway length or elevation.
    /// - Parameters:
    ///   - continentCode: 2-letter continent code.
    ///   - limit: Maximum number of results (default 10).
    ///   - sortBy: Sort criterion - "runway" (default) or "elevation".
    /// - Returns: An array of airports sorted by the specified criterion.
    /// - Throws: `AirportDataError.noDataFound` if no airports found.
    public static func getLargestAirportsByContinent(
        _ continentCode: String,
        limit: Int = 10,
        sortBy: String = "runway"
    ) throws -> [Airport] {
        let airports = try getAirportByContinent(continentCode)

        let sorted: [Airport]
        if sortBy.lowercased() == "elevation" {
            sorted = airports.sorted { ($0.elevationFt ?? 0) > ($1.elevationFt ?? 0) }
        } else {
            sorted = airports.sorted { ($0.runwayLength ?? 0) > ($1.runwayLength ?? 0) }
        }

        return Array(sorted.prefix(limit))
    }

    // MARK: - Bulk Operations

    /// Fetches multiple airports by their IATA or ICAO codes in one call.
    /// - Parameter codes: An array of IATA or ICAO codes.
    /// - Returns: An array of `Airport?` in the same order as the input codes.
    ///   Returns `nil` for codes that are not found.
    public static func getMultipleAirports(_ codes: [String]) -> [Airport?] {
        return codes.map { code in
            let upper = code.uppercased().trimmingCharacters(in: .whitespaces)
            if let airports = store.iataIndex[upper], let first = airports.first {
                return first
            }
            if let airports = store.icaoIndex[upper], let first = airports.first {
                return first
            }
            return nil
        }
    }

    /// Calculates distances between all pairs of airports in a list.
    /// - Parameter codes: An array of IATA or ICAO codes (minimum 2).
    /// - Returns: A `DistanceMatrix` with airport info and pairwise distances.
    /// - Throws: `AirportDataError.invalidInput` if fewer than 2 codes are provided.
    ///   `AirportDataError.noDataFound` if any code is not found.
    public static func calculateDistanceMatrix(_ codes: [String]) throws -> DistanceMatrix {
        guard codes.count >= 2 else {
            throw AirportDataError.invalidInput("At least 2 airport codes are required for distance matrix")
        }

        var resolvedAirports: [(code: String, airport: Airport)] = []
        for code in codes {
            let airport = try resolveAirport(code)
            resolvedAirports.append((code: code.uppercased(), airport: airport))
        }

        let airportInfos = resolvedAirports.map { item in
            DistanceMatrix.AirportInfo(
                code: item.code,
                name: item.airport.airport,
                iata: item.airport.iata,
                icao: item.airport.icao
            )
        }

        var distances = [String: [String: Double]]()
        for i in 0..<resolvedAirports.count {
            let codeI = resolvedAirports[i].code
            var row = [String: Double]()
            for j in 0..<resolvedAirports.count {
                let codeJ = resolvedAirports[j].code
                if i == j {
                    row[codeJ] = 0
                } else {
                    let dist = haversineDistance(
                        lat1: resolvedAirports[i].airport.latitude,
                        lon1: resolvedAirports[i].airport.longitude,
                        lat2: resolvedAirports[j].airport.latitude,
                        lon2: resolvedAirports[j].airport.longitude
                    )
                    row[codeJ] = round(dist)
                }
            }
            distances[codeI] = row
        }

        return DistanceMatrix(airports: airportInfos, distances: distances)
    }

    // MARK: - Validation & Utilities

    /// Validates if an IATA code exists in the database.
    /// - Parameter code: The IATA code to validate.
    /// - Returns: `true` if the code is a valid 3-letter uppercase IATA code that exists in the database.
    public static func validateIataCode(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 3 else { return false }
        // Must be all uppercase letters
        guard trimmed == trimmed.uppercased(),
              trimmed.allSatisfy({ $0.isUppercase && $0.isASCII }) else {
            return false
        }
        return store.iataIndex[trimmed] != nil
    }

    /// Validates if an ICAO code exists in the database.
    /// - Parameter code: The ICAO code to validate.
    /// - Returns: `true` if the code is a valid 4-character uppercase ICAO code that exists in the database.
    public static func validateIcaoCode(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 4 else { return false }
        // Must be all uppercase alphanumeric
        guard trimmed == trimmed.uppercased(),
              trimmed.allSatisfy({ ($0.isUppercase || $0.isNumber) && $0.isASCII }) else {
            return false
        }
        return store.icaoIndex[trimmed] != nil
    }

    /// Gets the count of airports matching the given filters without fetching all data.
    /// - Parameter filter: Optional `AirportFilter`. If `nil`, returns total count.
    /// - Returns: The number of matching airports.
    public static func getAirportCount(_ filter: AirportFilter? = nil) -> Int {
        guard let f = filter else {
            return store.airports.count
        }
        return findAirports(f).count
    }

    /// Checks if an airport has scheduled commercial service.
    /// - Parameter code: IATA or ICAO code.
    /// - Returns: `true` if the airport has scheduled service.
    /// - Throws: `AirportDataError.noDataFound` if the airport is not found.
    public static func isAirportOperational(_ code: String) throws -> Bool {
        let airport = try resolveAirport(code)
        return airport.scheduledService
    }

    // MARK: - Internal Helpers

    /// Resolves an airport by IATA or ICAO code.
    private static func resolveAirport(_ code: String) throws -> Airport {
        let upper = code.uppercased().trimmingCharacters(in: .whitespaces)
        if let airports = store.iataIndex[upper], let first = airports.first {
            return first
        }
        if let airports = store.icaoIndex[upper], let first = airports.first {
            return first
        }
        throw AirportDataError.noDataFound("No data found for airport code: \(code)")
    }

    /// Calculates the great-circle distance between two points using the Haversine formula.
    /// - Returns: Distance in kilometers.
    private static func haversineDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let earthRadiusKm = 6371.0
        let dLat = degreesToRadians(lat2 - lat1)
        let dLon = degreesToRadians(lon2 - lon1)

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(degreesToRadians(lat1)) * cos(degreesToRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusKm * c
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }

    private static func buildCountryStats(_ airports: [Airport]) -> AirportCountryStats {
        var byType = [String: Int]()
        var scheduledCount = 0
        var runwaySum = 0.0
        var runwayCount = 0
        var elevSum = 0.0
        var elevCount = 0
        var timezoneSet = Set<String>()

        for airport in airports {
            byType[airport.type, default: 0] += 1
            if airport.scheduledService { scheduledCount += 1 }
            if let rl = airport.runwayLength {
                runwaySum += Double(rl)
                runwayCount += 1
            }
            if let el = airport.elevationFt {
                elevSum += Double(el)
                elevCount += 1
            }
            if !airport.time.isEmpty {
                timezoneSet.insert(airport.time)
            }
        }

        return AirportCountryStats(
            total: airports.count,
            byType: byType,
            withScheduledService: scheduledCount,
            averageRunwayLength: runwayCount > 0 ? runwaySum / Double(runwayCount) : 0,
            averageElevation: elevCount > 0 ? elevSum / Double(elevCount) : 0,
            timezones: timezoneSet.sorted()
        )
    }

    private static func buildContinentStats(_ airports: [Airport]) -> AirportContinentStats {
        var byType = [String: Int]()
        var byCountry = [String: Int]()
        var scheduledCount = 0
        var runwaySum = 0.0
        var runwayCount = 0
        var elevSum = 0.0
        var elevCount = 0
        var timezoneSet = Set<String>()

        for airport in airports {
            byType[airport.type, default: 0] += 1
            byCountry[airport.countryCode, default: 0] += 1
            if airport.scheduledService { scheduledCount += 1 }
            if let rl = airport.runwayLength {
                runwaySum += Double(rl)
                runwayCount += 1
            }
            if let el = airport.elevationFt {
                elevSum += Double(el)
                elevCount += 1
            }
            if !airport.time.isEmpty {
                timezoneSet.insert(airport.time)
            }
        }

        return AirportContinentStats(
            total: airports.count,
            byType: byType,
            byCountry: byCountry,
            withScheduledService: scheduledCount,
            averageRunwayLength: runwayCount > 0 ? runwaySum / Double(runwayCount) : 0,
            averageElevation: elevCount > 0 ? elevSum / Double(elevCount) : 0,
            timezones: timezoneSet.sorted()
        )
    }
}
