# SetLogKit

Shared set-logging sheet and scoring logic for training apps: a drop-in `RatedSetForm`
UI plus the pure-function scoring, progression, and workout-segmenting logic behind it.

## Requirements

- iOS 17+ / macOS 14+
- Swift 5.9+

## Installation

```swift
.package(url: "https://github.com/sphericalwave/SetLogKit.git", branch: "main")
```

## Overview

- `SetRecord` — read-only face a persisted set presents to SetLogKit's logic; host apps conform their own model (SwiftData `@Model`, CoreData, plain struct)
- `RatedSetSkill` / `RatedSetForm` — the shared set-logging sheet. Conform a skill type + supply an `EquipmentModel` (from EquipmentKit) to get score chips, reps, TED metrics, notes, decision, isometric/slices, and the equipment slot for free
- `RatedSetFormConfig`, `RatedSetDraft`, `RatedSetEntry`, `PriorSet` — form configuration and state types
- `NoEquipment` — no-op `EquipmentModel` for skills with no equipment input
- `CompletionScorer` / `CompletionSettings` — completion scoring for a set
- `ProgressionEvaluator` / `ProgressionDecision` / `RatedSet` — Intuitive Training Protocol: suggests progress/repeat/regress from the last 3 logged sets (sustained RPT ≥ 8, RPD ≤ 3, RPE ≥ 6 across 3 sessions → progress; high RPD or low RPT → regress; otherwise repeat)
- `WorkoutSegmenter` / `WorkoutSegment` — segments a workout's logged sets
- `FalseColor` — false-color mapping for metric visualization
- `HRConfig` / `HRStats` — heart-rate stats display config
- UI widgets: `CompletionChip`, `TEDMetricStepper`, `MetricStepperRow`, `HRStatRow`, `TEDDescription`

## Dependencies

- [EquipmentKit](https://github.com/sphericalwave/EquipmentKit) (remote, branch `main`)

## Host app

`HostApp/RatedSetFormHarness` is a standalone harness app for previewing/testing
`RatedSetForm` in isolation, with a UI test target.
