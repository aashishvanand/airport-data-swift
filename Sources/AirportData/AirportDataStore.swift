import Foundation

/// Internal data store that lazily loads and caches airport data with indexed lookups.
final class AirportDataStore: @unchecked Sendable {
    static let shared = AirportDataStore()

    private var _airports: [Airport]?
    private var _iataIndex: [String: [Airport]]?
    private var _icaoIndex: [String: [Airport]]?
    private let lock = NSLock()

    private init() {}

    /// All airports in the database.
    var airports: [Airport] {
        lock.lock()
        defer { lock.unlock() }
        if let cached = _airports {
            return cached
        }
        let loaded = Self.loadAirports()
        _airports = loaded
        buildIndexes(from: loaded)
        return loaded
    }

    /// Index of airports by uppercase IATA code.
    var iataIndex: [String: [Airport]] {
        lock.lock()
        defer { lock.unlock() }
        if let cached = _iataIndex {
            return cached
        }
        // Force load which also builds indexes
        lock.unlock()
        _ = airports
        lock.lock()
        return _iataIndex ?? [:]
    }

    /// Index of airports by uppercase ICAO code.
    var icaoIndex: [String: [Airport]] {
        lock.lock()
        defer { lock.unlock() }
        if let cached = _icaoIndex {
            return cached
        }
        lock.unlock()
        _ = airports
        lock.lock()
        return _icaoIndex ?? [:]
    }

    /// Builds IATA and ICAO indexes in one pass. Must be called with lock held.
    private func buildIndexes(from airports: [Airport]) {
        var iata = [String: [Airport]]()
        iata.reserveCapacity(airports.count)
        var icao = [String: [Airport]]()
        icao.reserveCapacity(airports.count)
        for airport in airports {
            if !airport.iata.isEmpty {
                let key = airport.iata.uppercased()
                iata[key, default: []].append(airport)
            }
            if !airport.icao.isEmpty {
                let key = airport.icao.uppercased()
                icao[key, default: []].append(airport)
            }
        }
        _iataIndex = iata
        _icaoIndex = icao
    }

    /// Loads airports using JSONSerialization (fast ObjC-based parser) instead of JSONDecoder.
    private static func loadAirports() -> [Airport] {
        guard let url = Bundle.module.url(forResource: "airports", withExtension: "json") else {
            fatalError("AirportData: airports.json not found in bundle resources")
        }
        do {
            let data = try Data(contentsOf: url)
            let jsonArray = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]

            var airports = [Airport]()
            airports.reserveCapacity(jsonArray.count)

            for dict in jsonArray {
                let airport = Airport(
                    iata: dict["iata"] as? String ?? "",
                    icao: dict["icao"] as? String ?? "",
                    time: dict["time"] as? String ?? "",
                    utc: (dict["utc"] as? NSNumber)?.doubleValue ?? 0,
                    countryCode: dict["country_code"] as? String ?? "",
                    continent: dict["continent"] as? String ?? "",
                    airport: dict["airport"] as? String ?? "",
                    latitude: (dict["latitude"] as? NSNumber)?.doubleValue ?? 0,
                    longitude: (dict["longitude"] as? NSNumber)?.doubleValue ?? 0,
                    elevationFt: (dict["elevation_ft"] as? NSNumber)?.intValue,
                    type: dict["type"] as? String ?? "",
                    scheduledService: dict["scheduled_service"] as? Bool ?? false,
                    wikipedia: dict["wikipedia"] as? String ?? "",
                    website: dict["website"] as? String ?? "",
                    runwayLength: (dict["runway_length"] as? NSNumber)?.intValue,
                    flightradar24Url: dict["flightradar24_url"] as? String ?? "",
                    radarboxUrl: dict["radarbox_url"] as? String ?? "",
                    flightawareUrl: dict["flightaware_url"] as? String ?? ""
                )
                airports.append(airport)
            }

            return airports
        } catch {
            fatalError("AirportData: Failed to load airports.json: \(error)")
        }
    }
}
