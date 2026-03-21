# RoadTrack

RoadTrack is an iPhone-first drive tracker built inside the existing `Vroom` Xcode project while preserving the modular boundaries from the production plan.

## What is implemented

- App shell with onboarding, tab navigation, and dependency composition
- Domain models, configuration, repository contracts, and service boundaries
- SwiftData persistence for profile, vehicles, drives, events, traps, zones, subscription cache, convoy cache, and sync envelopes
- Route trace blob storage under Application Support
- Manual drive start and stop with simulated telemetry feeding route capture, scoring, trap extraction, and zone matching
- Dashboard, drives, drive detail, replay, analyze, convoys, settings, paywall, vehicle editor, and share composer flows
- Local export and local reset controls
- Mock convoy transport and convoy session coordinator
- Unit tests for trip detection, scoring, trap extraction, and insight aggregation

## Setup

- Xcode `26.3`
- Deployment target `iOS 17.0`
- Open `Vroom.xcodeproj`
- Build the `Vroom` scheme for an iPhone simulator

## Permissions and capabilities

The app currently declares and uses these user-facing permissions:

- Background location
- When-in-use and always location usage descriptions
- Motion usage description
- Notifications usage description

## Known limitations

- Identity is local-first only
- Convoy transport is mock and in-process only
- Voice remains a service placeholder
- Drive capture currently uses manual start with simulated telemetry rather than live sensor fusion
- Sync remains a no-op boundary with queued envelope support only

## Next backend steps

- Add CloudKit-backed personal sync adapters behind `SyncEngine`
- Replace simulated drive input with fused `CoreLocation` and `CoreMotion` capture
- Replace `MockConvoyTransport` with an authenticated realtime transport
- Add production voice provider wiring behind `VoiceChatService`
