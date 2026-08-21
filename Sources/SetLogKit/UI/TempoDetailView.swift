//
//  TempoDetailView.swift
//  SetLogKit
//
//  Full-screen list of predefined tempo presets, pushed from `TempoRow`.
//  Tapping a preset writes all four phase bindings and pops back.
//

import SwiftUI

struct TempoDetailView: View {
    @Binding var eccentric: Int
    @Binding var bottomPause: Int
    @Binding var concentric: Int
    @Binding var topPause: Int
    let info: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(TempoPreset.all) { preset in
                    let selected = preset.matches(eccentric: eccentric, bottomPause: bottomPause,
                                                   concentric: concentric, topPause: topPause)
                    Button {
                        eccentric = preset.eccentric
                        bottomPause = preset.bottomPause
                        concentric = preset.concentric
                        topPause = preset.topPause
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text(preset.label).font(.headline)
                                    Text(preset.tempoString)
                                        .font(.subheadline).monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                }
            } footer: {
                if !info.isEmpty {
                    Text(info)
                }
            }
        }
        .navigationTitle("Tempo")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
