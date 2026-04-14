import Foundation

struct HistoryEntry: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let text: String

    init(id: UUID = UUID(), createdAt: Date = Date(), text: String) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
    }
}

enum HistoryRetentionPolicy: String, CaseIterable {
    case keepForever
    case keepMonth
    case keepWeek
    case keep24Hours

    func cutoffDate(referenceDate: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .keepForever:
            return nil
        case .keepMonth:
            return calendar.date(byAdding: .month, value: -1, to: referenceDate)
        case .keepWeek:
            return calendar.date(byAdding: .day, value: -7, to: referenceDate)
        case .keep24Hours:
            return calendar.date(byAdding: .hour, value: -24, to: referenceDate)
        }
    }
}
