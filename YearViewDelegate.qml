import QtQuick 2.4
import Ubuntu.Components 1.3

GridView{
    id: yearView

    property int scrollMonth;
    property bool isCurrentItem;
    property int year;
    readonly property var currentDate: new Date()
    readonly property int currentYear: currentDate.getFullYear()
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int minCellWidth: units.gu(30)

    function refresh() {
        scrollMonth = 0;
        if(year == currentYear) {
            scrollMonth = currentMonth
        }
        yearView.positionViewAtIndex(scrollMonth, GridView.Beginning);
    }

    // Does not increase cash buffer if user is scolling
    cacheBuffer: PathView.view.flicking || PathView.view.dragging || !isCurrentItem ? 0 : 6 * cellHeight

    cellWidth: Math.floor(Math.min.apply(Math, [3, 4].map(function(n)
    { return ((width / n >= minCellWidth) ? width / n : width / 2) })))
    cellHeight: cellWidth * 1.4

    clip: true
    model: 12 /* months in a year */

    //scroll in case content height changed
    onHeightChanged: {
        yearView.positionViewAtIndex(scrollMonth, GridView.Beginning);
    }

    Component.onCompleted: {
        yearView.positionViewAtIndex(scrollMonth, GridView.Beginning);
    }

    delegate: Item {
        width: yearView.cellWidth
        height: yearView.cellHeight

        UbuntuShape {
            radius: "medium"
            anchors {
                fill: parent
                margins: units.gu(0.5)
            }

            MonthComponent {
                id: monthComponent
                objectName: "monthComponent" + index

                anchors {
                    margins: units.gu(0.5)
                    fill: parent
                }

                currentYear: yearView.year
                currentMonth: index
                isCurrentItem: yearView.focus
                isYearView: true
                dayLabelFontSize:"x-small"
                dateLabelFontSize: "medium"
                monthLabelFontSize: "medium"
                yearLabelFontSize: "medium"
                onMonthSelected: {
                    yearViewPage.monthSelected(date);
                }
            }
        }
    }
}
