import Foundation

struct RouteIssueDiagnosticSnapshot: Codable, Sendable {
  var createdAt: Date
  var appVersion: String
  var appBuild: String
  var destinationID: String?
  var destinationName: String?
  var currentStepIndex: Int
  var stepCount: Int
  var currentInstruction: String
  var nextInstruction: String
  var distanceToNextMeters: Int
  var remainingDistanceMeters: Int
  var isPaused: Bool
  var isOffRoute: Bool
  var isRecalculating: Bool
  var offRouteDistanceMeters: Int?
  var accuracyMeters: Double?
  var currentStep: RouteIssueStepSnapshot?
  var nextStep: RouteIssueStepSnapshot?
}

struct RouteIssueStepSnapshot: Codable, Sendable {
  var instruction: String
  var distanceMeters: Int
  var kind: String
  var maneuverType: String?
  var maneuverModifier: String?
  var roadName: String?
}

actor RouteIssueDiagnosticLogger {
  private let fileURL: URL
  private let encoder: JSONEncoder

  init(fileManager: FileManager = .default) {
    let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSTemporaryDirectory())
    let directory = baseDirectory
      .appendingPathComponent("NaviLive", isDirectory: true)
      .appendingPathComponent("Diagnostics", isDirectory: true)
    try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    fileURL = directory.appendingPathComponent("route-issues.jsonl")
    let configuredEncoder = JSONEncoder()
    configuredEncoder.dateEncodingStrategy = .iso8601
    encoder = configuredEncoder
  }

  func append(_ snapshot: RouteIssueDiagnosticSnapshot) throws {
    var line = try encoder.encode(snapshot)
    line.append(0x0A)

    if FileManager.default.fileExists(atPath: fileURL.path) {
      let handle = try FileHandle(forWritingTo: fileURL)
      try handle.seekToEnd()
      try handle.write(contentsOf: line)
      try handle.close()
    } else {
      try line.write(to: fileURL, options: [.atomic])
    }
  }
}