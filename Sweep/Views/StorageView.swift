import SwiftUI

struct StorageView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedCategory: StorageCategory?

    var body: some View {
        Group {
            if viewModel.isLoadingStorage {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing storage...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let path = viewModel.drillDownPath {
                drillDownView(path: path)
            } else {
                mainView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("")
        .onAppear {
            if !viewModel.storageScanned {
                Task { await viewModel.loadStorage() }
            }
        }
    }

    // MARK: - Main View

    private var mainView: some View {
        ScrollView {
            VStack(spacing: 16) {
                diskOverview
                categoryBreakdown

                if !viewModel.largeFiles.isEmpty {
                    largeFilesSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Disk Overview

    private var diskOverview: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label {
                        Text("Macintosh HD")
                            .font(.system(size: 14, weight: .semibold))
                    } icon: {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(String(format: "%.0f GB / %.0f GB",
                                viewModel.systemInfo.diskUsed,
                                viewModel.systemInfo.diskTotal))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geo in
                    let used = viewModel.systemInfo.diskPercentage
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 24)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(storageGradient)
                            .frame(width: max(0, geo.size.width * used), height: 24)
                    }
                }
                .frame(height: 24)

                HStack {
                    Circle()
                        .fill(storageGradient)
                        .frame(width: 8, height: 8)
                    Text("Used")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer().frame(width: 16)
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 8, height: 8)
                    Text("Free — \(String(format: "%.0f GB", viewModel.systemInfo.diskFree))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                Text("Storage Breakdown")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                    .padding(.leading, 4)

                if viewModel.storageCategories.isEmpty {
                    Text("No data yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                        .padding(.leading, 4)
                } else {
                    ForEach(viewModel.storageCategories) { category in
                        Button {
                            let path: String
                            switch category.name {
                            case "Applications": path = "/Applications"
                            case "Documents": path = NSHomeDirectory() + "/Documents"
                            case "Downloads": path = NSHomeDirectory() + "/Downloads"
                            case "Media": path = NSHomeDirectory() + "/Movies"
                            case "Projects": path = NSHomeDirectory() + "/Projects"
                            default: path = NSHomeDirectory() + "/Library"
                            }
                            Task { await viewModel.drillDown(path: path) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(colorFor(category.color))
                                    .frame(width: 24)

                                Text(category.name)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(category.formattedSize)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }

                        if category.id != viewModel.storageCategories.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Large Files

    private var largeFilesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                Text("Large Files")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                    .padding(.leading, 4)

                ForEach(Array(viewModel.largeFiles.enumerated()), id: \.offset) { index, entry in
                    HStack(spacing: 10) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.name)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Text(entry.path)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        Text(ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Button {
                            NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
                        } label: {
                            Image(systemName: "folder")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .help("Reveal in Finder")

                        Button {
                            try? FileManager.default.trashItem(at: URL(fileURLWithPath: entry.path), resultingItemURL: nil)
                            viewModel.largeFiles.removeAll { $0.path == entry.path }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .help("Move to Trash")
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)

                    if index < viewModel.largeFiles.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Drill Down

    private func drillDownView(path: String) -> some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button {
                    viewModel.drillDownPath = nil
                    viewModel.drillDownEntries = []
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                Spacer()

                Text(path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)

            Divider()

            if viewModel.drillDownEntries.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(Array(viewModel.drillDownEntries.enumerated()), id: \.offset) { _, entry in
                    HStack(spacing: 10) {
                        Image(systemName: entry.isDir ? "folder.fill" : "doc.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(entry.isDir ? .blue : .secondary)
                            .frame(width: 22)

                        Text(entry.name)
                            .font(.system(size: 13))
                            .lineLimit(1)

                        Spacer()

                        Text(ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Button {
                            NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
                        } label: {
                            Image(systemName: "folder")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .help("Reveal in Finder")
                    }
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
                        }
                        if entry.isDir {
                            Button("Analyze") {
                                Task { await viewModel.drillDown(path: entry.path) }
                            }
                        }
                        if !entry.isDir {
                            Button("Move to Trash", role: .destructive) {
                                try? FileManager.default.trashItem(at: URL(fileURLWithPath: entry.path), resultingItemURL: nil)
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Helpers

    private var storageGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": .blue
        case "purple": .purple
        case "orange": .orange
        case "gray": .gray
        case "green": .green
        case "cyan": .cyan
        case "pink": .pink
        default: .secondary
        }
    }
}
