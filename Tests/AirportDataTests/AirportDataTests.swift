import XCTest
@testable import AirportData

final class AirportDataTests: XCTestCase {

    // MARK: - getAirportByIata

    func testGetAirportByIataValid() throws {
        let airports = try AirportData.getAirportByIata("LHR")
        XCTAssertEqual(airports.first?.iata, "LHR")
        XCTAssertTrue(airports.first?.airport.contains("Heathrow") ?? false)
    }

    func testGetAirportByIataInvalid() {
        XCTAssertThrowsError(try AirportData.getAirportByIata("XYZ")) { error in
            XCTAssertTrue(error.localizedDescription.contains("No data found"))
        }
    }

    // MARK: - getAirportByIcao

    func testGetAirportByIcaoValid() throws {
        let airports = try AirportData.getAirportByIcao("EGLL")
        XCTAssertEqual(airports.first?.icao, "EGLL")
        XCTAssertTrue(airports.first?.airport.contains("Heathrow") ?? false)
    }

    func testGetAirportByIcaoInvalid() {
        XCTAssertThrowsError(try AirportData.getAirportByIcao("XXXX")) { error in
            XCTAssertTrue(error.localizedDescription.contains("No data found"))
        }
    }

    // MARK: - getAirportByCountryCode

    func testGetAirportByCountryCode() throws {
        let airports = try AirportData.getAirportByCountryCode("US")
        XCTAssertGreaterThan(airports.count, 100)
        XCTAssertEqual(airports.first?.countryCode, "US")
    }

    // MARK: - getAirportByContinent

    func testGetAirportByContinent() throws {
        let airports = try AirportData.getAirportByContinent("EU")
        XCTAssertGreaterThan(airports.count, 100)
        XCTAssertTrue(airports.allSatisfy { $0.continent == "EU" })
    }

    // MARK: - findNearbyAirports

    func testFindNearbyAirports() {
        // London coordinates, 50km radius
        let nearby = AirportData.findNearbyAirports(latitude: 51.5074, longitude: -0.1278, radiusKm: 50)
        XCTAssertGreaterThanOrEqual(nearby.count, 1)
        XCTAssertTrue(nearby.contains { $0.airport.iata == "LHR" })
    }

    // MARK: - getAirportsByType

    func testGetAirportsByTypeLarge() {
        let airports = AirportData.getAirportsByType("large_airport")
        XCTAssertGreaterThan(airports.count, 10)
        XCTAssertTrue(airports.allSatisfy { $0.type == "large_airport" })
    }

    func testGetAirportsByTypeMedium() {
        let airports = AirportData.getAirportsByType("medium_airport")
        XCTAssertGreaterThan(airports.count, 10)
        XCTAssertTrue(airports.allSatisfy { $0.type == "medium_airport" })
    }

    func testGetAirportsByTypeAirportGeneric() {
        let airports = AirportData.getAirportsByType("airport")
        XCTAssertGreaterThan(airports.count, 50)
        XCTAssertTrue(airports.allSatisfy { $0.type.contains("airport") })
    }

    func testGetAirportsByTypeHeliport() {
        let heliports = AirportData.getAirportsByType("heliport")
        XCTAssertTrue(heliports is [Airport])
        if !heliports.isEmpty {
            XCTAssertTrue(heliports.allSatisfy { $0.type == "heliport" })
        }
    }

    func testGetAirportsByTypeSeaplaneBase() {
        let seaplaneBases = AirportData.getAirportsByType("seaplane_base")
        XCTAssertTrue(seaplaneBases is [Airport])
        if !seaplaneBases.isEmpty {
            XCTAssertTrue(seaplaneBases.allSatisfy { $0.type == "seaplane_base" })
        }
    }

    func testGetAirportsByTypeCaseInsensitive() {
        let upperCase = AirportData.getAirportsByType("LARGE_AIRPORT")
        let lowerCase = AirportData.getAirportsByType("large_airport")
        XCTAssertEqual(upperCase.count, lowerCase.count)
        XCTAssertGreaterThan(upperCase.count, 0)
    }

    func testGetAirportsByTypeNonExistent() {
        let airports = AirportData.getAirportsByType("nonexistent_type")
        XCTAssertEqual(airports.count, 0)
    }

    // MARK: - getAutocompleteSuggestions

    func testGetAutocompleteSuggestions() {
        let suggestions = AirportData.getAutocompleteSuggestions("London")
        XCTAssertGreaterThan(suggestions.count, 0)
        XCTAssertLessThanOrEqual(suggestions.count, 10)
        XCTAssertTrue(suggestions.contains { $0.iata == "LHR" })
    }

    // MARK: - calculateDistance

    func testCalculateDistance() throws {
        let distance = try AirportData.calculateDistance("LHR", "JFK")
        XCTAssertEqual(distance, 5541, accuracy: 50)
    }

    // MARK: - findAirports (Advanced Filtering)

    func testFindAirportsMultipleCriteria() {
        let airports = AirportData.findAirports(AirportFilter(countryCode: "GB", type: "airport"))
        XCTAssertGreaterThanOrEqual(airports.count, 0)
        XCTAssertTrue(airports.allSatisfy {
            $0.countryCode == "GB" && $0.type.lowercased().contains("airport")
        })
    }

    func testFindAirportsScheduledService() {
        let withService = AirportData.findAirports(AirportFilter(hasScheduledService: true))
        let withoutService = AirportData.findAirports(AirportFilter(hasScheduledService: false))

        XCTAssertGreaterThan(withService.count + withoutService.count, 0)

        if !withService.isEmpty {
            XCTAssertTrue(withService.allSatisfy { $0.scheduledService == true })
        }

        if !withoutService.isEmpty {
            XCTAssertTrue(withoutService.allSatisfy { $0.scheduledService == false })
        }
    }

    // MARK: - getAirportsByTimezone

    func testGetAirportsByTimezone() throws {
        let airports = try AirportData.getAirportsByTimezone("Europe/London")
        XCTAssertGreaterThan(airports.count, 10)
        XCTAssertTrue(airports.allSatisfy { $0.time == "Europe/London" })
    }

    // MARK: - getAirportLinks

    func testGetAirportLinksLHR() throws {
        let links = try AirportData.getAirportLinks("LHR")
        XCTAssertNotNil(links.wikipedia)
        XCTAssertTrue(links.wikipedia?.contains("Heathrow_Airport") ?? false)
        XCTAssertNotNil(links.website)
    }

    func testGetAirportLinksHND() throws {
        let links = try AirportData.getAirportLinks("HND")
        XCTAssertNotNil(links.wikipedia)
        XCTAssertTrue(links.wikipedia?.contains("Tokyo_International_Airport") ?? false)
        XCTAssertNotNil(links.website)
    }

    // MARK: - getAirportStatsByCountry

    func testGetAirportStatsByCountrySG() throws {
        let stats = try AirportData.getAirportStatsByCountry("SG")
        XCTAssertGreaterThan(stats.total, 0)
        XCTAssertFalse(stats.byType.isEmpty)
        XCTAssertGreaterThanOrEqual(stats.withScheduledService, 0)
        XCTAssertTrue(stats.timezones is [String])
    }

    func testGetAirportStatsByCountryUS() throws {
        let stats = try AirportData.getAirportStatsByCountry("US")
        XCTAssertGreaterThan(stats.total, 1000)
        XCTAssertNotNil(stats.byType["large_airport"])
        XCTAssertGreaterThan(stats.byType["large_airport"] ?? 0, 0)
    }

    func testGetAirportStatsByCountryInvalid() {
        XCTAssertThrowsError(try AirportData.getAirportStatsByCountry("XYZ"))
    }

    // MARK: - getAirportStatsByContinent

    func testGetAirportStatsByContinentAS() throws {
        let stats = try AirportData.getAirportStatsByContinent("AS")
        XCTAssertGreaterThan(stats.total, 100)
        XCTAssertFalse(stats.byType.isEmpty)
        XCTAssertFalse(stats.byCountry.isEmpty)
        XCTAssertGreaterThan(stats.byCountry.count, 10)
    }

    func testGetAirportStatsByContinentEU() throws {
        let stats = try AirportData.getAirportStatsByContinent("EU")
        XCTAssertNotNil(stats.byCountry["GB"])
        XCTAssertNotNil(stats.byCountry["FR"])
        XCTAssertNotNil(stats.byCountry["DE"])
    }

    // MARK: - getLargestAirportsByContinent

    func testGetLargestAirportsByContinentByRunway() throws {
        let airports = try AirportData.getLargestAirportsByContinent("AS", limit: 5, sortBy: "runway")
        XCTAssertLessThanOrEqual(airports.count, 5)
        XCTAssertGreaterThan(airports.count, 0)
        // Check sorted by runway length descending
        for i in 0..<(airports.count - 1) {
            let runway1 = airports[i].runwayLength ?? 0
            let runway2 = airports[i + 1].runwayLength ?? 0
            XCTAssertGreaterThanOrEqual(runway1, runway2)
        }
    }

    func testGetLargestAirportsByContinentByElevation() throws {
        let airports = try AirportData.getLargestAirportsByContinent("SA", limit: 5, sortBy: "elevation")
        XCTAssertLessThanOrEqual(airports.count, 5)
        // Check sorted by elevation descending
        for i in 0..<(airports.count - 1) {
            let elev1 = airports[i].elevationFt ?? 0
            let elev2 = airports[i + 1].elevationFt ?? 0
            XCTAssertGreaterThanOrEqual(elev1, elev2)
        }
    }

    func testGetLargestAirportsByContinentLimit() throws {
        let airports = try AirportData.getLargestAirportsByContinent("EU", limit: 3)
        XCTAssertLessThanOrEqual(airports.count, 3)
    }

    // MARK: - getMultipleAirports

    func testGetMultipleAirportsByIata() {
        let airports = AirportData.getMultipleAirports(["SIN", "LHR", "JFK"])
        XCTAssertEqual(airports.count, 3)
        XCTAssertEqual(airports[0]?.iata, "SIN")
        XCTAssertEqual(airports[1]?.iata, "LHR")
        XCTAssertEqual(airports[2]?.iata, "JFK")
    }

    func testGetMultipleAirportsMixed() {
        let airports = AirportData.getMultipleAirports(["SIN", "EGLL", "JFK"])
        XCTAssertEqual(airports.count, 3)
        XCTAssertTrue(airports.allSatisfy { $0 != nil })
    }

    func testGetMultipleAirportsInvalidCode() {
        let airports = AirportData.getMultipleAirports(["SIN", "INVALID", "LHR"])
        XCTAssertEqual(airports.count, 3)
        XCTAssertNotNil(airports[0])
        XCTAssertNil(airports[1])
        XCTAssertNotNil(airports[2])
    }

    func testGetMultipleAirportsEmpty() {
        let airports = AirportData.getMultipleAirports([])
        XCTAssertEqual(airports.count, 0)
    }

    // MARK: - calculateDistanceMatrix

    func testCalculateDistanceMatrix() throws {
        let matrix = try AirportData.calculateDistanceMatrix(["SIN", "LHR", "JFK"])
        XCTAssertEqual(matrix.airports.count, 3)

        // Check diagonal is zero
        XCTAssertEqual(matrix.distances["SIN"]?["SIN"], 0)
        XCTAssertEqual(matrix.distances["LHR"]?["LHR"], 0)
        XCTAssertEqual(matrix.distances["JFK"]?["JFK"], 0)

        // Check symmetry
        XCTAssertEqual(matrix.distances["SIN"]?["LHR"], matrix.distances["LHR"]?["SIN"])
        XCTAssertEqual(matrix.distances["SIN"]?["JFK"], matrix.distances["JFK"]?["SIN"])

        // Check reasonable distances
        XCTAssertGreaterThan(matrix.distances["SIN"]?["LHR"] ?? 0, 5000)
        XCTAssertGreaterThan(matrix.distances["LHR"]?["JFK"] ?? 0, 3000)
    }

    func testCalculateDistanceMatrixTooFew() {
        XCTAssertThrowsError(try AirportData.calculateDistanceMatrix(["SIN"]))
    }

    func testCalculateDistanceMatrixInvalidCode() {
        XCTAssertThrowsError(try AirportData.calculateDistanceMatrix(["SIN", "INVALID"]))
    }

    // MARK: - findNearestAirport

    func testFindNearestAirport() {
        let nearest = AirportData.findNearestAirport(latitude: 1.35019, longitude: 103.994003)
        XCTAssertNotNil(nearest)
        XCTAssertEqual(nearest?.airport.iata, "SIN")
        XCTAssertLessThan(nearest?.distance ?? Double.greatestFiniteMagnitude, 2)
    }

    func testFindNearestAirportWithTypeFilter() {
        let nearest = AirportData.findNearestAirport(
            latitude: 51.5074, longitude: -0.1278,
            filter: NearestAirportFilter(type: "large_airport")
        )
        XCTAssertNotNil(nearest)
        XCTAssertEqual(nearest?.airport.type, "large_airport")
        XCTAssertNotNil(nearest?.distance)
    }

    func testFindNearestAirportWithTypeAndCountryFilter() {
        let nearest = AirportData.findNearestAirport(
            latitude: 40.7128, longitude: -74.0060,
            filter: NearestAirportFilter(type: "large_airport", countryCode: "US")
        )
        XCTAssertNotNil(nearest)
        XCTAssertNotNil(nearest?.distance)
        XCTAssertEqual(nearest?.airport.type, "large_airport")
        XCTAssertEqual(nearest?.airport.countryCode, "US")
    }

    // MARK: - validateIataCode

    func testValidateIataCodeValid() {
        XCTAssertTrue(AirportData.validateIataCode("SIN"))
        XCTAssertTrue(AirportData.validateIataCode("LHR"))
        XCTAssertTrue(AirportData.validateIataCode("JFK"))
    }

    func testValidateIataCodeInvalid() {
        XCTAssertFalse(AirportData.validateIataCode("XYZ"))
        XCTAssertFalse(AirportData.validateIataCode("ZZZ"))
    }

    func testValidateIataCodeBadFormat() {
        XCTAssertFalse(AirportData.validateIataCode("ABCD"))
        XCTAssertFalse(AirportData.validateIataCode("AB"))
        XCTAssertFalse(AirportData.validateIataCode("abc"))
        XCTAssertFalse(AirportData.validateIataCode(""))
    }

    // MARK: - validateIcaoCode

    func testValidateIcaoCodeValid() {
        XCTAssertTrue(AirportData.validateIcaoCode("WSSS"))
        XCTAssertTrue(AirportData.validateIcaoCode("EGLL"))
        XCTAssertTrue(AirportData.validateIcaoCode("KJFK"))
    }

    func testValidateIcaoCodeInvalid() {
        XCTAssertFalse(AirportData.validateIcaoCode("XXXX"))
        XCTAssertFalse(AirportData.validateIcaoCode("ZZZ0"))
    }

    func testValidateIcaoCodeBadFormat() {
        XCTAssertFalse(AirportData.validateIcaoCode("ABC"))
        XCTAssertFalse(AirportData.validateIcaoCode("ABCDE"))
        XCTAssertFalse(AirportData.validateIcaoCode("abcd"))
        XCTAssertFalse(AirportData.validateIcaoCode(""))
    }

    // MARK: - getAirportCount

    func testGetAirportCountTotal() {
        let count = AirportData.getAirportCount()
        XCTAssertGreaterThan(count, 5000)
    }

    func testGetAirportCountByType() {
        let largeCount = AirportData.getAirportCount(AirportFilter(type: "large_airport"))
        let totalCount = AirportData.getAirportCount()
        XCTAssertGreaterThan(largeCount, 0)
        XCTAssertLessThan(largeCount, totalCount)
    }

    func testGetAirportCountByCountry() {
        let usCount = AirportData.getAirportCount(AirportFilter(countryCode: "US"))
        XCTAssertGreaterThan(usCount, 1000)
    }

    func testGetAirportCountMultipleFilters() {
        let count = AirportData.getAirportCount(AirportFilter(countryCode: "US", type: "large_airport"))
        XCTAssertGreaterThan(count, 0)
        XCTAssertLessThan(count, 200)
    }

    // MARK: - isAirportOperational

    func testIsAirportOperationalTrue() throws {
        XCTAssertTrue(try AirportData.isAirportOperational("SIN"))
        XCTAssertTrue(try AirportData.isAirportOperational("LHR"))
        XCTAssertTrue(try AirportData.isAirportOperational("JFK"))
    }

    func testIsAirportOperationalByIcao() throws {
        XCTAssertTrue(try AirportData.isAirportOperational("SIN"))
        XCTAssertTrue(try AirportData.isAirportOperational("WSSS"))
    }

    func testIsAirportOperationalInvalid() {
        XCTAssertThrowsError(try AirportData.isAirportOperational("INVALID"))
    }

    // MARK: - searchByName

    func testSearchByName() throws {
        let airports = try AirportData.searchByName("Singapore")
        XCTAssertGreaterThan(airports.count, 0)
    }

    func testSearchByNameMinChars() {
        XCTAssertThrowsError(try AirportData.searchByName("S"))
    }
}
