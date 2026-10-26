import QtQuick
import QtQuick.Layouts
import Quickshell

// Starts an agent on a new idea in a fresh aboard workspace, named after the idea.
Rectangle {
    id: root

    required property var shell
    readonly property var agents: ["claude", "pi", "codex"]
    property string agent: "claude"
    property alias input: ideaInput

    // Gives focus back to the lists, e.g. on Escape.
    signal done()

    function start() {
        if (ideaInput.text.trim() === "")
            return;
        Quickshell.execDetached(["agent-run", "idea", "--agent", agent, ideaInput.text.trim()]);
        ideaInput.text = "";
        agent = "claude";
        shell.workOverlayOpen = false;
    }

    function cycleAgent() {
        agent = agents[(agents.indexOf(agent) + 1) % agents.length];
    }

    implicitHeight: 52
    radius: 16
    color: "#e61e1f22"
    border.width: 1
    border.color: ideaInput.activeFocus ? "#7368b5ab" : "#18ffffff"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 10
        spacing: 12

        Text {
            text: "󰛨"
            color: "#f9e2af"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 20
        }

        TextInput {
            id: ideaInput
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: "#f2f2f2"
            selectionColor: "#7368b5ab"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 14

            Keys.onReturnPressed: root.start()
            Keys.onEnterPressed: root.start()
            Keys.onEscapePressed: root.done()
            Keys.onTabPressed: root.cycleAgent()

            Text {
                visible: ideaInput.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: ideaInput.activeFocus ? "Describe the idea…  (⏎ starts, tab switches agent, esc cancels)"
                    : "Start a new idea…  (n)"
                color: "#5d6670"
                font: ideaInput.font
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                // Only grabs focus; clicks after that go to the input for cursor placement.
                enabled: !ideaInput.activeFocus
                onClicked: ideaInput.forceActiveFocus()
            }
        }

        Repeater {
            model: root.agents

            Rectangle {
                id: chip

                required property string modelData
                property bool active: root.agent === modelData

                Layout.preferredHeight: 30
                Layout.preferredWidth: chipText.implicitWidth + 22
                radius: 9
                color: active ? "#1f68b5ab" : chipMouse.containsMouse ? "#0dffffff" : "transparent"
                border.width: 1
                border.color: active ? "#5568b5ab" : "transparent"

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: chip.modelData
                    color: chip.active ? "#ffffff" : "#7d8690"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.agent = chip.modelData;
                        ideaInput.forceActiveFocus();
                    }
                }
            }
        }
    }
}
