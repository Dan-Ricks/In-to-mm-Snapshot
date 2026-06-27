import Foundation
import SwiftUI

struct Measurement: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let inches: Double
    let millimeters: Double
    let description: String

    init(inches: Double, description: String) {
        self.id = UUID()
        self.date = Date()
        self.inches = inches
        self.millimeters = inches * 25.4
        self.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@Observable
final class ConversionStore {
    private(set) var measurements: [Measurement] = []
    private let storageKey = "intomm.measurements"

    init() {
        load()
    }

    func save(_ measurement: Measurement) {
        measurements.insert(measurement, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        measurements.remove(atOffsets: offsets)
        persist()
    }

    func delete(_ measurement: Measurement) {
        measurements.removeAll { $0.id == measurement.id }
        persist()
    }

    func clearAll() {
        measurements.removeAll()
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Measurement].self, from: data) else {
            measurements = []
            return
        }
        measurements = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(measurements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

extension Date {
    func formattedForHistory() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
