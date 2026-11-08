import QtQuick
import Quickshell
import Quickshell.Io
import "resources.js" as Resources

// Readings for the resource widgets, taken only while `running`: CPU and
// memory from /proc every 2 seconds, the GPU (AMD through sysfs, NVIDIA
// through nvidia-smi; others give no reading) as often, the disk of your
// home folder every minute.
Scope {
    id: monitor

    property bool running: false
    property bool wantGpu: true
    property bool wantDisk: true
    property var cpu: ({ usage: 0, cores: 0 })
    property var ram: ({ used: 0, total: 0 })
    property var disk: ({ used: 0, total: 0 })
    property var gpu: ({ usage: 0, used: 0, total: 0, name: "" })
    property var lastCpu: null
    property string gpuKind: ""      // "amd", "nvidia", "none" once looked for
    property string amdDevice: ""    // /sys/class/drm/cardN/device

    FileView {
        id: stat
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const sample = Resources.cpuSample(text());
            monitor.cpu = { usage: monitor.lastCpu ? Resources.cpuUsage(monitor.lastCpu, sample) : 0, cores: sample.cores };
            monitor.lastCpu = sample;
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: monitor.ram = Resources.memory(text())
    }

    // AMD: busy percentage and video memory, plain files of the driver.
    FileView {
        id: amdBusy
        path: monitor.amdDevice ? monitor.amdDevice + "/gpu_busy_percent" : ""
        printErrors: false
        onLoaded: monitor.gpu = Object.assign({}, monitor.gpu, { usage: parseInt(text()) / 100 || 0, name: "AMD" })
    }
    FileView {
        id: amdUsed
        path: monitor.amdDevice ? monitor.amdDevice + "/mem_info_vram_used" : ""
        printErrors: false
        onLoaded: monitor.gpu = Object.assign({}, monitor.gpu, { used: parseInt(text()) || 0 })
    }
    FileView {
        id: amdTotal
        path: monitor.amdDevice ? monitor.amdDevice + "/mem_info_vram_total" : ""
        printErrors: false
        onLoaded: monitor.gpu = Object.assign({}, monitor.gpu, { total: parseInt(text()) || 0 })
    }
    Process {
        id: nvidia
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: monitor.gpu = Object.assign({ name: "NVIDIA" }, Resources.nvidia(text))
        }
    }
    // Which GPU can be read, looked for once.
    Process {
        running: monitor.running && monitor.wantGpu && monitor.gpuKind === ""
        command: ["sh", "-c", "for f in /sys/class/drm/card*/device/gpu_busy_percent; do "
            + "[ -r \"$f\" ] && { echo \"amd ${f%/gpu_busy_percent}\"; exit 0; }; done; "
            + "command -v nvidia-smi >/dev/null 2>&1 && echo nvidia || echo none"]
        stdout: StdioCollector {
            onStreamFinished: {
                const words = text.trim().split(" ");
                monitor.amdDevice = words[0] === "amd" ? words.slice(1).join(" ") : "";
                monitor.gpuKind = words[0] || "none";
            }
        }
    }
    Process {
        id: df
        command: ["df", "-P", "-B1", Quickshell.env("HOME") || "/"]
        stdout: StdioCollector {
            onStreamFinished: monitor.disk = Resources.disk(text)
        }
    }

    Timer {
        running: monitor.running
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (!monitor.wantGpu)
                return;
            if (monitor.gpuKind === "amd") {
                amdBusy.reload();
                amdUsed.reload();
                amdTotal.reload();
            } else if (monitor.gpuKind === "nvidia" && !nvidia.running) {
                nvidia.running = true;
            }
        }
    }
    Timer {
        running: monitor.running && monitor.wantDisk
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }
}
