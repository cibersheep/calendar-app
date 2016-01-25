/*
 * Copyright (C) 2013-2014 Canonical Ltd
 *
 * This file is part of Ubuntu Calendar App
 *
 * Ubuntu Calendar App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Ubuntu Calendar App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import "dateExt.js" as DateExt
import "ViewType.js" as ViewType

Page{
    id: weekViewPage
    objectName: "weekViewPage"

    property var anchorDate: new Date();
    readonly property var currentDate: weekViewPath.currentItem.item.startDay

    property var firstDayOfWeek: currentDate.weekStart(Qt.locale().firstDayOfWeek);
    property bool isCurrentPage: false
    property var selectedDay;

    signal dateSelected(var date);
    signal dateHighlighted(var date);

    Keys.forwardTo: [weekViewPath]

    flickable: null

    Action {
        id: calendarTodayAction
        objectName:"todaybutton"
        iconName: "calendar-today"
        text: i18n.tr("Today")
        onTriggered: {
            dayStart = new Date()
        }
    }

    head {
        actions: [
            calendarTodayAction,
            commonHeaderActions.newEventAction,
            commonHeaderActions.showCalendarAction,
            commonHeaderActions.reloadAction,
            commonHeaderActions.syncCalendarAction,
            commonHeaderActions.settingsAction
        ]

        contents: Label {
            id:monthYear
            objectName:"monthYearLabel"
            fontSize: "x-large"
            text: i18n.tr(currentDate.toLocaleString(Qt.locale(),i18n.tr("MMMM yyyy")))
            font.capitalization: Font.Capitalize
        }
    }

    PathViewBase{
        id: weekViewPath
        objectName: "weekviewpathbase"

        anchors.fill: parent

        //This is used to scroll all view together when currentItem scrolls
        property var childContentY;

        delegate: Loader {
            id: timelineLoader
            width: parent.width
            height: parent.height
            asynchronous: !weekViewPath.isCurrentItem
            sourceComponent: delegateComponent

            Component{
                id: delegateComponent

                TimeLineBaseComponent {
                    id: timeLineView

                    anchors.fill: parent
                    type: ViewType.ViewTypeWeek
                    startDay: anchorDate.addDays((weekViewPath.loopCurrentIndex + weekViewPath.indexType(index)) * 7)
                    isActive: parent.PathView.isCurrentItem
                    keyboardEventProvider: weekViewPath
                    selectedDay: weekViewPage.selectedDay

                    onIsActiveChanged: {
                        timeLineView.scrollTocurrentDate();
                    }

                    onDateSelected: {
                        weekViewPage.dateSelected(date);
                    }

                    onDateHighlighted:{
                        weekViewPage.dateHighlighted(date);
                    }

                    Connections{
                        target: calendarTodayAction
                        onTriggered:{
                            if( isActive )
                                timeLineView.scrollTocurrentDate();
                            }
                    }

                    Connections{
                        target: weekViewPage
                        onIsCurrentPageChanged:{
                            if(weekViewPage.isCurrentPage){
                                timeLineView.scrollToCurrentTime();
                                timeLineView.scrollTocurrentDate();
                            }
                        }
                    }

                    //get contentY value from PathView, if its not current Item
                    Binding{
                        target: timeLineView
                        property: "contentY"
                        value: weekViewPath.childContentY;
                        when: !parent.PathView.isCurrentItem
                    }

                    //set PathView's contentY property, if its current item
                    Binding{
                        target: weekViewPath
                        property: "childContentY"
                        value: contentY
                        when: parent.PathView.isCurrentItem
                    }
                }
            }
        }
    }
}
