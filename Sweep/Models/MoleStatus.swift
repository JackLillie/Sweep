import Foundation

// MARK: - mo status --json

struct MoleStatus: Codable {
    var collectedAt: String
    var host: String
    var platform: String
    var uptime: String
    var procs: Int
    var healthScore: Int
    var healthScoreMsg: String
    var hardware: Hardware
    var cpu: CPU
    var gpu: [GPU]
    var memory: Memory
    var disks: [Disk]
    var diskIo: DiskIO
    var network: [NetworkInterface]
    var proxy: Proxy
    var batteries: [Battery]
    var thermal: Thermal
    var topProcesses: [TopProcess]

    init() {
        collectedAt = ""; host = ""; platform = ""; uptime = ""
        procs = 0; healthScore = 0; healthScoreMsg = ""
        hardware = Hardware(); cpu = CPU(); gpu = []
        memory = Memory(); disks = []; diskIo = DiskIO()
        network = []; proxy = Proxy(); batteries = []
        thermal = Thermal(); topProcesses = []
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        collectedAt = (try? c.decode(String.self, forKey: .collectedAt)) ?? ""
        host = (try? c.decode(String.self, forKey: .host)) ?? ""
        platform = (try? c.decode(String.self, forKey: .platform)) ?? ""
        uptime = (try? c.decode(String.self, forKey: .uptime)) ?? ""
        procs = (try? c.decode(Int.self, forKey: .procs)) ?? 0
        healthScore = (try? c.decode(Int.self, forKey: .healthScore)) ?? 0
        healthScoreMsg = (try? c.decode(String.self, forKey: .healthScoreMsg)) ?? ""
        hardware = (try? c.decode(Hardware.self, forKey: .hardware)) ?? Hardware()
        cpu = (try? c.decode(CPU.self, forKey: .cpu)) ?? CPU()
        gpu = (try? c.decode([GPU].self, forKey: .gpu)) ?? []
        memory = (try? c.decode(Memory.self, forKey: .memory)) ?? Memory()
        disks = (try? c.decode([Disk].self, forKey: .disks)) ?? []
        diskIo = (try? c.decode(DiskIO.self, forKey: .diskIo)) ?? DiskIO()
        network = (try? c.decode([NetworkInterface].self, forKey: .network)) ?? []
        proxy = (try? c.decode(Proxy.self, forKey: .proxy)) ?? Proxy()
        batteries = (try? c.decode([Battery].self, forKey: .batteries)) ?? []
        thermal = (try? c.decode(Thermal.self, forKey: .thermal)) ?? Thermal()
        topProcesses = (try? c.decode([TopProcess].self, forKey: .topProcesses)) ?? []
    }

    // MARK: - Nested Types

    struct Hardware: Codable {
        var model: String
        var cpuModel: String
        var totalRam: String
        var diskSize: String
        var osVersion: String
        var refreshRate: String

        init(model: String = "", cpuModel: String = "", totalRam: String = "",
             diskSize: String = "", osVersion: String = "", refreshRate: String = "") {
            self.model = model; self.cpuModel = cpuModel; self.totalRam = totalRam
            self.diskSize = diskSize; self.osVersion = osVersion; self.refreshRate = refreshRate
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            model = (try? c.decode(String.self, forKey: .model)) ?? ""
            cpuModel = (try? c.decode(String.self, forKey: .cpuModel)) ?? ""
            totalRam = (try? c.decode(String.self, forKey: .totalRam)) ?? ""
            diskSize = (try? c.decode(String.self, forKey: .diskSize)) ?? ""
            osVersion = (try? c.decode(String.self, forKey: .osVersion)) ?? ""
            refreshRate = (try? c.decode(String.self, forKey: .refreshRate)) ?? ""
        }
    }

    struct CPU: Codable {
        var usage: Double
        var perCore: [Double]
        var perCoreEstimated: Bool
        var load1: Double
        var load5: Double
        var load15: Double
        var coreCount: Int
        var logicalCpu: Int
        var pCoreCount: Int
        var eCoreCount: Int

        init(usage: Double = 0, perCore: [Double] = [], perCoreEstimated: Bool = false,
             load1: Double = 0, load5: Double = 0, load15: Double = 0,
             coreCount: Int = 0, logicalCpu: Int = 0, pCoreCount: Int = 0, eCoreCount: Int = 0) {
            self.usage = usage; self.perCore = perCore; self.perCoreEstimated = perCoreEstimated
            self.load1 = load1; self.load5 = load5; self.load15 = load15
            self.coreCount = coreCount; self.logicalCpu = logicalCpu
            self.pCoreCount = pCoreCount; self.eCoreCount = eCoreCount
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            usage = (try? c.decode(Double.self, forKey: .usage)) ?? 0
            perCore = (try? c.decode([Double].self, forKey: .perCore)) ?? []
            perCoreEstimated = (try? c.decode(Bool.self, forKey: .perCoreEstimated)) ?? false
            load1 = (try? c.decode(Double.self, forKey: .load1)) ?? 0
            load5 = (try? c.decode(Double.self, forKey: .load5)) ?? 0
            load15 = (try? c.decode(Double.self, forKey: .load15)) ?? 0
            coreCount = (try? c.decode(Int.self, forKey: .coreCount)) ?? 0
            logicalCpu = (try? c.decode(Int.self, forKey: .logicalCpu)) ?? 0
            pCoreCount = (try? c.decode(Int.self, forKey: .pCoreCount)) ?? 0
            eCoreCount = (try? c.decode(Int.self, forKey: .eCoreCount)) ?? 0
        }
    }

    struct GPU: Codable {
        var name: String
        var usage: Double
        var memoryUsed: Int
        var memoryTotal: Int
        var coreCount: Int
        var note: String

        init(name: String = "", usage: Double = 0, memoryUsed: Int = 0,
             memoryTotal: Int = 0, coreCount: Int = 0, note: String = "") {
            self.name = name; self.usage = usage; self.memoryUsed = memoryUsed
            self.memoryTotal = memoryTotal; self.coreCount = coreCount; self.note = note
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = (try? c.decode(String.self, forKey: .name)) ?? ""
            usage = (try? c.decode(Double.self, forKey: .usage)) ?? 0
            memoryUsed = (try? c.decode(Int.self, forKey: .memoryUsed)) ?? 0
            memoryTotal = (try? c.decode(Int.self, forKey: .memoryTotal)) ?? 0
            coreCount = (try? c.decode(Int.self, forKey: .coreCount)) ?? 0
            note = (try? c.decode(String.self, forKey: .note)) ?? ""
        }
    }

    struct Memory: Codable {
        var used: Int64
        var total: Int64
        var usedPercent: Double
        var swapUsed: Int64
        var swapTotal: Int64
        var cached: Int64
        var pressure: String

        init(used: Int64 = 0, total: Int64 = 0, usedPercent: Double = 0,
             swapUsed: Int64 = 0, swapTotal: Int64 = 0, cached: Int64 = 0, pressure: String = "") {
            self.used = used; self.total = total; self.usedPercent = usedPercent
            self.swapUsed = swapUsed; self.swapTotal = swapTotal
            self.cached = cached; self.pressure = pressure
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            used = (try? c.decode(Int64.self, forKey: .used)) ?? 0
            total = (try? c.decode(Int64.self, forKey: .total)) ?? 0
            usedPercent = (try? c.decode(Double.self, forKey: .usedPercent)) ?? 0
            swapUsed = (try? c.decode(Int64.self, forKey: .swapUsed)) ?? 0
            swapTotal = (try? c.decode(Int64.self, forKey: .swapTotal)) ?? 0
            cached = (try? c.decode(Int64.self, forKey: .cached)) ?? 0
            pressure = (try? c.decode(String.self, forKey: .pressure)) ?? ""
        }
    }

    struct Disk: Codable {
        var mount: String
        var device: String
        var used: Int64
        var total: Int64
        var usedPercent: Double
        var fstype: String
        var external: Bool

        init(mount: String = "", device: String = "", used: Int64 = 0, total: Int64 = 0,
             usedPercent: Double = 0, fstype: String = "", external: Bool = false) {
            self.mount = mount; self.device = device; self.used = used; self.total = total
            self.usedPercent = usedPercent; self.fstype = fstype; self.external = external
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            mount = (try? c.decode(String.self, forKey: .mount)) ?? ""
            device = (try? c.decode(String.self, forKey: .device)) ?? ""
            used = (try? c.decode(Int64.self, forKey: .used)) ?? 0
            total = (try? c.decode(Int64.self, forKey: .total)) ?? 0
            usedPercent = (try? c.decode(Double.self, forKey: .usedPercent)) ?? 0
            fstype = (try? c.decode(String.self, forKey: .fstype)) ?? ""
            external = (try? c.decode(Bool.self, forKey: .external)) ?? false
        }
    }

    struct DiskIO: Codable {
        var readRate: Double
        var writeRate: Double

        init(readRate: Double = 0, writeRate: Double = 0) {
            self.readRate = readRate; self.writeRate = writeRate
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            readRate = (try? c.decode(Double.self, forKey: .readRate)) ?? 0
            writeRate = (try? c.decode(Double.self, forKey: .writeRate)) ?? 0
        }
    }

    struct NetworkInterface: Codable {
        var name: String
        var rxRateMbs: Double
        var txRateMbs: Double
        var ip: String

        init(name: String = "", rxRateMbs: Double = 0, txRateMbs: Double = 0, ip: String = "") {
            self.name = name; self.rxRateMbs = rxRateMbs; self.txRateMbs = txRateMbs; self.ip = ip
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = (try? c.decode(String.self, forKey: .name)) ?? ""
            rxRateMbs = (try? c.decode(Double.self, forKey: .rxRateMbs)) ?? 0
            txRateMbs = (try? c.decode(Double.self, forKey: .txRateMbs)) ?? 0
            ip = (try? c.decode(String.self, forKey: .ip)) ?? ""
        }
    }

    struct Proxy: Codable {
        var enabled: Bool
        var type: String
        var host: String

        init(enabled: Bool = false, type: String = "", host: String = "") {
            self.enabled = enabled; self.type = type; self.host = host
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? false
            type = (try? c.decode(String.self, forKey: .type)) ?? ""
            host = (try? c.decode(String.self, forKey: .host)) ?? ""
        }
    }

    struct Battery: Codable {
        var percent: Double
        var status: String
        var timeLeft: String
        var health: String
        var cycleCount: Int
        var capacity: Int

        init(percent: Double = 0, status: String = "", timeLeft: String = "",
             health: String = "", cycleCount: Int = 0, capacity: Int = 0) {
            self.percent = percent; self.status = status; self.timeLeft = timeLeft
            self.health = health; self.cycleCount = cycleCount; self.capacity = capacity
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            percent = (try? c.decode(Double.self, forKey: .percent)) ?? 0
            status = (try? c.decode(String.self, forKey: .status)) ?? ""
            timeLeft = (try? c.decode(String.self, forKey: .timeLeft)) ?? ""
            health = (try? c.decode(String.self, forKey: .health)) ?? ""
            cycleCount = (try? c.decode(Int.self, forKey: .cycleCount)) ?? 0
            capacity = (try? c.decode(Int.self, forKey: .capacity)) ?? 0
        }
    }

    struct Thermal: Codable {
        var cpuTemp: Double
        var gpuTemp: Double
        var fanSpeed: Int
        var fanCount: Int
        var systemPower: Double
        var adapterPower: Double
        var batteryPower: Double

        init(cpuTemp: Double = 0, gpuTemp: Double = 0, fanSpeed: Int = 0, fanCount: Int = 0,
             systemPower: Double = 0, adapterPower: Double = 0, batteryPower: Double = 0) {
            self.cpuTemp = cpuTemp; self.gpuTemp = gpuTemp
            self.fanSpeed = fanSpeed; self.fanCount = fanCount
            self.systemPower = systemPower; self.adapterPower = adapterPower; self.batteryPower = batteryPower
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            cpuTemp = (try? c.decode(Double.self, forKey: .cpuTemp)) ?? 0
            gpuTemp = (try? c.decode(Double.self, forKey: .gpuTemp)) ?? 0
            fanSpeed = (try? c.decode(Int.self, forKey: .fanSpeed)) ?? 0
            fanCount = (try? c.decode(Int.self, forKey: .fanCount)) ?? 0
            systemPower = (try? c.decode(Double.self, forKey: .systemPower)) ?? 0
            adapterPower = (try? c.decode(Double.self, forKey: .adapterPower)) ?? 0
            batteryPower = (try? c.decode(Double.self, forKey: .batteryPower)) ?? 0
        }
    }

    struct TopProcess: Codable {
        var name: String
        var cpu: Double
        var memory: Int64

        init(name: String = "", cpu: Double = 0, memory: Int64 = 0) {
            self.name = name; self.cpu = cpu; self.memory = memory
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = (try? c.decode(String.self, forKey: .name)) ?? ""
            cpu = (try? c.decode(Double.self, forKey: .cpu)) ?? 0
            memory = (try? c.decode(Int64.self, forKey: .memory)) ?? 0
        }
    }
}

// MARK: - mo analyze --json

struct MoleAnalysis: Codable {
    var path: String
    var entries: [Entry]
    var totalSize: Int64
    var totalFiles: Int

    init(path: String = "", entries: [Entry] = [], totalSize: Int64 = 0, totalFiles: Int = 0) {
        self.path = path; self.entries = entries; self.totalSize = totalSize; self.totalFiles = totalFiles
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = (try? c.decode(String.self, forKey: .path)) ?? ""
        entries = (try? c.decode([Entry].self, forKey: .entries)) ?? []
        totalSize = (try? c.decode(Int64.self, forKey: .totalSize)) ?? 0
        totalFiles = (try? c.decode(Int.self, forKey: .totalFiles)) ?? 0
    }

    struct Entry: Codable {
        var name: String
        var path: String
        var size: Int64
        var isDir: Bool

        init(name: String = "", path: String = "", size: Int64 = 0, isDir: Bool = false) {
            self.name = name; self.path = path; self.size = size; self.isDir = isDir
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = (try? c.decode(String.self, forKey: .name)) ?? ""
            path = (try? c.decode(String.self, forKey: .path)) ?? ""
            size = (try? c.decode(Int64.self, forKey: .size)) ?? 0
            isDir = (try? c.decode(Bool.self, forKey: .isDir)) ?? false
        }
    }
}
