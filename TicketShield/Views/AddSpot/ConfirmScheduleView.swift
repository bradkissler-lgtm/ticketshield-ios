import SwiftUI
import UIKit

struct ConfirmScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlements

    let title: String
    @State private var draft: SpotDraft
    var previewImage: UIImage?
    var foundDays: Bool
    var foundTime: Bool
    var onSave: (SpotDraft) -> Void

    @State private var showPaywall = false

    init(
        title: String,
        draft: SpotDraft,
        previewImage: UIImage? = nil,
        foundDays: Bool = true,
        foundTime: Bool = true,
        onSave: @escaping (SpotDraft) -> Void
    ) {
        self.title = title
        self._draft = State(initialValue: draft)
        self.previewImage = previewImage
        self.foundDays = foundDays
        self.foundTime = foundTime
        self.onSave = onSave
    }

    var body: some View {
        Form {
            if let previewImage {
                Section {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .accessibilityLabel("Photo of the parking sign")
                }
            }

            if !draft.ocrSnippet.isEmpty {
                Section("What we read") {
                    Text(draft.ocrSnippet)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section {
                TextField("Label", text: $draft.label)
                    .textInputAutocapitalization(.sentences)
            } header: {
                Text("Spot")
            } footer: {
                Text("A name you’ll recognize, like “Home driveway” or “Street cleaning.”")
            }

            Section {
                dayChips
            } header: {
                Text("Days")
            } footer: {
                if !foundDays {
                    Text("No days were found on the sign. Select every day the restriction applies.")
                }
            }

            Section {
                DatePicker("Starts", selection: $draft.start, displayedComponents: .hourAndMinute)
                DatePicker("Ends", selection: $draft.end, displayedComponents: .hourAndMinute)
            } header: {
                Text("Time window")
            } footer: {
                if !foundTime {
                    Text("No hours were found. 8:00–11:00 AM is a common street-cleaning window — please match the sign.")
                }
            }

            Section {
                Picker("Remind me", selection: $draft.leadTimeMinutes) {
                    ForEach(LeadTimeOptions.available(isPro: entitlements.isPro), id: \.self) { minutes in
                        Text("\(minutes) minutes before").tag(minutes)
                    }
                }
                if !entitlements.isPro {
                    Button("More lead times with Pro") {
                        showPaywall = true
                    }
                    .font(.footnote)
                }
            } header: {
                Text("Reminder")
            } footer: {
                Text("The alert is a local notification on this iPhone. Default is 30 minutes.")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onSave(draft)
                dismiss()
            } label: {
                Text("Save reminder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!draft.isValid)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            let options = LeadTimeOptions.available(isPro: entitlements.isPro)
            if !options.contains(draft.leadTimeMinutes) {
                draft.leadTimeMinutes = LeadTimeOptions.effective(
                    stored: draft.leadTimeMinutes,
                    isPro: entitlements.isPro
                )
            }
        }
    }

    private var dayChips: some View {
        let days = Weekday.orderedForDisplay()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(days) { day in
                let selected = draft.weekdays.contains(day)
                Button {
                    if selected {
                        draft.weekdays.remove(day)
                    } else {
                        draft.weekdays.insert(day)
                    }
                } label: {
                    Text(day.letter)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? TSTheme.teal : Color(.secondarySystemFill))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.accessibilityName)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
