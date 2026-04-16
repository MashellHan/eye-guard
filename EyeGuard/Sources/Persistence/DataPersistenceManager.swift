import Foundation
import os

/// Data structure persisted to JSON for daily continuity.
struct DailyData: Codable, Sendable {
    let date: String
    let breakEvents: [BreakEvent]
    let totalScreenTime: TimeInterval
    let longestContinuousSession: TimeInterval
    let scoreHistory: [Int]
    let exerciseSessionsToday: Int

    init(
        date: String,
        breakEvents: [BreakEvent],
        totalScreenTime: TimeInterval,
        longestContinuousSession: TimeInterval,
        scoreHistory: [Int],
        exerciseSessionsToday: Int = 0
    ) {
        self.date = date
        self.breakEvents = breakEvents
        self.totalScreenTime = totalScreenTime
        self.longestContinuousSession = longestContinuousSession
        self.scoreHistory = scoreHistory
        self.exerciseSessionsToday = exerciseSessionsToday
    }
}

/// Manages JSON data persistence for daily break events and sessions.
///
/// File format: `~/EyeGuard/data/YYYY-MM-DD.json`
///
/// Responsibilities:
/// - Save today's break events, screen time, and score history
/// - Load data on app start for daily continuity
/// - Thread-safe via nonisolated(unsafe) for Foundation types
struct DataPersistenceManager: Sendable {

    /// Creates encoder/decoder fresh each call to avoid storing non-Sendable types.
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Public API

    /// Saves today's data to a JSON file.
    ///
    /// - Parameters:
    ///   - breakEvents: All break events recorded today.
    ///   - totalScreenTime: Total active screen time in seconds.
    ///   - longestContinuousSession: Longest unbroken usage stretch in seconds.
    ///   - scoreHistory: Recent health score values for trend calculation.
    ///   - date: The date to save for (defaults to today).
    func save(
        breakEvents: [BreakEvent],
        totalScreenTime: TimeInterval,
        longestContinuousSession: TimeInterval,
        scoreHistory: [Int],
        exerciseSessionsToday: Int = 0,
        date: Date = .now
    ) async {
        let dateString = Self.formatDateString(date)
        let dailyData = DailyData(
            date: dateString,
            breakEvents: breakEvents,
            totalScreenTime: totalScreenTime,
            longestContinuousSession: longestContinuousSession,
            scoreHistory: scoreHistory,
            exerciseSessionsToday: exerciseSessionsToday
        )

        let fileURL = Self.fileURL(for: dateString)

        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let data = try Self.makeEncoder().encode(dailyData)
            try data.write(to: fileURL, options: .atomic)
            Log.persistence.info("Data saved: \(fileURL.lastPathComponent)")
        } catch {
            Log.persistence.error("Failed to save data: \(error.localizedDescription)")
        }
    }

    /// Loads today's data from the JSON file.
    ///
    /// - Parameter date: The date to load for (defaults to today).
    /// - Returns: The loaded `DailyData`, or nil if no file exists.
    func load(for date: Date = .now) async -> DailyData? {
        let dateString = Self.formatDateString(date)
        let fileURL = Self.fileURL(for: dateString)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Log.persistence.info("No data file for \(dateString)")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let dailyData = try Self.makeDecoder().decode(DailyData.self, from: data)
            Log.persistence.info("Data loaded: \(fileURL.lastPathComponent)")
            return dailyData
        } catch {
            Log.persistence.error("Failed to load data: \(error.localizedDescription)")
            return nil
        }
    }

    /// Checks if data exists for the given date.
    ///
    /// - Parameter date: The date to check.
    /// - Returns: True if a data file exists for the date.
    func exists(for date: Date = .now) -> Bool {
        let dateString = Self.formatDateString(date)
        let fileURL = Self.fileURL(for: dateString)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - Private

    /// Returns the file URL for a given date string.
    private static func fileURL(for dateString: String) -> URL {
        EyeGuardConstants.dataDirectory
            .appendingPathComponent("\(dateString).json")
    }

    /// Formats a date as YYYY-MM-DD using the shared static formatter (v1.9).
    private static func formatDateString(_ date: Date) -> String {
        TimeFormatting.dateStringFormatter.string(from: date)
    }
}
