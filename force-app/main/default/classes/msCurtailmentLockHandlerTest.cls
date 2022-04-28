/****************************************************************************************************
 * Class msCurtailmentLockHandlerTest
 *
 *   Create By	:   Maciej Dudek
 *   Create Date	:   13.06.2019
 *   Description	:	Testclass for msCurtailmentLockHandler
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Maciej Dudek                  	               13.06.2019       	Init version.
 *****************************************************************************************************/

@IsTest
private class msCurtailmentLockHandlerTest {
    @IsTest
    private static void testUnlockCurtailmentUpdate() {
        createCurtailmentSetting(false);
        Test.startTest();
        msCurtailmentLockHandler.switchCurtailmentUnlock(true);
        Test.stopTest();
        PortalSettings__c testCurtailmentSetting = queryCurtailmentSetting();
        System.assert(testCurtailmentSetting.Checkbox__c, 'Curtailments - Allow Update should be enabled');
    }

    @IsTest
    private static void testLockCurtailmentUpdate() {
        createCurtailmentSetting(true);
        Test.startTest();
        msCurtailmentLockHandler.switchCurtailmentUnlock(false);
        Test.stopTest();
        PortalSettings__c testCurtailmentSetting = queryCurtailmentSetting();
        Date saturday = Date.newInstance(1900, 1, 6);
        Date sunday = Date.newInstance(1900, 1, 7);
        Integer modSaturday = Math.mod(Date.today().daysBetween(saturday), 7);
        Integer modSunday = Math.mod(Date.today().daysBetween(sunday), 7);
        if (modSaturday == 0 || modSunday == 0) {
            System.assert(testCurtailmentSetting.Checkbox__c, 'Curtailments - Allow Update should be still enabled');
        } else {
            System.assert(!testCurtailmentSetting.Checkbox__c, 'Curtailments - Allow Update should be disabled');
        }
    }

    @IsTest
    private static void testUnlockCurtailmentUpdateWithoutRecord() {
        Test.startTest();
        msCurtailmentLockHandler.switchCurtailmentUnlock(true);
        Test.stopTest();
        PortalSettings__c testCurtailmentSetting = queryCurtailmentSetting();
        System.assert(testCurtailmentSetting.Checkbox__c, 'Curtailments - Allow Update should be enabled');
    }

    @IsTest
    private static void testLockCurtailmentUpdateWithoutRecord() {
        Test.startTest();
        msCurtailmentLockHandler.switchCurtailmentUnlock(false);
        Test.stopTest();
        PortalSettings__c testCurtailmentSetting = queryCurtailmentSetting();
        System.assert(!testCurtailmentSetting.Checkbox__c, 'Curtailments - Allow Update should be disabled');
    }

    @IsTest
    private static void calculateTriggerWorkdaysTest() {
        Date regularTriggerDate = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        Date triggerDateByOverflow = Date.newInstance(Date.today().addMonths(-1).year(), Date.today().addMonths(-1).month(), 1);
        Date monday = Date.newInstance(1900, 1, 1);
        Date tuesday = Date.newInstance(1900, 1, 2);
        Date wednesday = Date.newInstance(1900, 1, 3);
        Date thursday = Date.newInstance(1900, 1, 4);
        Date friday = Date.newInstance(1900, 1, 5);
        Date saturday = Date.newInstance(1900, 1, 6);
        Date sunday = Date.newInstance(1900, 1, 7);
        Integer modMondayRegular = Math.mod(regularTriggerDate.daysBetween(monday), 7);
        Integer modTuesdayRegular = Math.mod(regularTriggerDate.daysBetween(tuesday), 7);
        Integer modWednesdayRegular = Math.mod(regularTriggerDate.daysBetween(wednesday), 7);
        Integer modThursdayRegular = Math.mod(regularTriggerDate.daysBetween(thursday), 7);
        Integer modFridayRegular = Math.mod(regularTriggerDate.daysBetween(friday), 7);
        Integer modSaturdayRegular = Math.mod(regularTriggerDate.daysBetween(saturday), 7);
        Integer modSundayRegular = Math.mod(regularTriggerDate.daysBetween(sunday), 7);

        Integer modMondayByOverflow = Math.mod(triggerDateByOverflow.daysBetween(monday), 7);
        Integer modTuesdayByOverflow = Math.mod(triggerDateByOverflow.daysBetween(tuesday), 7);
        Integer modWednesdayByOverflow = Math.mod(triggerDateByOverflow.daysBetween(wednesday), 7);
        Integer modThursdayByOverflow = Math.mod(triggerDateByOverflow.daysBetween(thursday), 7);
        Integer modFridayByOverflow = Math.mod(triggerDateByOverflow.daysBetween(friday), 7);
        Integer modSaturdayByOverflow = Math.mod(triggerDateByOverflow.daysBetween(saturday), 7);
        Integer modSundayByOverflow = Math.mod(triggerDateByOverflow.daysBetween(sunday), 7);

        List<Operational_Holiday__c> testHolidays = new List<Operational_Holiday__c>();
        Integer holidaysToAdd = 0;
        Integer holidaysToAddByOverFlow = 0;
        if (modMondayRegular == 0) {
            holidaysToAdd = 5;
        } else if (modTuesdayRegular == 0) {
            holidaysToAdd = 4;
        } else if (modWednesdayRegular == 0) {
            holidaysToAdd = 3;
        } else if (modThursdayRegular == 0) {
            holidaysToAdd = 2;
        } else if (modFridayRegular == 0) {
            holidaysToAdd = 1;
        }
        if (modMondayByOverflow == 0) {
            holidaysToAddByOverFlow = 5;
        } else if (modTuesdayByOverflow == 0) {
            holidaysToAddByOverFlow = 4;
        } else if (modWednesdayByOverflow == 0) {
            holidaysToAddByOverFlow = 3;
        } else if (modThursdayByOverflow == 0) {
            holidaysToAddByOverFlow = 2;
        } else if (modFridayByOverflow == 0) {
            holidaysToAddByOverFlow = 1;
        }
        for (Integer i = 0; i < holidaysToAdd; i++) {
            testHolidays.add(new Operational_Holiday__c(Name = 'test', Affected_Date__c = regularTriggerDate.addDays(i), Market__c = 'Germany'));
        }
        for (Integer i = 0; i < holidaysToAddByOverFlow; i++) {
            testHolidays.add(new Operational_Holiday__c(Name = 'test', Affected_Date__c = triggerDateByOverflow.addDays(i), Market__c = 'Germany'));
        }
        insert testHolidays;
        Test.startTest();
        Set<Date> datesToSchedule = msCurtailmentLockHandler.calculateTriggerWorkdays(3);
        Test.stopTest();
    }

    private static void createCurtailmentSetting(Boolean isSettingEnabled) {
        PortalSettings__c testCurtailmentSetting;
        testCurtailmentSetting = new PortalSettings__c(Name = msCurtailmentLockHandler.CURTAILMENT_ALLOW_UPDATE, Checkbox__c = isSettingEnabled);
        insert testCurtailmentSetting;
    }

    private static PortalSettings__c queryCurtailmentSetting() {
        List<PortalSettings__c> settings = [
            SELECT Id, Checkbox__c
            FROM PortalSettings__c
            WHERE Name = :msCurtailmentLockHandler.CURTAILMENT_ALLOW_UPDATE
            LIMIT 1
        ];
        if (!settings.isEmpty()) {
            return settings[0];
        }
        return null;
    }
}