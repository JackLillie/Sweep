import SwiftUI

struct ApplicationsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []
    @State private var isLoading = false
    @State private var sortOrder: SortOrder = .size

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case lastOpened = "Last Opened"
    }

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning applications...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if apps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Scan to find installed applications")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Button("Scan Applications") {
                        Task { await scanApps() }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Toolbar
                    HStack {
                        Text("\(filteredApps.count) applications")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Picker("Sort by", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)

                    Divider()

                    List(filteredApps) { app in
                        HStack(spacing: 12) {
                            Image(systemName: "app.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.blue)
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text(app.path)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            if let days = app.daysSinceLastOpened {
                                Text(days > 0 ? "\(days)d ago" : "Today")
                                    .font(.system(size: 11))
                                    .foregroundStyle(days > 90 ? .orange : .secondary)
                            }

                            Text(app.formattedSize)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("")
        .searchable(text: $searchText, placement: .toolbar, prompt: "Filter applications")
    }

    private var filteredApps: [AppInfo] {
        let filtered = searchText.isEmpty ? apps : apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }

        switch sortOrder {
        case .name:
            return filtered.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .size:
            return filtered.sorted { $0.size > $1.size }
        case .lastOpened:
            return filtered.sorted {
                ($0.lastOpened ?? .distantPast) < ($1.lastOpened ?? .distantPast)
            }
        }
    }

    private func scanApps() async {
        isLoading = true
        defer { isLoading = false }

        let fm = FileManager.default
        let applicationsPath = "/Applications"

        guard let contents = try? fm.contentsOfDirectory(atPath: applicationsPath) else { return }

        var scanned: [AppInfo] = []
        for item in contents where item.hasSuffix(".app") {
            let fullPath = "\(applicationsPath)/\(item)"
            let name = item.replacingOccurrences(of: ".app", with: "")

            var size: Int64 = 0
            if let enumerator = fm.enumerator(
                at: URL(fileURLWithPath: fullPath),
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let url as URL in enumerator {
                    if let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
                       let fileSize = values.totalFileAllocatedSize {
                        size += Int64(fileSize)
                    }
                }
            }

            let bundleID = Bundle(path: fullPath)?.bundleIdentifier ?? ""
            let attrs = try? fm.attributesOfItem(atPath: fullPath)
            let lastOpened = attrs?[.modificationDate] as? Date

            scanned.append(AppInfo(
                name: name,
                bundleIdentifier: bundleID,
                size: size,
                path: fullPath,
                lastOpened: lastOpened
            ))
        }

        apps = scanned
    }
}
