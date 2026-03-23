import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private enum HistoryDateScope: String, CaseIterable, Identifiable {
    case all
    case recent
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .recent:
            return "7 Days"
        case .month:
            return "30 Days"
        }
    }

    var icon: String {
        switch self {
        case .all:
            return "tray.full"
        case .recent:
            return "clock.arrow.circlepath"
        case .month:
            return "calendar"
        }
    }
}

private struct HistoryShareContext: Identifiable {
    let id = UUID()
    let drive: Drive
    let payload: SharePayload
}

struct DriveListView: View {
    @EnvironmentObject private var appState: AppStateStore

    @State private var searchText = ""
    @State private var favoritesOnly = false
    @State private var dateScope: HistoryDateScope = .all
    @State private var replayDrive: Drive?
    @State private var shareContext: HistoryShareContext?

    private var filteredDrives: [Drive] {
        appState.drives.filter { drive in
            let matchesSearch = searchText.isEmpty
                || drive.summary.title.localizedCaseInsensitiveContains(searchText)
                || drive.summary.highlight.localizedCaseInsensitiveContains(searchText)

            let matchesFavorites = !favoritesOnly || drive.favorite

            let matchesDateScope: Bool
            switch dateScope {
            case .all:
                matchesDateScope = true
            case .recent:
                matchesDateScope = drive.startedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
            case .month:
                matchesDateScope = drive.startedAt >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
            }

            return matchesSearch && matchesFavorites && matchesDateScope
        }
    }

    private var groupedDrives: [(title: String, drives: [Drive])] {
        let groups = Dictionary(grouping: filteredDrives) { drive in
            Self.monthFormatter.string(from: drive.startedAt)
        }

        return groups
            .map { (title: $0.key, drives: $0.value.sorted(by: { $0.startedAt > $1.startedAt })) }
            .sorted { lhs, rhs in
                guard
                    let lhsDate = lhs.drives.first?.startedAt,
                    let rhsDate = rhs.drives.first?.startedAt
                else { return lhs.title > rhs.title }
                return lhsDate > rhsDate
            }
    }

    private var vehicleFilterLabel: String {
        appState.vehicle(for: appState.selectedVehicleFilter)?.nickname ?? "All vehicles"
    }

    private var vehicleOptions: [(title: String, value: UUID?)] {
        [("All vehicles", nil)] + appState.vehicles.map { ($0.nickname, Optional($0.id)) }
    }

    private var filterSummary: String {
        var parts: [String] = []
        parts.append("\(filteredDrives.count) drive\(filteredDrives.count == 1 ? "" : "s")")
        if appState.selectedVehicleFilter != nil {
            parts.append(vehicleFilterLabel)
        }
        if favoritesOnly {
            parts.append("saved only")
        }
        if dateScope != .all {
            parts.append(dateScope.title)
        }
        return parts.joined(separator: " • ")
    }

    var body: some View {
        List {
            Section {
                filterBar
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if groupedDrives.isEmpty {
                Section {
                    RoadEmptyState(
                        title: searchText.isEmpty ? "No drives yet" : "No matching drives",
                        message: searchText.isEmpty
                            ? "Track a drive first, then history becomes the place you come back to."
                            : "Try a different search term or clear one of the active filters.",
                        icon: searchText.isEmpty ? "road.lanes" : "magnifyingglass"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } else {
                ForEach(groupedDrives, id: \.title) { section in
                    Section(section.title) {
                        ForEach(section.drives) { drive in
                            NavigationLink {
                                DriveDetailView(drive: drive)
                            } label: {
                                HistoryDriveRow(drive: drive)
                                    .environmentObject(appState)
                            }
                            .contextMenu {
                                Button(drive.favorite ? "Remove saved drive" : "Save drive") {
                                    Task { await appState.toggleFavorite(for: drive) }
                                }

                                Button("Watch replay") {
                                    replayDrive = drive
                                }

                                Button("Share drive") {
                                    Task {
                                        let payload = await appState.sharePayload(for: drive)
                                        shareContext = HistoryShareContext(drive: drive, payload: payload)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    Task { await appState.toggleFavorite(for: drive) }
                                } label: {
                                    Label(drive.favorite ? "Unsave" : "Save", systemImage: drive.favorite ? "star.slash" : "star")
                                }
                                .tint(RoadTheme.primaryAction)

                                Button {
                                    replayDrive = drive
                                } label: {
                                    Label("Replay", systemImage: "play.circle")
                                }
                                .tint(RoadTheme.info)
                            }
                            .accessibilityIdentifier("History.Drive.\(drive.summary.title.replacingOccurrences(of: " ", with: ""))")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .background(RoadBackdrop())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search drives")
        .refreshable {
            await appState.refreshData()
        }
        .task {
            await appState.refreshData()
        }
        .sheet(item: $shareContext) { context in
            NavigationStack {
                ShareComposerView(drive: context.drive, payload: context.payload)
                    .environmentObject(appState)
            }
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(item: $replayDrive) { drive in
            RouteReplayView(drive: drive)
        }
        .accessibilityIdentifier("History.Screen")
    }

    private var filterBar: some View {
        RoadPanel(padding: RoadSpacing.regular) {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: RoadSpacing.regular) {
                        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
                            Text("Find a remembered drive fast.")
                                .font(RoadTypography.label)
                                .foregroundStyle(RoadTheme.textPrimary)

                            Text(filterSummary)
                                .font(RoadTypography.meta)
                                .foregroundStyle(RoadTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        vehicleMenu
                    }

                    VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                        Text("Find a remembered drive fast.")
                            .font(RoadTypography.label)
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text(filterSummary)
                            .font(RoadTypography.meta)
                            .foregroundStyle(RoadTheme.textSecondary)

                        vehicleMenu
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RoadSpacing.compact) {
                        ForEach(HistoryDateScope.allCases) { scope in
                            Button {
                                dateScope = scope
                            } label: {
                                RoadSelectableChip(title: scope.title, icon: scope.icon, isSelected: dateScope == scope)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("History.Filter.\(scope.rawValue)")
                        }

                        Button {
                            favoritesOnly.toggle()
                        } label: {
                            RoadSelectableChip(title: "Saved", icon: "star.fill", isSelected: favoritesOnly)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("History.Filter.saved")
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var vehicleMenu: some View {
        Menu {
            ForEach(vehicleOptions, id: \.title) { option in
                Button(option.title) {
                    Task { await appState.setVehicleFilter(option.value) }
                }
            }
        } label: {
            HStack(spacing: RoadSpacing.small) {
                Image(systemName: "car.fill")
                    .foregroundStyle(RoadTheme.info)

                Text(vehicleFilterLabel)
                    .font(RoadTypography.label)
                    .foregroundStyle(RoadTheme.textPrimary)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RoadTheme.textMuted)
            }
            .padding(.horizontal, RoadSpacing.regular)
            .frame(minHeight: RoadHeight.compact)
            .background(
                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                    .fill(RoadTheme.backgroundRaised)
            )
            .overlay {
                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                    .strokeBorder(RoadTheme.border)
            }
        }
        .buttonStyle(.plain)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
}

private struct HistoryDriveRow: View {
    @EnvironmentObject private var appState: AppStateStore
    let drive: Drive

    private static let previewSize = CGSize(width: 112, height: 92)

    private var currentDrive: Drive {
        appState.drives.first(where: { $0.id == drive.id }) ?? drive
    }

    private var presentation: JournalDrivePresentation {
        RoadPresentationBuilder.journalRow(drive: currentDrive, vehicle: appState.vehicle(for: currentDrive.vehicleID))
    }

    private var previewState: DriveRoutePreviewState {
        appState.routePreviewState(for: currentDrive.id, size: Self.previewSize)
    }

    var body: some View {
        HStack(alignment: .top, spacing: RoadSpacing.compact) {
            previewCard

            VStack(alignment: .leading, spacing: RoadSpacing.small) {
                HStack(alignment: .top, spacing: RoadSpacing.compact) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(presentation.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)

                        Text(presentation.subtitle)
                            .font(RoadTypography.meta)
                            .foregroundStyle(RoadTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    RoadCapsuleLabel(text: "Score \(currentDrive.scoreSummary.overall)", tint: RoadTheme.success)
                }

                HStack(spacing: RoadSpacing.compact) {
                    RoadCapsuleLabel(text: presentation.vehicleLabel, tint: RoadTheme.info, icon: "car.fill")
                    RoadCapsuleLabel(text: RoadFormatting.distance(currentDrive.distanceMeters), tint: RoadTheme.primaryAction, icon: "arrow.left.and.right")

                    if presentation.isFavorite {
                        RoadCapsuleLabel(text: "Saved", tint: RoadTheme.warning, icon: "star.fill")
                    }
                }

                Text(presentation.timestamp)
                    .font(RoadTypography.caption)
                    .foregroundStyle(RoadTheme.textMuted)
            }
        }
        .padding(.vertical, RoadSpacing.small)
        .contentShape(Rectangle())
        .task(id: PreviewTaskID(driveID: currentDrive.id, mapStyle: appState.preferences.mapStyle)) {
            await appState.ensureRouteAssets(
                for: currentDrive.id,
                includePreview: true,
                previewSize: Self.previewSize,
                mapStyle: appState.preferences.mapStyle
            )
        }
    }

    @ViewBuilder
    private var previewCard: some View {
        switch previewState {
        case .idle, .loading:
            previewPlaceholder(title: "Loading", icon: "point.3.filled.connected.trianglepath", showsProgress: true)

        case .ready(let data):
            if let image = previewImage(from: data) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.previewSize.width, height: Self.previewSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                            .strokeBorder(RoadTheme.border)
                    }
                    .accessibilityIdentifier("History.Preview.\(currentDrive.id.uuidString)")
            } else {
                previewPlaceholder(title: "Route", icon: "map", showsProgress: false)
            }

        case .unavailable:
            previewPlaceholder(title: "No route", icon: "map", showsProgress: false)
        }
    }

    private func previewPlaceholder(title: String, icon: String, showsProgress: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                .fill(RoadTheme.backgroundRaised)

            VStack(spacing: RoadSpacing.xSmall) {
                if showsProgress {
                    ProgressView()
                        .tint(RoadTheme.primaryAction)
                } else {
                    Image(systemName: icon)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RoadTheme.info)
                }

                Text(title)
                    .font(RoadTypography.caption.weight(.semibold))
                    .foregroundStyle(RoadTheme.textSecondary)
            }
        }
        .frame(width: Self.previewSize.width, height: Self.previewSize.height)
        .overlay {
            RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                .strokeBorder(RoadTheme.border)
        }
    }

    private func previewImage(from data: Data) -> Image? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        return Image(uiImage: image)
        #else
        return nil
        #endif
    }
}

private struct PreviewTaskID: Hashable {
    let driveID: UUID
    let mapStyle: AppMapStyle
}
