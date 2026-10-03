import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Your Chasen servers in the bar. It runs `chasen overview --json`, which asks
// every server you are logged in to and prints each one with its apps, their
// state, the change that runs now, and the alerts of the server.
//
// The icon turns while a deploy runs. It is urgent when an app is down or a
// server has an error, normal with a warning, and dim when all is well. A
// click opens the tree: each server, its alerts, and its apps.
Panel {
  id: root
  moduleName: "karloscodes.chasen"
  ipcTarget: "karloscodes.chasen"

  property var servers: []
  property int running: 0
  property int down: 0
  property int errors: 0
  property int warnings: 0
  property bool loaded: false
  property string problem: ""   // why chasen did not answer

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool broken: down > 0 || errors > 0
  readonly property color barIconColor: broken ? urgent : (running > 0 || warnings > 0 ? barForeground : Qt.darker(barForeground, 1.55))

  function refresh() {
    if (!overview.running) overview.running = true
  }

  function read(text) {
    try {
      var all = JSON.parse(String(text || "").trim())
      root.servers = all.servers || []
      root.running = all.running || 0
      root.down = all.down || 0
      root.errors = all.errors || 0
      root.warnings = all.warnings || 0
      root.problem = ""
    } catch (e) {
      root.problem = "chasen did not answer. Update it: chasen update"
    }
    root.loaded = true
  }

  function summary() {
    if (root.problem !== "") return root.problem
    if (!root.loaded) return "Asking your servers..."
    var parts = []
    if (root.running > 0) parts.push(root.running + " running")
    if (root.down > 0) parts.push(root.down + " down")
    if (root.errors > 0) parts.push(root.errors + (root.errors === 1 ? " error" : " errors"))
    if (root.warnings > 0) parts.push(root.warnings + (root.warnings === 1 ? " warning" : " warnings"))
    return parts.length > 0 ? parts.join(" · ") : "All is well"
  }

  function openScreen() {
    root.close()
    if (root.bar) root.bar.run("omarchy-launch-tui chasen")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: overview
    running: false
    command: ["chasen", "overview", "--json"]
    stdout: StdioCollector { id: overviewOut; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 127) {
        root.problem = "Chasen is not installed: curl -fsSL https://chasenhq.com/cli | sh"
        root.loaded = true
        return
      }
      root.read(overviewOut.text)
    }
  }

  // Every 10 seconds while a deploy runs or the tree is open, else at the
  // interval of the settings.
  Timer {
    interval: (root.running > 0 || root.opened ? 10 : Math.max(30, root.setting("refreshIntervalSec", 60))) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "Chasen: " + root.summary()
    iconComponent: Component {
      Item {
        Text {
          id: glyph
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.running > 0 ? "" : ""
          font.family: root.fontFamily
          font.pixelSize: Style.bar.iconFont
          color: root.barIconColor
          RotationAnimator on rotation {
            running: root.running > 0
            from: 0
            to: 360
            duration: 1400
            loops: Animation.Infinite
          }
          onTextChanged: if (root.running === 0) rotation = 0
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) root.openScreen()
      else if (buttonCode === Qt.RightButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: root.openScreen()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refresh()
      }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(12)

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: "Chasen"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.summary()
            color: root.broken ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Repeater {
            model: root.servers

            Column {
              id: serverBlock
              required property var modelData
              width: column.width
              spacing: Style.space(6)

              PanelSeparator { foreground: root.foreground }

              PanelSectionHeader {
                text: serverBlock.modelData.name
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Text {
                textFormat: Text.PlainText
                visible: !!serverBlock.modelData.error
                width: parent.width
                text: "Does not answer: " + (serverBlock.modelData.error || "")
                color: root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }

              Repeater {
                model: serverBlock.modelData.alerts || []
                Text {
                  required property var modelData
                  textFormat: Text.PlainText
                  width: serverBlock.width
                  text: (modelData.error ? "✗  " : "!  ") + modelData.what
                  color: modelData.error ? root.urgent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.WordWrap
                }
              }

              Repeater {
                model: serverBlock.modelData.apps || []

                Item {
                  id: appRow
                  required property var modelData
                  width: serverBlock.width
                  implicitHeight: Math.max(name.implicitHeight, now.implicitHeight) + Style.space(4)

                  Text {
                    id: dot
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: appRow.modelData.running ? "" : (appRow.modelData.up ? "●" : "✗")
                    color: appRow.modelData.up ? (appRow.modelData.running ? root.foreground : root.dim) : root.urgent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    RotationAnimator on rotation {
                      running: !!appRow.modelData.running
                      from: 0
                      to: 360
                      duration: 1400
                      loops: Animation.Infinite
                    }
                  }

                  Text {
                    id: name
                    anchors.left: dot.right
                    anchors.leftMargin: Style.space(8)
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: appRow.modelData.app
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }

                  Text {
                    id: now
                    anchors.right: parent.right
                    anchors.left: name.right
                    anchors.leftMargin: Style.space(12)
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: appRow.modelData.running ? appRow.modelData.running + "…"
                        : (appRow.modelData.up ? appRow.modelData.version : appRow.modelData.state)
                    color: appRow.modelData.up ? root.dim : root.urgent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openScreen()
                  }
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: root.loaded && root.servers.length === 0 && root.problem === ""
            width: parent.width
            text: "No server yet. Add one: chasen add server root@203.0.113.5"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: "Enter or a click opens the screen · r asks again · Esc closes"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
