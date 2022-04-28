/****************************************************************************************************
 * Class msCurtailmentLockHandler
 *
 *   Create By	:   Maciej Dudek
 *   Create Date	:   13.06.2019
 *   Description	:	This class is used to handle unlocking of the 'Curtailments - Allow Update' Portal
 *                   Settings
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	        Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Maciej Dudek                              13.06.2019          Init version.
 *   * Christian Gottlieb (mindsquare GmbH)      16.01.2020          Refactored for usage in msScheduledPortalActions
 *****************************************************************************************************/

public with sharing class msCurtailmentLockHandler {
    public static final String CURTAILMENT_ALLOW_UPDATE = 'Curtailments - Allow Update';

    @TestVisible
    private static Date today = Date.today();
    private static final Map<String, Integer> MONTHS = new Map<String, Integer>{
        'January' => 1,
        'February' => 2,
        'March' => 3,
        'April' => 4,
        'May' => 5,
        'June' => 6,
        'July' => 7,
        'August' => 8,
        'September' => 9,
        'October' => 10,
        'November' => 11,
        'December' => 12
    };

    public static Set<Date> calculateTriggerWorkdays(Integer triggerDay) {
        Date regularTriggerDate = Date.newInstance(today.year(), today.month(), triggerDay);
        Date triggerDateByOverflow = Date.newInstance(today.addMonths(-1).year(), today.addMonths(-1).month(), triggerDay);
        Set<Date> pushFurtherDates = getHolidayDates();

        pushFurtherDates.addAll(getRemainingDaysOfWeekend(regularTriggerDate));
        pushFurtherDates.addAll(getRemainingDaysOfWeekend(triggerDateByOverflow));

        while (pushFurtherDates.contains(regularTriggerDate)) {
            regularTriggerDate = regularTriggerDate.addDays(1);
            pushFurtherDates.addAll(getRemainingDaysOfWeekend(regularTriggerDate));
        }
        while (pushFurtherDates.contains(triggerDateByOverflow)) {
            triggerDateByOverflow = triggerDateByOverflow.addDays(1);
            pushFurtherDates.addAll(getRemainingDaysOfWeekend(triggerDateByOverflow));
        }
        return new Set<Date>{ regularTriggerDate, triggerDateByOverflow };
    }

    public static void switchCurtailmentUnlock(Boolean unlock) {
        List<PortalSettings__c> settings = getCurtailmentPortalSettings();

        if (!settings.isEmpty()) {
            PortalSettings__c curtailmentLockSetting = settings[0];
            curtailmentLockSetting.Checkbox__c = unlock;
            update curtailmentLockSetting;
        } else {
            PortalSettings__c curtailmentLockSetting = new PortalSettings__c(Name = CURTAILMENT_ALLOW_UPDATE, Checkbox__c = unlock);
            insert curtailmentLockSetting;
        }
    }

    public static void lockCurtailmentUpdate() {
        switchCurtailmentUnlock(false);
    }

    public static void unlockCurtailmentUpdate() {
        switchCurtailmentUnlock(true);
    }

    private static List<PortalSettings__c> getCurtailmentPortalSettings() {
        return [SELECT Id, Checkbox__c FROM PortalSettings__c WHERE Name = :CURTAILMENT_ALLOW_UPDATE LIMIT 1];
    }

    private static Set<Date> getHolidayDates() {
        Date todayLastMonth = Date.today().addMonths(-1);
        Date todayNextMonth = Date.today().addMonths(1);

        Set<Date> holidayDates = new Set<Date>();
        List<Operational_Holiday__c> holidays = [
            SELECT Affected_Date__c
            FROM Operational_Holiday__c
            WHERE Market__c = 'Germany' AND Affected_Date__c > :todayLastMonth AND Affected_Date__c < :todayNextMonth
        ];
        for (Operational_Holiday__c holiday : holidays) {
            holidayDates.add(holiday.Affected_Date__c.addDays(1));
        }
        return holidayDates;
    }

    private static Set<Date> getRemainingDaysOfWeekend(Date initialDay) {
        Date sunday = Date.newInstance(1900, 1, 7);
        Date monday = Date.newInstance(1900, 1, 8);
        Integer modSaturday = Math.mod(initialDay.daysBetween(sunday), 7);
        Integer modSunday = Math.mod(initialDay.daysBetween(monday), 7);
        Set<Date> weekEndDays = new Set<Date>();
        if (modSaturday == 0) {
            weekEndDays.add(initialDay);
            weekEndDays.add(initialDay.addDays(1));
        } else if (modSunday == 0) {
            weekEndDays.add(initialDay);
        }
        return weekEndDays;
    }
}