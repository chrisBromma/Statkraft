/****************************************************************************************************
* Class msChartDatePickerController
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-10-10
*   Description	:	Controller for the msChartDatePicker Component
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-10-10       	Init version.
*****************************************************************************************************/

public with sharing class msChartDatePickerController {

    @AuraEnabled
    public static Map<String, Datetime> convertSelectedDates(   Date localStartDate, Integer localStartHour, Integer localStartMinute,
                                                                Date localEndDate, Integer localEndHour, Integer localEndMinute,
                                                                String timeZoneSidKey) {
        Time localStartTime = Time.newInstance(localStartHour, localStartMinute,0,0);
        Time localEndTime = Time.newInstance(localEndHour, localEndMinute,0,0);
        Map<String, Datetime> startAndEndDateUTC = new Map<String, Datetime>();
        startAndEndDateUTC.put('startDateUTC', convertToUTC(localStartDate, localStartTime, timeZoneSidKey));
        startAndEndDateUTC.put('endDateUTC', convertToUTC(localEndDate, localEndTime, timeZoneSidKey));

        return startAndEndDateUTC;
    }

    @AuraEnabled
    public static Datetime convertToUTC(Date localDate, Time localTime, String timeZoneSidKey) {

        Datetime localDateTime = Datetime.newInstanceGmt(localDate,localTime);
        Long localUnixTime = localDateTime.getTime();
        Integer offset = TimeZone.getTimeZone(timeZoneSidKey).getOffset(localDateTime);
        return Datetime.newInstance(localUnixTime - offset);
    }
}