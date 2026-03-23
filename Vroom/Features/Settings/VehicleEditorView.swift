import SwiftUI

struct VehicleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppStateStore

    let editingVehicle: Vehicle?

    @State private var draft: VehicleEditorDraft
    @State private var showingArchiveConfirmation = false

    init(editingVehicle: Vehicle? = nil) {
        self.editingVehicle = editingVehicle
        _draft = State(initialValue: editingVehicle.map(VehicleEditorDraft.init) ?? VehicleEditorDraft())
    }

    private var nicknameIsValid: Bool {
        !draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Vehicle name", text: $draft.nickname)
                        .textInputAutocapitalization(.words)

                    TextField("Make", text: $draft.make)
                        .textInputAutocapitalization(.words)

                    TextField("Model", text: $draft.model)
                        .textInputAutocapitalization(.words)

                    Stepper("Year \(draft.year)", value: $draft.year, in: 1990...Calendar.current.component(.year, from: Date()) + 1)
                } header: {
                    Text("Vehicle")
                } footer: {
                    Text("Vehicle name is required. Make and model are optional.")
                }

                Section {
                    Toggle("Use as default vehicle", isOn: $draft.isPrimary)
                } header: {
                    Text("Defaults")
                } footer: {
                    Text("The default vehicle is the one new drives use unless you change it later.")
                }

                if !nicknameIsValid {
                    Section {
                        Label("Add a vehicle name before saving.", systemImage: "exclamationmark.circle.fill")
                            .font(RoadTypography.meta)
                            .foregroundStyle(RoadTheme.destructive)
                    }
                }

                if let vehicle = editingVehicle {
                    Section {
                        Button("Archive Vehicle", role: .destructive) {
                            showingArchiveConfirmation = true
                        }
                    } footer: {
                        Text("Archived vehicles are removed from the active garage.")
                    }
                    .confirmationDialog("Archive this vehicle?", isPresented: $showingArchiveConfirmation, titleVisibility: .visible) {
                        Button("Archive Vehicle", role: .destructive) {
                            Task {
                                await appState.archiveVehicle(vehicle)
                                dismiss()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .navigationTitle(editingVehicle == nil ? "Add Vehicle" : "Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
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
                    .disabled(!nicknameIsValid)
                }
            }
        }
    }
}
