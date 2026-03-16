import SwiftUI

struct PermissionsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var permissions: [PermissionGroup] = []
    @State private var isLoading = false

    struct PermissionGroup: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
        let entries: [PermissionEntry]
    }

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning permissions...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if permissions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Audit app permissions")
                        .font(.system(size: 14, weight: .medium))
                    Text("See which apps have access to camera, mic, location, and more.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    Button("Scan Permissions") {
                        Task { await scanPermissions() }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(permissions) { group in
                            GroupBox {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: group.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(group.color)
                                            .frame(width: 24)
                                        Text(group.name)
                                            .font(.system(size: 13, weight: .semibold))
                                        Spacer()
                                        Text("\(group.entries.count) apps")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.bottom, 4)

                                    if group.entries.isEmpty {
                                        Text("No apps found")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.tertiary)
                                    } else {
                                        ForEach(group.entries) { entry in
                                            HStack(spacing: 10) {
                                                Image(systemName: entry.icon)
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.secondary)
                                                    .frame(width: 20)

                                                Text(entry.appName)
                                                    .font(.system(size: 12))

                                                Spacer()

                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(entry.granted ? .green : .red)
                                                        .frame(width: 6, height: 6)
                                                    Text(entry.granted ? "Granted" : "Denied")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 2)

                                            if entry.id != group.entries.last?.id {
                                                Divider()
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("")
    }

    private func scanPermissions() async {
        isLoading = true
        defer { isLoading = false }

        permissions = [
            PermissionGroup(
                name: "Full Disk Access",
                icon: "internaldrive",
                color: .blue,
                entries: []
            ),
            PermissionGroup(
                name: "Camera",
                icon: "camera",
                color: .orange,
                entries: []
            ),
            PermissionGroup(
                name: "Microphone",
                icon: "mic",
                color: .red,
                entries: []
            ),
            PermissionGroup(
                name: "Location",
                icon: "location",
                color: .green,
                entries: []
            ),
        ]
    }
}
