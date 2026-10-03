import SwiftUI
import SwiftData
import UserNotifications

struct SpotListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AppPreferences.self) private var preferences
    @Query(sort: \ParkingSpot.createdAt) private var spots: [ParkingSpot]

    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var movedCarMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if spots.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(TSTheme.groupedBackground)
            .navigationTitle("ParkShield")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startAddFlow()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add parking spot")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSpotFlowView { draft in
                    save(draft)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Moved car", isPresented: Binding(
                get: { movedCarMessage != nil },
                set: { if !$0 { movedCarMessage = nil } }
            )) {
                Button("OK", role: .cancel) { movedCarMessage = nil }
            } message: {
                Text(movedCarMessage ?? "")
            }
        }
    }

    private var sortedSpots: [ParkingSpot] {
        spots.sorted { a, b in
            let na = a.nextRestrictionStart() ?? .distantFuture
            let nb = b.nextRestrictionStart() ?? .distantFuture
            if na != nb { return na < nb }
            return a.label.localizedCaseInsensitiveCompare(b.label) == .orderedAscending
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "signpost.right.fill")
                .font(.system(size: 56))
                .foregroundStyle(TSTheme.teal)
                .accessibilityHidden(true)
            Text("Photo a parking sign")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("We’ll read the curb sign on this iPhone and suggest days and hours. You confirm the schedule. Then you get a local reminder before the window.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Button {
                startAddFlow()
            } label: {
                Label("Photo a parking sign", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(sortedSpots) { spot in
                    NavigationLink {
                        SpotDetailView(spot: spot)
                    } label: {
                        SpotRowView(spot: spot, isPro: entitlements.isPro)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            delete(spot)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            movedCar(spot)
                        } label: {
                            Label("Moved car", systemImage: "car")
                        }
                        .tint(TSTheme.teal)
                    }
                }
            } footer: {
                Text(footerText)
            }
        }
        .overlay(alignment: .bottom) {
            if !entitlements.isPro && spots.count >= SpotLimit.freeMax {
                Button {
                    showPaywall = true
                } label: {
                    Text("Free includes 1 saved spot. Upgrade for unlimited.")
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 8)
            }
        }
    }

    private var footerText: String {
        if entitlements.isPro {
            return "Reminders are scheduled on this iPhone. Nothing is uploaded."
        }
        return "Free includes 1 saved spot. Reminders stay on this iPhone."
    }

    private func startAddFlow() {
        if SpotLimit.canAdd(existingCount: spots.count, isPro: entitlements.isPro) {
            showAdd = true
        } else {
            showPaywall = true
        }
    }

    private func save(_ draft: SpotDraft) {
        let spot = ParkingSpot(
            label: draft.label.trimmingCharacters(in: .whitespacesAndNewlines),
            weekdayMask: Weekday.mask(from: draft.weekdays),
            startHour: Calendar.current.component(.hour, from: draft.start),
            startMinute: Calendar.current.component(.minute, from: draft.start),
            endHour: Calendar.current.component(.hour, from: draft.end),
            endMinute: Calendar.current.component(.minute, from: draft.end),
            leadTimeMinutes: draft.leadTimeMinutes,
            ocrSnippet: draft.ocrSnippet
        )
        modelContext.insert(spot)
        try? modelContext.save()
        showAdd = false
        Task {
            _ = await NotificationScheduler.requestAuthorization()
            var all = spots
            if !all.contains(where: { $0.spotID == spot.spotID }) {
                all.append(spot)
            }
            await NotificationScheduler.replenish(
                spots: all,
                digestEnabled: entitlements.isPro && preferences.weeklyDigestEnabled,
                isPro: entitlements.isPro
            )
        }
    }

    private func delete(_ spot: ParkingSpot) {
        modelContext.delete(spot)
        try? modelContext.save()
        Task {
            await NotificationScheduler.replenish(
                spots: spots.filter { $0.spotID != spot.spotID },
                digestEnabled: entitlements.isPro && preferences.weeklyDigestEnabled,
                isPro: entitlements.isPro
            )
        }
    }

    private func movedCar(_ spot: ParkingSpot) {
        spot.clearTodaysAlert()
        try? modelContext.save()
        movedCarMessage = "Today’s reminder for \(spot.label) is cleared. Next week’s reminder stays."
        Task {
            await NotificationScheduler.replenish(
                spots: spots,
                digestEnabled: entitlements.isPro && preferences.weeklyDigestEnabled,
                isPro: entitlements.isPro
            )
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ParkingSpot.self, configurations: config)
    return SpotListView()
        .modelContainer(container)
        .environment(EntitlementStore())
        .environment(AppPreferences())
}
