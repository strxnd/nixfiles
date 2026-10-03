pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Colors.js" as Colors

PopupWindow {
    id: popup
    required property var panel
    required property Item anchorItem
    readonly property string outputName: panel.screen.name
    readonly property var scalePresets: ["1", "1.25", "1.6", "2", "3", "4"]
    property var display: null
    property int brightnessPercent: 50
    property bool brightnessAvailable: false
    property bool brightnessQueued: false
    property string error: ""
    readonly property var currentMode: display?.modes?.find(mode => mode.current) ?? null

    function refresh() {
        if (!visible || stateProcess.running || scaleProcess.running)
            return;
        stateProcess.running = true;
    }

    function refreshBrightness() {
        if (!visible || brightnessReadProcess.running || brightnessSetProcess.running || brightnessDebounce.running || brightnessQueued)
            return;
        brightnessReadProcess.command = ["display-control", "brightness-read", outputName];
        brightnessReadProcess.running = true;
    }

    function setScale(value) {
        if (scaleProcess.running || !display?.enabled)
            return;
        error = "";
        scaleProcess.command = ["display-control", "scale", outputName, value];
        scaleProcess.running = true;
    }

    function setBrightness() {
        if (!brightnessAvailable)
            return;
        if (brightnessSetProcess.running) {
            brightnessQueued = true;
            return;
        }
        error = "";
        brightnessQueued = false;
        brightnessSetProcess.command = ["display-control", "brightness", outputName, String(brightnessPercent)];
        brightnessSetProcess.running = true;
    }

    anchor.item: anchorItem
    anchor.rect.y: anchorItem.height + 6
    implicitWidth: 380
    implicitHeight: menuContent.implicitHeight + 127
    grabFocus: true
    color: Colors.background

    onVisibleChanged: {
        if (visible) {
            error = "";
            refresh();
            refreshBrightness();
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: popup.visible
        onTriggered: {
            popup.refresh();
            if (!brightnessSlider.pressed)
                popup.refreshBrightness();
        }
    }

    Timer {
        id: brightnessDebounce
        interval: 180
        onTriggered: popup.setBrightness()
    }

    Process {
        id: stateProcess
        command: ["wlr-randr", "--json"]
        stdout: StdioCollector {
            id: stateOutput
        }
        stderr: StdioCollector {
            id: stateError
        }
        onExited: code => {
            if (code !== 0) {
                popup.error = stateError.text.trim() || "Could not read display settings";
                return;
            }
            try {
                popup.display = JSON.parse(stateOutput.text).find(output => output.name === popup.outputName) ?? null;
            } catch (error) {
                popup.error = "Could not read display settings";
            }
        }
    }

    Process {
        id: scaleProcess
        stderr: StdioCollector {
            id: scaleError
        }
        onExited: code => {
            if (code !== 0)
                popup.error = scaleError.text.trim() || "Could not change scale";
            popup.refresh();
        }
    }

    Process {
        id: brightnessReadProcess
        stdout: StdioCollector {
            id: brightnessOutput
        }
        onExited: code => {
            try {
                const value = code === 0 ? JSON.parse(brightnessOutput.text).brightness : null;
                popup.brightnessAvailable = value !== null;
                if (value !== null)
                    popup.brightnessPercent = value;
            } catch (error) {
                popup.brightnessAvailable = false;
            }
        }
    }

    Process {
        id: brightnessSetProcess
        stderr: StdioCollector {
            id: brightnessError
        }
        onExited: code => {
            if (code !== 0) {
                popup.error = brightnessError.text.trim() || "Could not change brightness";
                popup.brightnessQueued = false;
                popup.refreshBrightness();
            } else if (popup.brightnessQueued) {
                popup.setBrightness();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: Colors.accent
    }

    Item {
        id: hero
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 19
        height: 48

        Text {
            id: heroIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Quickshell.screens.length > 1 ? "󰍺" : "󰍹"
            color: Colors.foreground
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 30
        }

        Column {
            anchors.left: heroIcon.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: "Display"
                color: Colors.foreground
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 22
                font.bold: true
            }
            Text {
                width: parent.width
                text: popup.currentMode ? popup.outputName + " · " + popup.currentMode.width + "×" + popup.currentMode.height + " · " + popup.currentMode.refresh.toFixed(2) + " Hz" : popup.outputName
                elide: Text.ElideRight
                color: Colors.foregroundDim
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 13
            }
        }
    }

    Rectangle {
        id: heroDivider
        anchors.left: hero.left
        anchors.right: hero.right
        anchors.top: hero.bottom
        anchors.topMargin: 14
        height: 1
        color: Colors.border
    }

    Column {
        id: menuContent
        anchors.top: heroDivider.bottom
        anchors.topMargin: 26
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 19
        anchors.rightMargin: 19
        spacing: 13

        Column {
            visible: popup.brightnessAvailable
            width: parent.width
            spacing: 10

            Item {
                width: parent.width
                height: 20

                Text {
                    text: "BRIGHTNESS"
                    color: Colors.foregroundDim
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                Text {
                    anchors.right: parent.right
                    text: popup.brightnessPercent + "%"
                    color: Colors.foregroundDim
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 15
                }
            }

            Slider {
                id: brightnessSlider
                width: parent.width
                height: 32
                leftPadding: 0
                rightPadding: 0
                from: 1
                to: 100
                stepSize: 1
                value: popup.brightnessPercent
                enabled: !brightnessReadProcess.running
                onMoved: {
                    popup.brightnessPercent = Math.round(value);
                    brightnessDebounce.restart();
                }
                onPressedChanged: {
                    if (!pressed) {
                        brightnessDebounce.stop();
                        popup.setBrightness();
                    }
                }
                background: Rectangle {
                    x: brightnessSlider.leftPadding
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: brightnessSlider.availableWidth
                    height: 6
                    color: Colors.border
                    Rectangle {
                        width: Math.max(0, brightnessHandle.x - parent.x - 4)
                        height: parent.height
                        color: Colors.foreground
                    }
                }
                handle: Rectangle {
                    id: brightnessHandle
                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: 20
                    height: 20
                    color: Colors.foreground
                }
            }
        }

        Text {
            visible: !popup.brightnessAvailable
            width: parent.width
            text: brightnessReadProcess.running ? "Checking brightness control…" : "Brightness control unavailable"
            color: Colors.muted
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 14
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.border
        }

        Text {
            text: "SCALE"
            color: Colors.foregroundDim
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 15
            font.bold: true
            font.letterSpacing: 1.2
        }

        Row {
            id: scaleRow
            width: parent.width
            spacing: 5

            Repeater {
                model: popup.scalePresets

                Rectangle {
                    id: preset
                    required property string modelData
                    readonly property bool active: !!popup.display && Math.abs(popup.display.scale - Number(modelData)) < 0.005
                    width: (scaleRow.width - scaleRow.spacing * (popup.scalePresets.length - 1)) / popup.scalePresets.length
                    height: 34
                    color: active || presetMouse.containsMouse ? Colors.hover : "transparent"
                    border.width: 1
                    border.color: active ? Colors.accent : Colors.border
                    opacity: scaleProcess.running || !popup.display?.enabled ? 0.5 : 1

                    Text {
                        anchors.centerIn: parent
                        text: preset.modelData + "x"
                        color: preset.active ? Colors.foreground : Colors.foregroundDim
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !scaleProcess.running && !!popup.display?.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.setScale(preset.modelData)
                    }
                }
            }
        }

        Text {
            visible: popup.error !== ""
            width: parent.width
            text: popup.error
            wrapMode: Text.Wrap
            color: Colors.danger
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 14
        }
    }
}
