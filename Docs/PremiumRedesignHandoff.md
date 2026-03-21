# Premium Redesign Handoff

## Design System
- Foundations live in `Vroom/Features/Shared/RoadTheme.swift`.
- Shared visual primitives:
  - `RoadBackdrop`
  - `RoadPanel`
  - `RoadSectionHeader`
  - `RoadCapsuleLabel`
  - `RoadStatPill`
  - `RoadPrimaryButtonStyle`
  - `RoadSecondaryButtonStyle`
  - `MetricCard`
- Shared formatting helpers live in `Vroom/Features/Shared/RoadFormatting.swift`.
- Shared route surface lives in `Vroom/Features/Shared/RouteMapView.swift`.

## Navigation Model
- Root shell: `AppTabShellView`
- Primary destinations:
  - `DashboardView`
  - `DriveListView`
  - `AnalyzeView`
  - `ConvoysView`
  - `GarageView`
- Modal/special destinations:
  - `LiveDriveView`
  - `DriveSummaryView`
  - `PaywallView`
  - `SettingsView`
  - `VehicleEditorView`

## Implemented Screen Mapping
- Onboarding: `OnboardingFlowView`
- Home: `DashboardView`
- Live Drive: `LiveDriveView`
- End Summary: `DriveSummaryView`
- History: `DriveListView`
- Drive Detail: `DriveDetailView`
- Route Replay: `RouteReplayView`
- Insights: `AnalyzeView`
- Convoys: `ConvoysView`
- Vehicles / Garage: `GarageView`
- Share Composer: `ShareComposerView`
- Premium: `PaywallView`
- Settings / Privacy: `SettingsView`

## State Conventions
- App-wide completion presentation: `AppStateStore.presentedCompletedDrive`
- Screen states are handled inline through empty/loading/active content branches.
- Route-driven surfaces should continue to reuse `RouteMapView` so map language stays consistent.

## Figma / Design Notes
- Information architecture artifact: create or claim the FigJam diagram from the generated link returned in chat.
- The current Figma MCP auth is still limited, so this repo document plus the SwiftUI theme files are the primary implementation source until editable Figma access is available.
