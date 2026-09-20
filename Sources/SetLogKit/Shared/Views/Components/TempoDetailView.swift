//
//  TempoDetailView.swift
//  SetLogKit
//
//  Full-screen list of tempo presets, pushed from `TempoRow`. Tapping a preset
//  writes all four phase bindings and pops back. When the host supplies a
//  `TempoPresetLibrary` with an `onAdd`, the list also carries the host's
//  custom presets and an "Add tempo" affordance.
//

import SwiftUI

struct TempoDetailView: View {
    @Binding var eccentric: Int
    @Binding var bottomPause: Int
    @Binding var concentric: Int
    @Binding var topPause: Int
    let info: String
    var library: TempoPresetLibrary = .none

    @Environment(\.dismiss) private var dismiss
    @State private var showingAdd = false

    var body: some View {
        List {
            Section {
                ForEach(TempoPreset.reps) { preset in
                    row(for: preset)
                }
            } header: {
                Text("Rep tempo")
            }

            Section {
                ForEach(TempoPreset.isometrics) { preset in
                    row(for: preset)
                }
            } header: {
                Text("Isometric strength")
            } footer: {
                Text("One held position instead of reps — the coach counts the hold out.")
            }

            if !library.custom.isEmpty || library.isEditable {
                Section {
                    ForEach(library.custom) { preset in
                        row(for: preset)
                    }
                    if library.isEditable {
                        Button {
                            showingAdd = true
                        } label: {
                            Label("Add tempo", systemImage: "plus")
                                .font(.headline)
                        }
                        .accessibilityIdentifier("tempoDetail.add")
                    }
                } header: {
                    Text("Custom")
                } footer: {
                    if !info.isEmpty {
                        Text(info)
                    }
                }
            }
        }
        .navigationTitle("Tempo")
        .inlineNavTitle()
        .sheet(isPresented: $showingAdd) {
            AddTempoSheet { preset in
                library.onAdd?(preset)
                apply(preset)
            }
        }
    }

    @ViewBuilder
    private func row(for preset: TempoPreset) -> some View {
        let selected = preset.matches(eccentric: eccentric, bottomPause: bottomPause,
                                       concentric: concentric, topPause: topPause)
        Button {
            apply(preset)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(preset.label).font(.headline)
                        Text(preset.tempoString)
                            .font(.subheadline).monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    if !preset.description.isEmpty {
                        Text(preset.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            if preset.isCustom, let onDelete = library.onDelete {
                Button(role: .destructive) { onDelete(preset) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func apply(_ preset: TempoPreset) {
        eccentric = preset.eccentric
        bottomPause = preset.bottomPause
        concentric = preset.concentric
        topPause = preset.topPause
        dismiss()
    }
}

/// One phase of a custom tempo: type the seconds directly, or step by one.
/// A 90-second hold is 90 taps on a stepper alone, hence the field.
private struct PhaseDurationRow: View {
    let label: String
    @Binding var value: Int

    static let range = 0...90

    var body: some View {
        Stepper(value: $value, in: Self.range) {
            HStack {
                Text(label).font(.callout)
                Spacer()
                TextField("0", value: $value, format: .number)
                    .decimalKeyboard()
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 48)
                    .onChange(of: value) { _, new in
                        let clamped = min(max(new, Self.range.lowerBound), Self.range.upperBound)
                        if clamped != new { value = clamped }
                    }
                Text("s").foregroundStyle(.secondary)
            }
        }
    }
}

/// Name + four phase rows for a new custom tempo. Kept here rather than a
/// file of its own — it's only ever reached from `TempoDetailView`.
private struct AddTempoSheet: View {
    let onSave: (TempoPreset) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var detail = ""
    @State private var eccentric = 3
    @State private var bottomPause = 1
    @State private var concentric = 1
    @State private var topPause = 0

    private var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedDetail: String {
        detail.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var isEmpty: Bool {
        eccentric == 0 && bottomPause == 0 && concentric == 0 && topPause == 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $label)
                        .accessibilityIdentifier("addTempo.name")
                    TextField("Description (optional)", text: $detail, axis: .vertical)
                        .lineLimit(1...3)
                        .accessibilityIdentifier("addTempo.detail")
                }
                Section {
                    PhaseDurationRow(label: "Eccentric", value: $eccentric)
                    PhaseDurationRow(label: "Bottom pause", value: $bottomPause)
                    PhaseDurationRow(label: "Concentric", value: $concentric)
                    PhaseDurationRow(label: "Top pause", value: $topPause)
                } footer: {
                    Text("\(eccentric)-\(bottomPause)-\(concentric)-\(topPause) — seconds per phase.")
                        .monospacedDigit()
                }
            }
            .navigationTitle("New Tempo")
            .inlineNavTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(TempoPreset(
                            label: trimmedLabel,
                            eccentric: eccentric, bottomPause: bottomPause,
                            concentric: concentric, topPause: topPause,
                            description: trimmedDetail, isCustom: true
                        ))
                        dismiss()
                    }
                    .bold()
                    .disabled(trimmedLabel.isEmpty || isEmpty)
                    .accessibilityIdentifier("addTempo.save")
                }
            }
        }
    }
}
