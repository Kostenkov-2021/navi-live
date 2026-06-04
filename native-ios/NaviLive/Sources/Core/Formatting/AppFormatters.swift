import Foundation

enum AppFormatters {
  static func distance(_ meters: Int) -> String {
    if meters >= 1000 {
      return String(format: "%.1f km", locale: L10n.currentLocale, Double(meters) / 1000.0)
    }
    return "\(meters) m"
  }

  static func eta(minutes: Int) -> String {
    if minutes <= 1 {
      return L10n.text("formatter.minute.one")
    }
    return L10n.text("formatter.minute.other", minutes)
  }

  static func accuracy(_ meters: Double?) -> String {
    guard let meters else {
      return L10n.text("formatter.accuracy.unknown")
    }
    return L10n.text("formatter.accuracy.value", Int(meters.rounded()))
  }

  static func coordinates(_ point: GeoPoint) -> String {
    String(format: "%.5f, %.5f", locale: L10n.currentLocale, point.latitude, point.longitude)
  }

  static func dateTime(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .shortened)
  }
}
