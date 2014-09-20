/*
 * Copyright (C) 2014 Canonical Ltd
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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Page{
    id:root
    objectName: "eventReminder"

    property var visualReminder: null
    property var audibleReminder: null
    property var reminderModel: null
    property var eventTitle: null
    property var reminderTime: visualReminder.secondsBeforeStart

    visible: false
    flickable: null
    title: i18n.tr("Reminder")

    head.backAction: Action{
        iconName:"back"
        onTriggered:{
            if(reminderTime !== 0){
                visualReminder.repetitionCount = 3;
                visualReminder.repetitionDelay = 120;
                visualReminder.message = eventTitle
                visualReminder.secondsBeforeStart = reminderTime;

                audibleReminder.repetitionCount = 3;
                audibleReminder.repetitionDelay = 120;
                audibleReminder.secondsBeforeStart = reminderTime;
            }
            pop();
        }
    }

    Flickable {
        id: _pageFlickable

        clip: true
        anchors.fill: parent
        contentHeight: reminderModel.count * units.gu(7)

        Column {
            id: _reminderColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Repeater {
                id: _reminders

                model: reminderModel

                ListItem.Standard {
                    id: _reminderDelegate

                    property alias isChecked: reminderCheckbox.checked

                    text: label
                    control: CheckBox {
                        id: reminderCheckbox

                        checked: root.reminderTime === value

                        onClicked: {
                            root.reminderTime = value
                            if (checked) {
                                // Ensures only one reminder option is selected
                                for(var i=0; i<reminderModel.count; i++) {
                                    if(_reminders.itemAt(i).isChecked &&
                                            i !== index) {
                                        _reminders.itemAt(i).isChecked = false
                                    }
                                }
                            }

                            else {
                                checked = !checked
                            }
                        }
                    }
                }
            }
        }
    }
}