import SwiftUI

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .overview
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        Group {
            if viewModel.moleAvailable {
                NavigationSplitView {
                    SidebarView(selection: $selectedItem)
                } detail: {
                    Group {
                        switch selectedItem {
                        case .overview:
                            OverviewView(viewModel: viewModel)
                        case .smartClean:
                            SmartCleanView(viewModel: viewModel)
                        case .applications:
                            ApplicationsView(viewModel: viewModel)
                        case .storage:
                            StorageView(viewModel: viewModel)
                        case .permissions:
                            PermissionsView(viewModel: viewModel)
                        case nil:
                            OverviewView(viewModel: viewModel)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentMargins(.top, 0, for: .scrollContent)
                }
            } else {
                MoleNotFoundView {
                    Task { await viewModel.recheckMole() }
                }
            }
        }
        .task {
            await viewModel.checkMoleAvailability()
            if viewModel.moleAvailable {
                await viewModel.loadSystemInfo()
            }
        }
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var systemInfo = SystemInfo()
    @Published var cleanSections: [CleanSection] = []
    @Published var cleanSummary = CleanSummary()
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var cleanResult: String?
    @Published var diskFreeBefore: Double = 0
    @Published var isLoading = true
    @Published var moleAvailable = true
    @Published var cleanPermissionsChecked = false
    @Published var hasScanned = false

    private let bridge = MoleBridge()

    func checkMoleAvailability() async {
        moleAvailable = await bridge.isAvailable
    }

    func recheckMole() async {
        moleAvailable = await bridge.recheckAvailability()
    }

    func loadSystemInfo() async {
        let status = await bridge.fetchStatus()
        systemInfo = SystemInfo(from: status)
        isLoading = false
    }

    @Published var scanActivity = ""
    private var scanTask: Task<Void, Never>?

    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
        scanActivity = ""
    }

    func scanForCleanables() async {
        isScanning = true
        diskFreeBefore = systemInfo.diskFree
        scanActivity = "Starting scan..."

        let (sections, summary) = await bridge.scanForCleanablesStreaming { [weak self] liveSections, liveSummary, activity in
            Task { @MainActor in
                self?.cleanSections = liveSections
                self?.cleanSummary = liveSummary
                self?.scanActivity = activity
            }
        }

        cleanSections = sections
        cleanSummary = summary
        isScanning = false
    }

    func runClean() async {
        isCleaning = true
        do {
            let result = try await bridge.runClean()
            cleanResult = result
            cleanSections = []
            cleanSummary = CleanSummary()
            // Refresh system info to show updated disk space
            await loadSystemInfo()
        } catch {
            actionError = error.localizedDescription
        }
        isCleaning = false
    }

    @Published var actionError: String?

    func emptyTrash() async {
        do {
            try await bridge.emptyTrash()
        } catch {
            actionError = error.localizedDescription
        }
    }

    func flushDNS() async {
        do {
            try await bridge.flushDNS()
        } catch {
            actionError = error.localizedDescription
        }
    }

    func freeMemory() async {
        do {
            try await bridge.freeMemory()
        } catch {
            actionError = error.localizedDescription
        }
    }

    var totalCleanableSize: Int64 {
        cleanSections.reduce(0) { $0 + $1.totalSize }
    }

    var formattedCleanableSize: String {
        ByteCountFormatter.string(fromByteCount: totalCleanableSize, countStyle: .file)
    }

    var hasCleanableItems: Bool {
        !cleanSections.isEmpty
    }

    // MARK: - Applications
    @Published var apps: [AppInfo] = []
    @Published var isLoadingApps = false
    @Published var appsScanned = false

    // MARK: - Storage
    @Published var storageCategories: [StorageCategory] = []
    @Published var largeFiles: [MoleAnalysis.Entry] = []
    @Published var isLoadingStorage = false
    @Published var storageScanned = false
    @Published var storageActivity = "Starting analysis..."
    @Published var drillDownEntries: [MoleAnalysis.Entry] = []
    @Published var drillDownPath: String?

    func loadStorage() async {
        isLoadingStorage = true
        storageCategories = []
        largeFiles = []

        // Analyze /Applications
        storageActivity = "Analyzing Applications..."
        if let appsAnalysis = try? await bridge.analyze(path: "/Applications") {
            let appsSize = appsAnalysis.entries.reduce(Int64(0)) { $0 + $1.size }
            if appsSize > 0 {
                storageCategories.append(StorageCategory(name: "Applications", size: appsSize, color: "blue", icon: "app.fill"))
                storageCategories.sort { $0.size > $1.size }
            }
        }

        // Analyze home directory
        storageActivity = "Analyzing home directory..."
        let analysis = try? await bridge.analyze(path: NSHomeDirectory())

        if let entries = analysis?.entries {
            // Developer & Libraries
            storageActivity = "Calculating Developer & Libraries..."
            let devNames: Set = ["Library", ".local", ".cargo", ".rustup", ".npm", ".cache", ".gradle", ".m2"]
            let devSize = entries.filter { devNames.contains($0.name) }.reduce(Int64(0)) { $0 + $1.size }
            if devSize > 0 {
                storageCategories.append(StorageCategory(name: "Developer & Libraries", size: devSize, color: "purple", icon: "hammer.fill"))
                storageCategories.sort { $0.size > $1.size }
            }

            // Documents + Desktop
            storageActivity = "Calculating Documents..."
            let docsSize = entries.filter { $0.name == "Documents" || $0.name == "Desktop" }.reduce(Int64(0)) { $0 + $1.size }
            if docsSize > 0 {
                storageCategories.append(StorageCategory(name: "Documents", size: docsSize, color: "orange", icon: "doc.fill"))
                storageCategories.sort { $0.size > $1.size }
            }

            // Downloads
            storageActivity = "Calculating Downloads..."
            let downloadsSize = entries.first(where: { $0.name == "Downloads" })?.size ?? 0
            if downloadsSize > 0 {
                storageCategories.append(StorageCategory(name: "Downloads", size: downloadsSize, color: "cyan", icon: "arrow.down.circle.fill"))
                storageCategories.sort { $0.size > $1.size }
            }

            // Media
            storageActivity = "Calculating Media..."
            let mediaSize = entries.filter { $0.name == "Movies" || $0.name == "Music" || $0.name == "Pictures" }.reduce(Int64(0)) { $0 + $1.size }
            if mediaSize > 0 {
                storageCategories.append(StorageCategory(name: "Media", size: mediaSize, color: "pink", icon: "photo.fill"))
                storageCategories.sort { $0.size > $1.size }
            }

            // Projects
            storageActivity = "Calculating Projects..."
            let projNames: Set = ["Projects", "Developer", "GitHub", "dev", "repos"]
            let projectsSize = entries.filter { projNames.contains($0.name) }.reduce(Int64(0)) { $0 + $1.size }
            if projectsSize > 0 {
                storageCategories.append(StorageCategory(name: "Projects", size: projectsSize, color: "green", icon: "folder.fill"))
                storageCategories.sort { $0.size > $1.size }
            }

            // Large files
            storageActivity = "Finding large files..."
            largeFiles = entries.filter { !$0.isDir && $0.size > 100_000_000 }
                .sorted { $0.size > $1.size }
                .prefix(20)
                .map { $0 }
        }

        isLoadingStorage = false
        storageScanned = true
    }

    func drillDown(path: String) async {
        drillDownPath = path
        drillDownEntries = []
        if let analysis = try? await bridge.analyze(path: path) {
            drillDownEntries = analysis.entries.sorted { $0.size > $1.size }
        }
    }
}
