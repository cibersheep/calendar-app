.pragma library
.import "dateExt.js" as DateExt

function minutesSince(since, until)
{
    var sinceTime = new Date(since)
    sinceTime.setSeconds(0)
    var untilTime =  new Date(until)
    untilTime.setSeconds(0)

    var sinceTimeInSecs = sinceTime.getTime()
    var untilTimeInSecs = untilTime.getTime()

    // limit to since day minutes
    untilTimeInSecs = Math.min(sinceTime.endOfDay().getTime(), untilTimeInSecs)

    // calculate the time in minutes of this event
    var totalSecs =  untilTimeInSecs - sinceTimeInSecs
    if (totalSecs > 0)
        return (totalSecs / 60000)

    return 0
}

function parseDayEvents(date, itemsOfTheDay)
{
    var eventsInfo = []

    // put events with the same start time together
    for(var c=0; c < itemsOfTheDay.length; c++) {
        var event = itemsOfTheDay[c]
        if (event.allDay)
            continue

        var eventStartTimeInMinutes = minutesSince(date, event.startDateTime)
        var eventEndTimeInMinutes = minutesSince(date, event.endDateTime)
        eventsInfo.push({'eventId': event.itemId,
                         'startTime': eventStartTimeInMinutes,
                         'endTime': eventEndTimeInMinutes,
                         'endTimeInSecs': event.endDateTime.getTime(),
                         'y': -1,
                         'intersectionCount': 0,
                         'width': 1.0})
    }

    return eventsInfo
}
