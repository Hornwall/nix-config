import QtQuick

// A rail along the left edge of a PR row that joins the rows of one stack.
Rectangle {
    id: root

    required property var pullRequests
    required property int index
    property int gap: 6
    property var stack: pullRequests[index].stack || null
    property bool joinsAbove: stack !== null && index > 0
        && (pullRequests[index - 1].stack || {}).id === stack.id
    property bool joinsBelow: stack !== null && index < pullRequests.length - 1
        && (pullRequests[index + 1].stack || {}).id === stack.id
    // "󰜘 2/4 on #8779", for the row's first line.
    property string label: stack === null ? ""
        : "󰜘 " + stack.position + "/" + stack.size + (stack.parent ? " on #" + stack.parent.number : "")

    visible: stack !== null
    x: 4
    y: joinsAbove ? -gap : 12
    width: 3
    height: parent.height - y - (joinsBelow ? -gap : 12)
    radius: 1.5
    color: "#80b4befe"
}
