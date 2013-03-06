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

        onSelectedTabIndexChanged: calendarView.gotoNextMonth(selectedTabIndex)
    }

    CalendarView {
        id: calendarView
        onMonthStartChanged: tabs.selectedTabIndex = monthStart.getMonth()
        y: pageArea.y
        width: mainView.width
        height: (mainView.width / 8) * 6
    }

    EventView {
        id: eventView
        currentDayStart: calendarView.currentDayStart
        anchors.top: calendarView.bottom
        anchors.bottom: parent.bottom
        width: mainView.width
        Component.onCompleted: {
            incrementCurrentDay.connect(calendarView.incrementCurrentDay)
            decrementCurrentDay.connect(calendarView.decrementCurrentDay)
        }
    }
}
