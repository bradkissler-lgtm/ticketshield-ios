import Foundation
import Observation

@Observable
final class AppPreferences {
    private enum Key {
        static let defaultLead = "ts.defaultLeadTimeMinutes"
        static let digest = "ts.weeklyDigestEnabled"
    }

    var defaultLeadTimeMinutes: Int {
        didSet {
            UserDefaults.standard.set(defaultLeadTimeMinutes, forKey: Key.defaultLead)
        }
    }

    var weeklyDigestEnabled: Bool {
        didSet {
            UserDefaults.standard.set(weeklyDigestEnabled, forKey: Key.digest)
        }
    }

    init(defaults: UserDefaults = .standard) {
        let storedLead = defaults.object(forKey: Key.defaultLead) as? Int
        defaultLeadTimeMinutes = storedLead ?? LeadTimeOptions.defaultMinutes
        weeklyDigestEnabled = defaults.bool(forKey: Key.digest)
    }
}
