import QtQuick 2.0
import Ubuntu.Components 0.1

MainView {
    id: mainView
    width: units.gu(45)
    height: units.gu(80)
        // FIXME: 80/45 = aspect ration of Galaxy Nexus

    Tabs { // preliminary HACK, needs rewrite when NewTabBar is finalized!
        id: tabs
        anchors.fill: parent

        Tab { id: pageArea; title: i18n.tr("January"); page: Item { anchors.fill: parent } }
        Tab { title: i18n.tr("February") }
        Tab { title: i18n.tr("March") }
        Tab { title: i18n.tr("April") }
        Tab { title: i18n.tr("May") }
        Tab { title: i18n.tr("June") }
        Tab { title: i18n.tr("July") }
        Tab { title: i18n.tr("August") }
        Tab { title: i18n.tr("September") }
        Tab { title: i18n.tr("October") }
        Tab { title: i18n.tr("November") }
        Tab { title: i18n.tr("December") }

        onSelectedTabIndexChanged: monthView.gotoNextMonth(selectedTabIndex)
    }

    Rectangle {
        anchors.top: monthView.top
        anchors.left: monthView.left
        anchors.right: monthView.right
        height: monthView.visibleHeight
        color: "white"
    }

    MonthView {
        id: monthView
        onMonthStartChanged: tabs.selectedTabIndex = monthStart.getMonth()
        y: pageArea.y
    }

    EventView {
        id: eventView

        property real minY: pageArea.y + monthView.compressedHeight
        property real maxY: pageArea.y + monthView.height

        y: maxY
        width: mainView.width
        height: parent.height - monthView.compressedHeight - monthView.y

        currentDayStart: monthView.currentDayStart
        expanded: !monthView.compressed

        Component.onCompleted: {
            incrementCurrentDay.connect(monthView.incrementCurrentDay)
            decrementCurrentDay.connect(monthView.decrementCurrentDay)
        }

        onCompressRequest: {
            monthView.compressed = true
        }
        onCompressComplete: {
            yBehavior.enabled = true
            y = Qt.binding(function() { return eventView.minY })
        }
        onExpandRequest: {
        }
        onExpandComplete: {
            monthView.compressed = false
            y = Qt.binding(function() { return eventView.maxY })
        }

        Behavior on y {
            id: yBehavior
            enabled: false
            NumberAnimation { duration: 100 }
        }
    }

    tools: ToolbarActions {
        Action {
            iconSource: Qt.resolvedUrl("avatar.png")
            text: i18n.tr("To-do")
            onTriggered:; // FIXME
        }
        Action {
            iconSource: Qt.resolvedUrl("avatar.png")
            text: i18n.tr("New Event")
            onTriggered:; // FIXME
        }
        Action {
            iconSource: Qt.resolvedUrl("avatar.png")
            text: i18n.tr("Timeline")
            onTriggered:; // FIXME
        }
    }
}
