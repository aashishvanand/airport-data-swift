import Foundation

/// Errors thrown by AirportData functions.
public enum AirportDataError: LocalizedError, Equatable {
    case noDataFound(String)
    case invalidInput(String)

    public var errorDescription: String? {
        switch self {
        case .noDataFound(let message):
            return message
        case .invalidInput(let message):
            return message
        }
    }
}
