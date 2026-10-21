import SwiftUI

struct SpotRowView: View {
    let spot: ParkingSpot
    let isPro: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(spot.label)
                .font(.headline)
            Text("\(spot.daysText) · \(spot.windowText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                if let next = spot.nextRestrictionStart() {
                    Label(nextText(next), systemImage: "bell")
                        .font(.caption)
                        .foregroundStyle(TSTheme.teal)
                } else {
                    Label("No upcoming window", systemImage: "bell.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if spot.isTodaysAlertCleared() {
                    Text("Moved car today")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TSTheme.amber)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func nextText(_ date: Date) -> String {
        let lead = LeadTimeOptions.effective(stored: spot.leadTimeMinutes, isPro: isPro)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Next \(formatter.string(from: date)) · \(lead) min heads-up"
    }
}
