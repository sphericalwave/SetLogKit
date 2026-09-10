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

    private var presets: [TempoPreset] { TempoPreset.all + library.custom }

    var body: some View {
        List {
            Section {
                ForEach(presets) { preset in
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
            } footer: {
                if !info.isEmpty {
                    Text(info)
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

/// Name + four phase steppers for a new custom tempo. Kept here rather than a
/// file of its own — it's only ever reached from `TempoDetailView`.
private struct AddTempoSheet: View {
    let onSave: (TempoPreset) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var eccentric = 3
    @State private var bottomPause = 1
    @State private var concentric = 1
    @State private var topPause = 0

    private var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
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
                }
                Section {
                    MetricStepperRow(label: "Eccentric", value: $eccentric, range: 0...9)
                    MetricStepperRow(label: "Bottom pause", value: $bottomPause, range: 0...9)
                    MetricStepperRow(label: "Concentric", value: $concentric, range: 0...9)
                    MetricStepperRow(label: "Top pause", value: $topPause, range: 0...9)
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
                            description: "", isCustom: true
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
