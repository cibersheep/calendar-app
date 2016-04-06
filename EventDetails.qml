/*
 * Copyright (C) 2013-2016 Canonical Ltd
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
import Ubuntu.Components.Popups 1.3
import QtOrganizer 5.0

import "Defines.js" as Defines
import "dateExt.js" as DateExt
import "./3rd-party/lunar.js" as Lunar

Page {
    id: root
    objectName: "eventDetails"

    property var event
    property var model
    property var collection: model.collection(event.collectionId);

    header: PageHeader {
        title: i18n.tr("Event Details")
        flickable: flicable
        trailingActionBar.actions: Action {
            text: i18n.tr("Edit");
            objectName: "edit"
            iconName: "edit";
            enabled: !collection.extendedMetaData("collection-readonly")
            shortcut: "Ctrl+E"
            onTriggered: {
                if( event.itemType === Type.EventOccurrence ) {
                    var dialog = PopupUtils.open(Qt.resolvedUrl("EditEventConfirmationDialog.qml"),root,{"event": event});
                    dialog.editEvent.connect( function(eventId){
                        if( eventId === event.parentId ) {
                            showEditEventPage(internal.parentEvent, model)
                        } else {
                            showEditEventPage(event, model)
                        }
                    });
                } else {
                    showEditEventPage(event, model)
                }
            }
        }
    }

    Component.onCompleted: {
        showEvent(event)
    }

    Keys.onEscapePressed: {
        pageStack.pop();
    }

    Connections {
        target: event
        onItemChanged: showEvent(event)
    }

    Connections{
        target: model
        onItemsFetched: {
            if (internal.fetchParentRequestId === requestId) {
                if (fetchedItems.length > 0) {
                    internal.parentEvent = fetchedItems[0];
                    updateRecurrence(internal.parentEvent);
                } else {
                    console.warn("Fail to fetch pareten event")
                }
                internal.fetchParentRequestId = -1
            }

        }
    }

    function updateRecurrence( event ) {
        var index = 0;
        if (event.recurrence) {
            if(event.recurrence.recurrenceRules[0] !== undefined){
                var rule =  event.recurrence.recurrenceRules[0];
                recurrenceLabel.text = eventUtils.getRecurrenceString(rule)
            } else {
                //For event occurs once, event.recurrence.recurrenceRules == []
                recurrenceLabel.text = Defines.recurrenceLabel[0];
            }
        }
    }

    function updateContacts(event) {
        // Use details method to get attendees list instead of "attendees" property
        // since a binding issue was returning an empty attendees list for some use cases
        var attendees = event.details(Detail.EventAttendee)

        contactModel.clear();

        if( attendees !== undefined ) {
            for (var j = 0 ; j < attendees.length ; ++j) {
                var name = attendees[j].name.trim().length === 0 ? attendees[j].emailAddress.replace("mailto:", "")
                                                                 : attendees[j].name
                var participationStatus = attendees[j].participationStatus
                if (participationStatus === EventAttendee.StatusAccepted) {
                    contactModel.append({"name": name, "participationStatus": i18n.tr("Attending")});

                } else if (participationStatus === EventAttendee.StatusDeclined) {
                    contactModel.append({"name": name, "participationStatus": i18n.tr("Not Attending")});

                } else if (participationStatus === EventAttendee.StatusTentative) {
                    contactModel.append({"name": name, "participationStatus": i18n.tr("Maybe")});

                } else {
                    contactModel.append({"name": name, "participationStatus": i18n.tr("No Reply")});

                }
            }
        }
    }

    function updateReminder(event) {
        //TODO: implment support for display information about all reminder
        // We can have multiples Audible and Visible reminders.
        var reminder = event.detail(Detail.AudibleReminder)
        if(reminder) {
            for(var i=0; i<reminderModel.count; i++) {
                if(reminder.secondsBeforeStart === reminderModel.get(i).value) {
                    reminderLayout.subtitle.text = reminderModel.get(i).label
                }
            }
        } else {
            reminderLayout.subtitle.text = reminderModel.get(0).label
        }
    }

    function getDate(e) {
        var dateLabel = null

        var startDateTime = e.startDateTime
        var endDateTime = isNaN(e.endDateTime.getTime()) ? e.startDateTime : e.endDateTime

        var startTime = startDateTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        var endTime = endDateTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        var startDay = startDateTime.toLocaleDateString(Qt.locale(), Locale.LongFormat)
        var endDay = endDateTime.toLocaleDateString(Qt.locale(), Locale.LongFormat)

        var lunarStartDate = null
        var lunarEndDate = null

        var allDayString = "(%1)".arg(i18n.tr("All Day"))

        if (mainView.displayLunarCalendar) {
            lunarStartDate = Lunar.calendar.solar2lunar(startDateTime.getFullYear(),
                                                        startDateTime.getMonth() + 1,
                                                        startDateTime.getDate())

            lunarEndDate = Lunar.calendar.solar2lunar(endDateTime.getFullYear(),
                                                      endDateTime.getMonth() + 1,
                                                      endDateTime.getDate())
        }

        if( e.allDay ) {
            var days = Math.floor((endDateTime - startDateTime) / Date.msPerDay);
            if( days !== 1 ) {
                if (mainView.displayLunarCalendar) {
                    dateLabel = ("%1 %2 %3 - %4 %5 %6").arg(lunarStartDate.gzYear).arg(lunarStartDate .IMonthCn).arg(lunarStartDate.IDayCn)
                    .arg(lunarEndDate.gzYear).arg(lunarEndDate .IMonthCn).arg(lunarEndDate.IDayCn)
                } else {
                    dateLabel = ("%1 - %2").arg(startDay).arg(endDateTime.addDays(-1).toLocaleDateString(Qt.locale(), Locale.LongFormat))
                }
            } else {
                if (mainView.displayLunarCalendar) {
                    dateLabel = ("%1 %2 %3").arg(lunarStartDate.gzYear).arg(lunarStartDate .IMonthCn).arg(lunarStartDate.IDayCn)
                } else {
                    dateLabel = startDay
                }
            }

            dateLabel = dateLabel.concat(" ", allDayString)
        }

        else {
            if (endDateTime.getDate() !== startDateTime.getDate()) {
                if (mainView.displayLunarCalendar) {
                    dateLabel = ("%1 %2 %3, %4 - %5 %6 %7, %8").arg(lunarStartDate.gzYear).arg(lunarStartDate .IMonthCn).arg(lunarStartDate.IDayCn).arg(startTime)
                    .arg(lunarEndDate.gzYear).arg(lunarEndDate .IMonthCn).arg(lunarEndDate.IDayCn).arg(endTime);
                } else {
                    dateLabel = ("%1, %2 - %3, %4").arg(startDay).arg(startTime).arg(endDay).arg(endTime)
                }
            } else {
                if (mainView.displayLunarCalendar) {
                    dateLabel = ("%1 %2 %3, %4 - %5").arg(lunarStartDate.gzYear).arg(lunarStartDate .IMonthCn).arg(lunarStartDate.IDayCn).arg(startTime).arg(endTime)
                } else {
                    dateLabel = ("%1, %2 - %3").arg(startDay).arg(startTime).arg(endTime)
                }
            }
        }
        return dateLabel
    }

    function showEvent(e) {
        var isOcurrence =  (e.itemType === Type.EventOccurrence) || (e.itemType === Type.TodoOccurrence)
        if (isOcurrence) {
            internal.fetchParentRequestId = model.fetchItems([e.parentId]);
        }

        updateContacts(e);
        updateRecurrence(e);
        updateReminder(e);
    }

    function showEditEventPage(event, model) {
        if(event.itemId === "qtorganizer:::") {
            //Can not edit event without proper itemid
            return;
        }

        pageStack.push(Qt.resolvedUrl("NewEvent.qml"),{"event": event, "model":model});
        pageStack.currentPage.eventAdded.connect( function(event){
            pageStack.pop();
        })
        //When event deleted from the Edit mode
        pageStack.currentPage.eventDeleted.connect(function(eventId){
            pageStack.pop();
        })
    }

    RemindersModel {
        id: reminderModel
    }

    ListModel {
        id: contactModel
    }

    EventUtils{
        id:eventUtils
    }

    QtObject{
        id: internal
        property int fetchParentRequestId: -1;
        property var parentEvent;
    }

    Scrollbar {
        flickableItem: flicable
        align: Qt.AlignTrailing
    }

    Flickable{
        id: flicable

        clip: interactive
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.height + titleContainer.height

        Rectangle{
            id: titleContainer

            color: collection.color
            width: parent.width
            height: mainEventDetails.height + units.gu(4)

            Column {
                id: mainEventDetails

                spacing: units.gu(0.5)
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; margins: units.gu(2) }

                Label {
                    text: event.displayLabel
                    color: "White"
                    textSize: Label.Large
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: getDate(event)
                    color: "White"
                    visible: text != ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: event.location
                    color: "White"
                    visible: text != ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Label {
                    id: recurrenceLabel
                    textSize: Label.Small
                    color: "White"
                    visible: text != ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }
        }

        Column{
            id: column

            width: parent.width
            anchors.top: titleContainer.bottom

            ListItem {
                height: units.gu(6)
                Row{
                    id: calendarNameRow

                    spacing: units.gu(1)
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; margins: units.gu(2) }

                    Label {
                        text: i18n.tr("Calendar")
                    }

                    UbuntuShape{
                        id: calendarIndicator
                        width: parent.height
                        height: width
                        color: collection.color
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label{
                        id:calendarName
                        objectName: "calendarName"
                        text: collection.name
                    }
                }
            }

            ListView {
                model: contactModel
                width: parent.width
                height: count !== 0 ? (count+1) * units.gu(7): 0
                interactive: false

                section.property: "participationStatus"
                section.labelPositioning: ViewSection.InlineLabels
                section.delegate:  ListItem {
                    height: sectionLayout.height
                    divider.visible: false
                    ListItemLayout {
                        id: sectionLayout
                        title.text: section
                        title.font.weight: Font.DemiBold
                    }
                }

                delegate: ListItem {
                    height: contactListItemLayout.height
                    divider.visible: false
                    ListItemLayout {
                        id: contactListItemLayout
                        title.text: name
                    }
                }
            }

            // Add a ListItem to work as divider between the contact list model and the description list item
            // This will be removed on the new event's details page
            ListItem { height: units.gu(4) }

            ListItem {
                id: descLabel
                height: descTitle.height + desc.implicitHeight + divider.height + units.gu(4)
                visible: desc.text !== ""

                Label {
                    id: descTitle
                    text: i18n.tr("Description")
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(2); topMargin: units.gu(1.5) }
                }

                Label {
                    id: desc
                    text: event.description
                    textSize: Label.Small
                    color: UbuntuColors.graphite
                    wrapMode: Text.WordWrap
                    anchors { left: parent.left; right: parent.right; top: descTitle.bottom; margins: units.gu(2); topMargin: units.gu(0.5) }
                }
            }

            ListItem {
                height: reminderLayout.height + divider.height
                ListItemLayout {
                    id: reminderLayout
                    title.text: i18n.tr("Reminder")
                }
            }
        }
    }
}
