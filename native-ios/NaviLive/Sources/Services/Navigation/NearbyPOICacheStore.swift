import Foundation

struct NearbyPOICacheRecord: Codable, Sendable {
  var id: String
  var name: String
  var address: String
  var point: GeoPoint
  var phone: String?
  var website: String?
  var kind: String
  var searchableText: String
  var fetchedAt: Date
}

actor NearbyPOICacheStore {
  private struct Snapshot: Codable {
    var version: Int = 1
    var lastUpdatedAt: Date?
    var center: GeoPoint?
    var records: [NearbyPOICacheRecord] = []
  }

  private let fileURL: URL
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(fileManager: FileManager = .default) {
    let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSTemporaryDirectory())
    let appDirectory = directory.appendingPathComponent("NaviLive", isDirectory: true)
    try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
    fileURL = appDirectory.appendingPathComponent("nearby-poi-cache.json")
  }

  func loadRecords() -> [NearbyPOICacheRecord] {
    readSnapshot().records
  }

  func metadata() -> NearbyPOICacheState {
    let snapshot = readSnapshot()
    return NearbyPOICacheState(
      cachedPlaceCount: snapshot.records.count,
      lastUpdatedAt: snapshot.lastUpdatedAt,
      lastCenter: snapshot.center
    )
  }

  func saveMerged(
    records: [NearbyPOICacheRecord],
    center: GeoPoint,
    fetchedAt: Date
  ) -> NearbyPOICacheState {
    var merged: [String: NearbyPOICacheRecord] = [:]
    records.forEach { record in
      var updated = record
      updated.fetchedAt = fetchedAt
      merged[updated.id] = updated
    }
    let minimumDate = fetchedAt.addingTimeInterval(-Self.maxRecordAge)
    readSnapshot().records
      .filter { $0.fetchedAt >= minimumDate }
      .forEach { record in
        if merged[record.id] == nil {
          merged[record.id] = record
        }
      }
    let pruned = merged.values
      .sorted { $0.fetchedAt > $1.fetchedAt }
      .prefix(Self.maxRecordCount)
    writeSnapshot(Snapshot(lastUpdatedAt: fetchedAt, center: center, records: Array(pruned)))
    return NearbyPOICacheState(
      cachedPlaceCount: pruned.count,
      lastUpdatedAt: fetchedAt,
      lastCenter: center
    )
  }

  func clear() -> NearbyPOICacheState {
    try? FileManager.default.removeItem(at: fileURL)
    return NearbyPOICacheState()
  }

  private func readSnapshot() -> Snapshot {
    guard let data = try? Data(contentsOf: fileURL),
          let snapshot = try? decoder.decode(Snapshot.self, from: data) else {
      return Snapshot()
    }
    return snapshot
  }

  private func writeSnapshot(_ snapshot: Snapshot) {
    guard let data = try? encoder.encode(snapshot) else { return }
    try? data.write(to: fileURL, options: [.atomic])
  }

  private static let maxRecordCount = 1_200
  private static let maxRecordAge: TimeInterval = 14 * 24 * 60 * 60
}
