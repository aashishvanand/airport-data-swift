# Airport Data Swift

A comprehensive Swift library for retrieving airport information by IATA codes, ICAO codes, and various other criteria. This library provides easy access to a large dataset of airports worldwide with detailed information including coordinates, timezone, type, and external links.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/aashishvanand/airport-data-swift.git", from: "1.0.0")
]
```

Then add `AirportData` to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["AirportData"]
)
```

Or in Xcode: **File > Add Package Dependencies** and enter:
```
https://github.com/aashishvanand/airport-data-swift.git
```

## Features

- Comprehensive airport database with worldwide coverage (18,000+ airports)
- Search by IATA codes, ICAO codes, country, continent, and more
- Geographic proximity search with customizable radius
- External links to Wikipedia, airport websites, and flight tracking services
- Distance calculation between airports using the Haversine formula
- Filter by airport type (large_airport, medium_airport, small_airport, heliport, seaplane_base)
- Timezone-based airport lookup
- Autocomplete suggestions for search interfaces
- Advanced multi-criteria filtering
- Statistical analysis by country and continent
- Bulk operations for multiple airports
- Code validation utilities
- Airport ranking by runway length and elevation
- Thread-safe with lazy loading and in-memory caching
- Zero external dependencies
- Supports iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+

## Airport Data Structure

Each `Airport` struct contains the following properties:

```swift
public struct Airport {
    let iata: String              // 3-letter IATA code
    let icao: String              // 4-letter ICAO code
    let time: String              // Timezone identifier (e.g. "Asia/Singapore")
    let utc: Double               // UTC offset in hours
    let countryCode: String       // 2-letter ISO country code
    let continent: String         // 2-letter continent code (AS, EU, NA, SA, AF, OC, AN)
    let airport: String           // Airport name
    let latitude: Double          // Latitude coordinate
    let longitude: Double         // Longitude coordinate
    let elevationFt: Int?         // Elevation in feet
    let type: String              // Airport type
    let scheduledService: Bool    // Has scheduled commercial service
    let wikipedia: String         // Wikipedia URL
    let website: String           // Airport website URL
    let runwayLength: Int?        // Longest runway in feet
    let flightradar24Url: String  // Flightradar24 tracking URL
    let radarboxUrl: String       // RadarBox tracking URL
    let flightawareUrl: String    // FlightAware tracking URL
}
```

## Basic Usage

```swift
import AirportData

// Get airport by IATA code
let airports = try AirportData.getAirportByIata("SIN")
print(airports.first!.airport) // "Singapore Changi Airport"

// Get airport by ICAO code
let airports = try AirportData.getAirportByIcao("WSSS")
print(airports.first!.countryCode) // "SG"

// Search airports by name
let airports = try AirportData.searchByName("Singapore")
print(airports.count) // Multiple airports matching "Singapore"

// Find nearby airports (within 50km of coordinates)
let nearby = AirportData.findNearbyAirports(latitude: 1.35019, longitude: 103.994003, radiusKm: 50)
print(nearby) // Airports near Singapore Changi
```

## API Reference

### Core Search Functions

#### `getAirportByIata(_:)`
Finds airports by their 3-letter IATA code.

```swift
let airports = try AirportData.getAirportByIata("LHR")
// Returns array of airports with IATA code 'LHR'
```

#### `getAirportByIcao(_:)`
Finds airports by their 4-character ICAO code.

```swift
let airports = try AirportData.getAirportByIcao("EGLL")
// Returns array of airports with ICAO code 'EGLL'
```

#### `searchByName(_:)`
Searches for airports by name (case-insensitive, minimum 2 characters).

```swift
let airports = try AirportData.searchByName("Heathrow")
// Returns airports with 'Heathrow' in their name
```

### Geographic Functions

#### `findNearbyAirports(latitude:longitude:radiusKm:)`
Finds airports within a specified radius of given coordinates.

```swift
let nearby = AirportData.findNearbyAirports(latitude: 51.5074, longitude: -0.1278, radiusKm: 100)
// Returns airports within 100km of London, sorted by distance
```

#### `calculateDistance(_:_:)`
Calculates the great-circle distance between two airports using IATA or ICAO codes.

```swift
let distance = try AirportData.calculateDistance("LHR", "JFK")
// Returns distance in kilometers (approximately 5540)
```

#### `findNearestAirport(latitude:longitude:filter:)`
Finds the single nearest airport to given coordinates, optionally with filters.

```swift
// Find nearest airport to coordinates
let nearest = AirportData.findNearestAirport(latitude: 1.35019, longitude: 103.994003)

// Find nearest large airport with scheduled service
let nearestHub = AirportData.findNearestAirport(
    latitude: 1.35019,
    longitude: 103.994003,
    filter: NearestAirportFilter(type: "large_airport", hasScheduledService: true)
)
```

### Filtering Functions

#### `getAirportByCountryCode(_:)`
Finds all airports in a specific country.

```swift
let usAirports = try AirportData.getAirportByCountryCode("US")
// Returns all airports in the United States
```

#### `getAirportByContinent(_:)`
Finds all airports on a specific continent.

```swift
let asianAirports = try AirportData.getAirportByContinent("AS")
// Continent codes: AS, EU, NA, SA, AF, OC, AN
```

#### `getAirportsByType(_:)`
Finds airports by their type.

```swift
let largeAirports = AirportData.getAirportsByType("large_airport")
// Types: large_airport, medium_airport, small_airport, heliport, seaplane_base

// Use "airport" to match all airport types
let allAirports = AirportData.getAirportsByType("airport")
```

#### `getAirportsByTimezone(_:)`
Finds all airports within a specific timezone.

```swift
let londonAirports = try AirportData.getAirportsByTimezone("Europe/London")
```

### Advanced Functions

#### `findAirports(_:)`
Finds airports matching multiple criteria.

```swift
// Find large airports in Great Britain with scheduled service
let airports = AirportData.findAirports(AirportFilter(
    countryCode: "GB",
    type: "large_airport",
    hasScheduledService: true
))

// Find airports with minimum runway length
let longRunwayAirports = AirportData.findAirports(AirportFilter(
    minRunwayFt: 10000
))
```

#### `getAutocompleteSuggestions(_:)`
Provides autocomplete suggestions for search interfaces (returns max 10 results).

```swift
let suggestions = AirportData.getAutocompleteSuggestions("Lon")
// Returns up to 10 airports matching 'Lon' in name or IATA code
```

#### `getAirportLinks(_:)`
Gets external links for an airport using IATA or ICAO code.

```swift
let links = try AirportData.getAirportLinks("SIN")
// Returns AirportLinks with website, wikipedia, flightradar24, radarbox, flightaware
```

### Statistical & Analytical Functions

#### `getAirportStatsByCountry(_:)`
Gets comprehensive statistics about airports in a specific country.

```swift
let stats = try AirportData.getAirportStatsByCountry("US")
print(stats.total)                // Total airports
print(stats.byType)               // Count by type
print(stats.withScheduledService)  // Airports with scheduled service
print(stats.averageRunwayLength)   // Average runway length in feet
print(stats.averageElevation)      // Average elevation in feet
print(stats.timezones)             // All timezones
```

#### `getAirportStatsByContinent(_:)`
Gets comprehensive statistics about airports on a specific continent.

```swift
let stats = try AirportData.getAirportStatsByContinent("AS")
print(stats.byCountry)  // Count by country code
```

#### `getLargestAirportsByContinent(_:limit:sortBy:)`
Gets the largest airports on a continent by runway length or elevation.

```swift
// Top 5 by runway length
let airports = try AirportData.getLargestAirportsByContinent("AS", limit: 5, sortBy: "runway")

// Top 10 by elevation
let highAltitude = try AirportData.getLargestAirportsByContinent("SA", limit: 10, sortBy: "elevation")
```

### Bulk Operations

#### `getMultipleAirports(_:)`
Fetches multiple airports by their IATA or ICAO codes in one call.

```swift
let airports = AirportData.getMultipleAirports(["SIN", "LHR", "JFK", "WSSS"])
// Returns [Airport?] — nil for codes not found
```

#### `calculateDistanceMatrix(_:)`
Calculates distances between all pairs of airports in a list.

```swift
let matrix = try AirportData.calculateDistanceMatrix(["SIN", "LHR", "JFK"])
// matrix.airports — info about each airport
// matrix.distances["SIN"]!["LHR"]! — distance in km
```

### Validation & Utilities

#### `validateIataCode(_:)`
Validates if an IATA code exists in the database.

```swift
AirportData.validateIataCode("SIN")  // true
AirportData.validateIataCode("XYZ")  // false
```

#### `validateIcaoCode(_:)`
Validates if an ICAO code exists in the database.

```swift
AirportData.validateIcaoCode("WSSS")  // true
AirportData.validateIcaoCode("XXXX")  // false
```

#### `getAirportCount(_:)`
Gets the count of airports matching the given filters.

```swift
let total = AirportData.getAirportCount()

let count = AirportData.getAirportCount(AirportFilter(
    countryCode: "US",
    type: "large_airport"
))
```

#### `isAirportOperational(_:)`
Checks if an airport has scheduled commercial service.

```swift
let operational = try AirportData.isAirportOperational("SIN")  // true
```

## Error Handling

Methods that can fail throw `AirportDataError`:

```swift
do {
    let airport = try AirportData.getAirportByIata("XYZ")
} catch let error as AirportDataError {
    print(error.localizedDescription)  // "No data found for IATA code: XYZ"
}
```

## Examples

### Find airports near a city

```swift
let parisAirports = AirportData.findNearbyAirports(latitude: 48.8566, longitude: 2.3522, radiusKm: 100)
print("Found \(parisAirports.count) airports near Paris")
for result in parisAirports {
    print("\(result.airport.iata) - \(result.airport.airport) (\(Int(result.distance)) km)")
}
```

### Get flight distance

```swift
let distance = try AirportData.calculateDistance("SIN", "LHR")
print("Distance: \(Int(distance)) km")
```

### Build an airport search interface

```swift
let suggestions = AirportData.getAutocompleteSuggestions("New York")
for airport in suggestions {
    print("\(airport.iata) - \(airport.airport)")
}
```

### Filter airports by multiple criteria

```swift
let asianHubs = AirportData.findAirports(AirportFilter(
    continent: "AS",
    type: "large_airport",
    hasScheduledService: true
))
```

### Get airport statistics

```swift
let usStats = try AirportData.getAirportStatsByCountry("US")
print("Total airports: \(usStats.total)")
print("Large airports: \(usStats.byType["large_airport"] ?? 0)")
print("Average runway length: \(Int(usStats.averageRunwayLength)) ft")
```

### Bulk operations

```swift
let airports = AirportData.getMultipleAirports(["SIN", "LHR", "JFK", "NRT"])
for airport in airports.compactMap({ $0 }) {
    print("\(airport.iata): \(airport.airport)")
}

let matrix = try AirportData.calculateDistanceMatrix(["SIN", "LHR", "JFK"])
print("SIN to LHR: \(Int(matrix.distances["SIN"]!["LHR"]!)) km")
print("LHR to JFK: \(Int(matrix.distances["LHR"]!["JFK"]!)) km")
```

### Validation utilities

```swift
let codes = ["SIN", "XYZ", "LHR"]
for code in codes {
    let isValid = AirportData.validateIataCode(code)
    print("\(code): \(isValid ? "Valid" : "Invalid")")
}
```

## Related Libraries

| Platform | Package |
|----------|---------|
| JavaScript | [airport-data-js](https://github.com/aashishvanand/airport-data-js) |
| Python | [airport-data-python](https://github.com/aashishvanand/airport-data-python) |
| Dart/Flutter | [airport-data-dart](https://github.com/aashishvanand/airport-data-dart) |
| Rust | [airport-data-rust](https://github.com/aashishvanand/airport-data-rust) |

## Data Source

This library uses a comprehensive dataset of worldwide airports with regular updates to ensure accuracy and completeness.

## License

This project is licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0) - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/aashishvanand/airport-data-swift/issues).
