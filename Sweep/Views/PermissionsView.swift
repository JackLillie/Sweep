import SwiftUI

struct PermissionsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var permissionGroups: [PermissionGroup] = []
    @State private var isLoading = false
    @State private var hasScanned = false
    @State private var hasFullDiskAccess = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if !hasScanned && !isLoading {
                setupView
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Reading permissions...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if permissionGroups.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("No permissions found")
                        .font(.system(size: 14, weight: .medium))
                    Button("Scan Again") {
                        Task { await scanPermissions() }
                    }
                    .controlSize(.regular)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resultsView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("")
        .onAppear { checkFDA() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkFDA()
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 36))
                .foregroundStyle(.red)

            VStack(spacing: 6) {
                Text("Privacy Audit")
                    .font(.system(size: 18, weight: .semibold))
                Text("See which apps have access to your camera, microphone,\nfiles, and other sensitive permissions.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            GroupBox {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(hasFullDiskAccess ? .green : .orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full Disk Access")
                            .font(.system(size: 13, weight: .medium))
                        Text(hasFullDiskAccess ? "Granted" : "Required to read permission database")
                            .font(.system(size: 11))
                            .foregroundStyle(hasFullDiskAccess ? .green : .secondary)
                    }

                    Spacer()

                    if hasFullDiskAccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Open Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                        }
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: 400)

            if hasFullDiskAccess {
                Button {
                    Task { await scanPermissions() }
                } label: {
                    Text("Scan Permissions")
                        .frame(minWidth: 120)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            } else {
                Text("Grant Full Disk Access to read the permissions database.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                GroupBox {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            let totalApps = permissionGroups.reduce(0) { $0 + $1.entries.count }
                            Text("\(totalApps) permissions across \(permissionGroups.count) categories")
                                .font(.system(size: 13, weight: .medium))
                            Text("Tap a category to see details")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        Button("Rescan") {
                            Task { await scanPermissions() }
                        }
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                }

                // Permission groups
                ForEach(permissionGroups) { group in
                    PermissionGroupCard(group: group)
                }

                // Open System Settings
                GroupBox {
                    Button {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
                    } label: {
                        HStack {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.secondary)
                            Text("Open Privacy & Security Settings")
                                .font(.system(size: 12))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - TCC Reading

    private func checkFDA() {
        let tccPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        hasFullDiskAccess = FileManager.default.isReadableFile(atPath: tccPath)
    }

    private func scanPermissions() async {
        isLoading = true
        hasScanned = true
        defer { isLoading = false }

        var allEntries: [(service: String, client: String, authValue: Int)] = []

        // Read both user and system TCC databases
        let dbPaths = [
            "/Library/Application Support/com.apple.TCC/TCC.db",
            NSHomeDirectory() + "/Library/Application Support/com.apple.TCC/TCC.db"
        ]

        for dbPath in dbPaths {
            if let entries = readTCCDatabase(path: dbPath) {
                allEntries.append(contentsOf: entries)
            }
        }

        // Group by service
        var grouped: [String: [PermissionEntry]] = [:]
        for entry in allEntries {
            let serviceName = mapServiceName(entry.service)
            let appName = resolveAppName(bundleID: entry.client)
            let granted = entry.authValue == 2
            let limited = entry.authValue == 3

            let permEntry = PermissionEntry(
                appName: appName,
                permission: serviceName,
                granted: granted || limited,
                icon: "app.fill"
            )

            grouped[entry.service, default: []].append(permEntry)
        }

        // Build groups, sorted by entry count
        permissionGroups = grouped
            .map { service, entries in
                let info = serviceInfo(service)
                return PermissionGroup(
                    service: service,
                    name: info.name,
                    icon: info.icon,
                    color: info.color,
                    entries: entries.sorted { $0.appName.localizedCompare($1.appName) == .orderedAscending }
                )
            }
            .filter { !$0.entries.isEmpty }
            .sorted { $0.entries.count > $1.entries.count }
    }

    private func readTCCDatabase(path: String) -> [(service: String, client: String, authValue: Int)]? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [path, "SELECT service, client, auth_value FROM access;"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }

            return output.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
                .compactMap { line in
                    let parts = line.components(separatedBy: "|")
                    guard parts.count >= 3,
                          let authValue = Int(parts[2]) else { return nil }
                    return (service: parts[0], client: parts[1], authValue: authValue)
                }
        } catch {
            return nil
        }
    }

    private func resolveAppName(bundleID: String) -> String {
        // Try to find the app by bundle ID
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let name = url.deletingPathExtension().lastPathComponent
            if !name.isEmpty { return name }
        }
        // Fall back to readable bundle ID
        let components = bundleID.components(separatedBy: ".")
        if let last = components.last, !last.isEmpty {
            return last
        }
        return bundleID
    }

    private func mapServiceName(_ service: String) -> String {
        serviceInfo(service).name
    }

    private func serviceInfo(_ service: String) -> (name: String, icon: String, color: Color) {
        switch service {
        case "kTCCServiceCamera": return ("Camera", "camera.fill", .orange)
        case "kTCCServiceMicrophone": return ("Microphone", "mic.fill", .red)
        case "kTCCServiceSystemPolicyAllFiles": return ("Full Disk Access", "internaldrive.fill", .blue)
        case "kTCCServiceAccessibility": return ("Accessibility", "accessibility", .purple)
        case "kTCCServiceScreenCapture": return ("Screen Recording", "rectangle.dashed.badge.record", .indigo)
        case "kTCCServicePhotos", "kTCCServicePhotosAdd": return ("Photos", "photo.fill", .pink)
        case "kTCCServiceAddressBook": return ("Contacts", "person.crop.circle.fill", .blue)
        case "kTCCServiceCalendar": return ("Calendar", "calendar", .red)
        case "kTCCServiceReminders": return ("Reminders", "checklist", .orange)
        case "kTCCServiceSystemPolicyDesktopFolder": return ("Desktop Folder", "folder.fill", .blue)
        case "kTCCServiceSystemPolicyDocumentsFolder": return ("Documents Folder", "doc.fill", .blue)
        case "kTCCServiceSystemPolicyDownloadsFolder": return ("Downloads Folder", "arrow.down.circle.fill", .blue)
        case "kTCCServiceSystemPolicyNetworkVolumes": return ("Network Volumes", "externaldrive.connected.to.line.below.fill", .gray)
        case "kTCCServiceSystemPolicyRemovableVolumes": return ("Removable Volumes", "externaldrive.fill", .gray)
        case "kTCCServiceAppleEvents": return ("Automation", "gearshape.2.fill", .green)
        case "kTCCServiceListenEvent": return ("Input Monitoring", "keyboard.fill", .purple)
        case "kTCCServiceMediaLibrary": return ("Media & Apple Music", "music.note", .pink)
        case "kTCCServiceSpeechRecognition": return ("Speech Recognition", "waveform", .blue)
        case "kTCCServiceDeveloperTool": return ("Developer Tools", "hammer.fill", .orange)
        case "kTCCServicePostEvent": return ("Input Monitoring", "cursorarrow.click", .purple)
        case "kTCCServiceLiverpool": return ("CloudKit", "icloud.fill", .blue)
        case "kTCCServiceUbiquity": return ("iCloud Drive", "icloud.fill", .blue)
        case "kTCCServiceWillow": return ("Home Data", "house.fill", .orange)
        case "kTCCServiceLocation": return ("Location Services", "location.fill", .blue)
        case "kTCCServiceBluetoothAlways": return ("Bluetooth", "wave.3.right", .blue)
        case "kTCCServiceContactsFull", "kTCCServiceContactsLimited": return ("Contacts", "person.crop.circle.fill", .blue)
        case "kTCCServiceMotion": return ("Motion & Fitness", "figure.walk", .green)
        case "kTCCServiceUserTracking": return ("App Tracking", "hand.raised.fill", .orange)
        case "kTCCServiceWebBrowserPublicKeyCredential": return ("Passkeys", "key.fill", .purple)
        case "kTCCServiceFocusStatus": return ("Focus Status", "moon.circle.fill", .indigo)
        case "kTCCServiceAppData": return ("App Data", "square.stack.fill", .gray)
        case "kTCCServiceEndpointSecurityClient": return ("Endpoint Security", "shield.fill", .red)
        case "kTCCServiceFileProviderPresence": return ("File Provider", "doc.badge.gearshape.fill", .blue)
        case "kTCCServiceFileProviderDomain": return ("File Provider", "doc.badge.gearshape.fill", .blue)
        case "kTCCServiceSiri": return ("Siri", "waveform.circle.fill", .purple)
        case "kTCCServiceSystemPolicySysAdminFiles": return ("Admin Files", "lock.doc.fill", .red)
        case "kTCCServiceSystemPolicyDeveloperFiles": return ("Developer Files", "wrench.fill", .orange)
        default:
            let cleaned = service
                .replacingOccurrences(of: "kTCCService", with: "")
                .replacingOccurrences(of: "SystemPolicy", with: "")
            return (cleaned, "lock.fill", .gray)
        }
    }
}

// MARK: - Permission Group Model

struct PermissionGroup: Identifiable {
    let id = UUID()
    let service: String
    let name: String
    let icon: String
    let color: Color
    let entries: [PermissionEntry]
}

// MARK: - Permission Group Card

struct PermissionGroupCard: View {
    let group: PermissionGroup
    @State private var isExpanded = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .frame(width: 12)

                        Image(systemName: group.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(group.color)
                            .frame(width: 20)

                        Text(group.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        let granted = group.entries.filter(\.granted).count
                        let denied = group.entries.filter { !$0.granted }.count

                        if granted > 0 {
                            HStack(spacing: 3) {
                                Circle().fill(.green).frame(width: 6, height: 6)
                                Text("\(granted)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if denied > 0 {
                            HStack(spacing: 3) {
                                Circle().fill(.red).frame(width: 6, height: 6)
                                Text("\(denied)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()
                        .padding(.top, 8)

                    ForEach(group.entries) { entry in
                        HStack(spacing: 10) {
                            Text(entry.appName)
                                .font(.system(size: 12))
                                .lineLimit(1)

                            Spacer()

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(entry.granted ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                Text(entry.granted ? "Allowed" : "Denied")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        if entry.id != group.entries.last?.id {
                            Divider().padding(.leading, 4)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
    }
}
