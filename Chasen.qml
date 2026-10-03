import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// The alerts of your Chasen servers in the bar. It runs `chasen alerts
// --waybar`, which asks every server you are logged in to and prints one
// line of JSON: the count, the alerts server by server, and a class (error,
// warning, or nothing). The icon is dim when all is well, normal with a
// warning, and urgent with an error. A click opens the screen of chasen.
BarWidget {
  id: root
  moduleName: "karloscodes.chasen"

  property string level: ""        // "error", "warning", or "" when all is well
  property string summary: "Asking your servers..."
  property bool installed: true

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)

  function refresh() {
    if (!alerts.running) alerts.running = true
  }

  function read(text) {
    try {
      var line = JSON.parse(String(text || "").trim())
      root.level = line["class"] || ""
      root.summary = (line.text ? line.text.replace("●", "").trim() + " alerts\n" : "") + (line.tooltip || "No alerts")
    } catch (e) {
      root.level = "warning"
      root.summary = "chasen did not answer. Update it: chasen update"
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  ShellIpc {
    target: "karloscodes.chasen"

    function refresh(): void {
      root.broadcast("refresh")
    }
  }

  Process {
    id: alerts
    running: false
    command: ["chasen", "alerts", "--waybar"]
    stdout: StdioCollector { id: alertsOut; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 127) {
        root.installed = false
        root.level = "warning"
        root.summary = "Chasen is not installed: curl -fsSL https://chasenhq.com/cli | sh"
        return
      }
      root.installed = true
      root.read(alertsOut.text)
    }
  }

  Timer {
    interval: Math.max(30, root.setting("refreshIntervalSec", 60)) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.summary
    iconComponent: Component {
      Item {
        Text {
          anchors.centerIn: parent
          text: ""
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.bar.iconFont
          color: root.level === "error" ? root.urgent : (root.level === "warning" ? root.foreground : root.dim)
        }
      }
    }
    onPressed: {
      if (root.bar) root.bar.run(root.installed ? "omarchy-launch-tui chasen" : "xdg-open https://chasenhq.com/docs/omarchy/")
    }
  }
}
