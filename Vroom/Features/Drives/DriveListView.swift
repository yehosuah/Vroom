import SwiftUI

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
            return "Last 7 days"
        case .month:
            return "Last 30 days"
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

struct DriveListView: View {
    @EnvironmentObject private var appState: AppStateStore
    @State private var searchText = ""
    @State private var favoritesOnly = false
    @State private var dateScope: HistoryDateScope = .all

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

    private var vehicleFilterLabel: String {
        appState.vehicle(for: appState.selectedVehicleFilter)?.nickname ?? "All vehicles"
    }

    private var vehicleOptions: [(title: String, value: UUID?)] {
        [("All vehicles", nil)] + appState.vehicles.map { ($0.nickname, Optional($0.id)) }
    }

    private var resultSubtitle: String {
        if filteredDrives.isEmpty {
            return searchText.isEmpty ? "No drives match the current filters." : "Try a different search or clear a filter."
        }
        return favoritesOnly ? "Showing saved drives only." : "Open a drive to review the full route and events."
    }

    var body: some View {
        RoadScreenScaffold {
            RoadPageHeader(
                title: "History",
                subtitle: "Search, filter, and reopen your completed drives."
            )

            filterBar

            VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                RoadSectionHeader(
                    title: filteredDrives.isEmpty ? "No drives found" : "\(filteredDrives.count) drive\(filteredDrives.count == 1 ? "" : "s")",
                    subtitle: resultSubtitle
                )

                if filteredDrives.isEmpty {
                    RoadEmptyState(
                        title: searchText.isEmpty ? "No drives yet" : "No matching drives",
                        message: searchText.isEmpty ? "Start and save a drive to build your history." : "Try a different search or clear one of the filters.",
                        icon: searchText.isEmpty ? "road.lanes" : "magnifyingglass"
                    )
                } else {
                    ForEach(filteredDrives) { drive in
                        HistoryDriveRow(drive: drive)
                            .environmentObject(appState)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search drives")
        .task {
            await appState.refreshData()
        }
        .accessibilityIdentifier("History.Screen")
    }

    private var filterBar: some View {
        RoadPanel(padding: RoadSpacing.regular) {
            VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: RoadSpacing.regular) {
                        Text("Filters")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)

                        Spacer(minLength: RoadSpacing.regular)

                        vehicleFilterMenu
                    }

                    VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                        Text("Filters")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RoadTheme.textPrimary)

                        vehicleFilterMenu
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

    private var vehicleFilterMenu: some View {
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
                    .font(RoadTypography.caption.weight(.semibold))
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
}

private struct HistoryDriveRow: View {
    @EnvironmentObject private var appState: AppStateStore
    let drive: Drive

    private var currentDrive: Drive {
        appState.drives.first(where: { $0.id == drive.id }) ?? drive
    }

    private var presentation: JournalDrivePresentation {
        RoadPresentationBuilder.journalRow(drive: currentDrive, vehicle: appState.vehicle(for: currentDrive.vehicleID))
    }

    private var stats: [RoadMetricPresentation] {
        [
            RoadMetricPresentation(
                id: "history-score-\(currentDrive.id)",
                label: "Score",
                value: "\(currentDrive.scoreSummary.overall)",
                icon: "rosette",
                accent: .success
            ),
            RoadMetricPresentation(
                id: "history-distance-\(currentDrive.id)",
                label: "Distance",
                value: RoadFormatting.distance(currentDrive.distanceMeters),
                icon: "arrow.left.and.right",
                accent: .neutral
            ),
            RoadMetricPresentation(
                id: "history-duration-\(currentDrive.id)",
                label: "Drive time",
                value: RoadFormatting.duration(currentDrive.duration),
                icon: "clock",
                accent: .electric
            )
        ]
    }

    var body: some View {
        RoadPanel {
            VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                NavigationLink {
                    DriveDetailView(drive: currentDrive)
                } label: {
                    VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: RoadSpacing.regular) {
                                titleBlock
                                Spacer(minLength: RoadSpacing.regular)
                                timestampBlock
                            }

                            VStack(alignment: .leading, spacing: RoadSpacing.compact) {
                                titleBlock
                                timestampBlock
                            }
                        }

                        HStack(spacing: RoadSpacing.small) {
                            RoadCapsuleLabel(text: presentation.vehicleLabel, tint: RoadTheme.info, icon: "car.fill")

                            if presentation.isFavorite {
                                RoadCapsuleLabel(text: "Saved", tint: RoadTheme.primaryAction, icon: "star.fill")
                            }
                        }

                        RoadMetricGrid(metrics: stats, minimumWidth: 120)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("History.Drive.\(presentation.title.replacingOccurrences(of: " ", with: ""))")

                NavigationLink {
                    RouteReplayView(drive: currentDrive)
                } label: {
                    Label("Replay drive", systemImage: "play.circle")
                }
                .buttonStyle(RoadSecondaryButtonStyle())
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: RoadSpacing.xSmall) {
            Text(presentation.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(RoadTheme.textPrimary)

            Text(presentation.subtitle)
                .font(RoadTypography.caption)
                .foregroundStyle(RoadTheme.textSecondary)
                .lineLimit(2)
        }
    }

    private var timestampBlock: some View {
        Text(presentation.timestamp)
            .font(RoadTypography.caption)
            .foregroundStyle(RoadTheme.textMuted)
    }
}
