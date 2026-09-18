import SwiftUI
import SwiftData

struct SpotDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AppPreferences.self) private var preferences

    @Bindable var spot: ParkingSpot

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var movedCarNote: String?

    var body: some View {
        List {
            Section("Schedule") {
                LabeledContent("Days", value: spot.daysText.isEmpty ? "None" : spot.daysText)
                LabeledContent("Window", value: spot.windowText)
                LabeledContent("Lead time", value: "\(effectiveLead) minutes before")
                if let next = spot.nextRestrictionStart() {
                    LabeledContent("Next window", value: next.formatted(date: .abbreviated, time: .shortened))
                } else {
                    LabeledContent("Next window", value: "None upcoming")
                }
            }

            Section {
                Button {
                    spot.clearTodaysAlert()
                    try? modelContext.save()
                    movedCarNote = "Today’s reminder is cleared. Next week’s reminder stays."
                    Task { await replenish() }
                } label: {
                    Label("Moved car", systemImage: "car.fill")
                }
                .disabled(spot.isTodaysAlertCleared())
                if spot.isTodaysAlertCleared() {
                    Text("Today’s alert for this spot is already cleared.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Use this after you park somewhere else for the rest of today.")
            }

            if !spot.ocrSnippet.isEmpty {
                Section("What we read") {
                    Text(spot.ocrSnippet)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section {
                Button("Edit schedule") { showEdit = true }
                Button("Delete spot", role: .destructive) { showDeleteConfirm = true }
            }
        }
        .navigationTitle(spot.label)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                ConfirmScheduleView(
                    title: "Edit schedule",
                    draft: SpotDraft.from(spot: spot),
                    previewImage: nil,
                    foundDays: true,
                    foundTime: true,
                    onSave: { draft in
                        spot.apply(draft: draft)
                        try? modelContext.save()
                        Task { await replenish() }
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEdit = false }
                    }
                }
            }
        }
        .alert("Delete this spot?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(spot)
                try? modelContext.save()
                Task { await replenish() }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The reminder will stop. This does not affect other spots.")
        }
        .alert("Moved car", isPresented: Binding(
            get: { movedCarNote != nil },
            set: { if !$0 { movedCarNote = nil } }
        )) {
            Button("OK", role: .cancel) { movedCarNote = nil }
        } message: {
            Text(movedCarNote ?? "")
        }
    }

    private var effectiveLead: Int {
        LeadTimeOptions.effective(stored: spot.leadTimeMinutes, isPro: entitlements.isPro)
    }

    private func replenish() async {
        let descriptor = FetchDescriptor<ParkingSpot>()
        let spots = (try? modelContext.fetch(descriptor)) ?? []
        await NotificationScheduler.replenish(
            spots: spots,
            digestEnabled: entitlements.isPro && preferences.weeklyDigestEnabled,
            isPro: entitlements.isPro
        )
    }
}
