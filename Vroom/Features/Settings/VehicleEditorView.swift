import SwiftUI

struct VehicleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppStateStore
    let editingVehicle: Vehicle?

    @State private var draft: VehicleEditorDraft

    init(editingVehicle: Vehicle? = nil) {
        self.editingVehicle = editingVehicle
        _draft = State(initialValue: editingVehicle.map(VehicleEditorDraft.init) ?? VehicleEditorDraft())
    }

    var body: some View {
        NavigationStack {
            RoadScreenScaffold(bottomPadding: 40) {
                RoadPageHeader(
                    title: editingVehicle == nil ? "Add vehicle" : "Edit vehicle",
                    subtitle: "Update the vehicle information used in Garage and History."
                )

                RoadPanel {
                    VStack(alignment: .leading, spacing: RoadSpacing.regular) {
                        RoadTextField(
                            title: "Vehicle name",
                            helper: "Shown in History and Garage.",
                            text: $draft.nickname
                        )
                        RoadTextField(
                            title: "Make",
                            helper: "Optional.",
                            text: $draft.make
                        )
                        RoadTextField(
                            title: "Model",
                            helper: "Optional.",
                            text: $draft.model
                        )

                        RoadFormField(title: "Year", helper: "Use the model year that best matches this vehicle.") {
                            Stepper(value: $draft.year, in: 1990...Calendar.current.component(.year, from: Date()) + 1) {
                                Text("\(draft.year)")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(RoadTheme.textPrimary)
                            }
                            .padding(.horizontal, RoadSpacing.regular)
                            .frame(minHeight: RoadHeight.regular)
                            .background(
                                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                    .fill(RoadTheme.backgroundRaised)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                    .strokeBorder(RoadTheme.border)
                            }
                            .tint(RoadTheme.primaryAction)
                        }

                        RoadFormField(title: "Set as primary vehicle", helper: "Use this vehicle by default for new drives.") {
                            Toggle(isOn: $draft.isPrimary) {
                                Text(draft.isPrimary ? "Primary vehicle" : "Not primary")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RoadTheme.textPrimary)
                            }
                            .tint(RoadTheme.primaryAction)
                            .padding(.horizontal, RoadSpacing.regular)
                            .frame(minHeight: RoadHeight.regular)
                            .background(
                                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                    .fill(RoadTheme.backgroundRaised)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: RoadRadius.medium, style: .continuous)
                                    .strokeBorder(RoadTheme.border)
                            }
                        }
                    }
                }

                if let vehicle = editingVehicle {
                    RoadPanel {
                        Button("Archive vehicle", role: .destructive) {
                            Task {
                                await appState.archiveVehicle(vehicle)
                                dismiss()
                            }
                        }
                        .buttonStyle(RoadSecondaryButtonStyle())
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save vehicle") {
                        Task {
                            await appState.saveVehicle(draft: draft, editing: editingVehicle)
                            dismiss()
                        }
                    }
                    .disabled(draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
