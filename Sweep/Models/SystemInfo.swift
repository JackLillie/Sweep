import Foundation
import SwiftUI

struct SystemInfo {
    var hostname: String = ""
    var macModel: String = ""
    var osVersion: String = ""
    var cpuUsage: Double = 0
    var memoryUsed: Double = 0
    var memoryTotal: Double = 0
    var diskUsed: Double = 0
    var diskTotal: Double = 0
    var uptimeDays: Int = 0
    var uptimeHours: Int = 0
    var uptime: String = ""
    var healthScore: Int = 0
    var healthScoreMsg: String = ""
    var networkDown: Double = 0
    var networkUp: Double = 0
    var batteryPercent: Double = 0
    var batteryStatus: String = ""
    var hasBattery: Bool = false
    var cpuTemp: Double = 0

    var memoryPercentage: Double {
        guard memoryTotal > 0 else { return 0 }
        return memoryUsed / memoryTotal
    }

    var diskPercentage: Double {
        guard diskTotal > 0 else { return 0 }
        return diskUsed / diskTotal
    }

    var diskFree: Double {
        diskTotal - diskUsed
    }

    init() {}

    init(from status: MoleStatus) {
        hostname = status.host.replacingOccurrences(of: ".local", with: "")
        macModel = status.hardware.model
        osVersion = status.hardware.osVersion
        uptime = status.uptime
        healthScore = status.healthScore
        healthScoreMsg = status.healthScoreMsg

        // CPU: mole gives 0-100, views use 0-1
        cpuUsage = status.cpu.usage / 100.0

        // Memory: mole gives bytes, views use GB
        memoryUsed = Double(status.memory.used) / 1_073_741_824
        memoryTotal = Double(status.memory.total) / 1_073_741_824

        // Disk: use first non-external disk
        if let disk = status.disks.first(where: { !$0.external }) ?? status.disks.first {
            diskUsed = Double(disk.used) / 1_000_000_000
            diskTotal = Double(disk.total) / 1_000_000_000
        }

        // Parse uptime string (e.g. "3d 12h 45m") into days/hours
        let parts = status.uptime.components(separatedBy: " ")
        for part in parts {
            if part.hasSuffix("d"), let n = Int(part.dropLast()) { uptimeDays = n }
            if part.hasSuffix("h"), let n = Int(part.dropLast()) { uptimeHours = n }
        }

        // Network: sum all interfaces
        networkDown = status.network.reduce(0) { $0 + $1.rxRateMbs }
        networkUp = status.network.reduce(0) { $0 + $1.txRateMbs }

        // Battery
        if let battery = status.batteries.first {
            hasBattery = true
            batteryPercent = battery.percent
            batteryStatus = battery.status
        }

        cpuTemp = status.thermal.cpuTemp
    }
}

// MARK: - Mole Clean Scan Result

struct CleanSection: Identifiable {
    let id = UUID()
    let name: String
    var items: [CleanItem] = []
    var isSelected: Bool = true

    var totalSize: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var formattedSize: String { ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file) }

    var icon: String {
        switch name.lowercased() {
        case let n where n.contains("user"): return "person.circle"
        case let n where n.contains("app cache"): return "square.stack.3d.up"
        case let n where n.contains("browser"): return "globe"
        case let n where n.contains("cloud"): return "cloud"
        case let n where n.contains("developer"): return "hammer"
        case let n where n.contains("application"): return "app"
        case let n where n.contains("virtual"): return "desktopcomputer"
        case let n where n.contains("orphan"): return "trash.circle"
        case let n where n.contains("backup"): return "externaldrive"
        case let n where n.contains("time machine"): return "clock.arrow.circlepath"
        case let n where n.contains("large"): return "doc.richtext"
        case let n where n.contains("system"): return "gearshape"
        case let n where n.contains("project"): return "folder"
        case let n where n.contains("support"): return "wrench"
        default: return "folder.badge.gearshape"
        }
    }

    var color: Color {
        switch name.lowercased() {
        case let n where n.contains("user"): return .purple
        case let n where n.contains("browser"): return .blue
        case let n where n.contains("developer"): return .orange
        case let n where n.contains("application"): return .indigo
        case let n where n.contains("orphan"): return .red
        case let n where n.contains("cloud"): return .cyan
        default: return .secondary
        }
    }
}

struct CleanItem: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let sizeText: String
    var isSelected: Bool = true

    var formattedSize: String {
        size > 0 ? ByteCountFormatter.string(fromByteCount: size, countStyle: .file) : sizeText
    }
}

struct CleanSummary {
    var totalSize: String = ""
    var itemCount: Int = 0
    var categoryCount: Int = 0
}

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let size: Int64
    let path: String
    let lastOpened: Date?

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var daysSinceLastOpened: Int? {
        guard let lastOpened else { return nil }
        return Calendar.current.dateComponents([.day], from: lastOpened, to: Date()).day
    }
}

struct StorageCategory: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let color: String
    let icon: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct PermissionEntry: Identifiable {
    let id = UUID()
    let appName: String
    let permission: String
    let granted: Bool
    let icon: String
}
