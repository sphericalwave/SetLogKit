//
//  CompletionChip.swift
//  SetLogKit
//
//  Small capsule that displays a 0–100 % completion score, color-coded.
//

import SwiftUI

public struct CompletionChip: View {
    /// 0...100, or nil when there is no qualifying data (renders "—").
    let percent: Double?
    /// Optional sub-label, e.g. "last" or "best".
    var caption: String?

    public init(percent: Double?, caption: String? = nil) {
        self.percent = percent
        self.caption = caption
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.caption2.weight(.semibold).monospacedDigit())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(tint.opacity(0.18)))
                .foregroundStyle(tint)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var label: String {
        guard let p = percent else { return "—" }
        return "\(Int(p.rounded()))%"
    }

    private var tint: Color {
        guard let p = percent else { return .secondary }
        switch p {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}
