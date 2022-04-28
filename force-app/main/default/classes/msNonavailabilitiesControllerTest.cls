/****************************************************************************************************
* Class msNonavailabilitiesControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   11.10.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   11.10.2018      	    Init version.
*****************************************************************************************************/

@IsTest
private class msNonavailabilitiesControllerTest {

    @TestSetup public static void generateTestData(){
        msTestDataFactory.createTestPortalContext();
    }
    @IsTest
    static void testGetDowntimes() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"id":"3c98a0b8-3a1d-441f-a019-b20d2df4fd50","version":1,"country":"Germany",' +
                '"entityName":"AN 00530 Windpark Oer-Erkenschwick","entityId":"a0F1j0000008Xe3EAE",' +
                '"entityType":"Asset","outageStatus":"Open","startDate":"2018-10-11T09:51:00Z",' +
                '"endDate":"2018-10-12T09:51:00Z","level":0.0,"generators":[],"reason":"Unplanned_failure",' +
                '"outageType":"Shutdown","changeUser":"Testi Naundorf","changeTime":"2018-10-11T09:51:15.9401967Z"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Downtimes_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            msNonavailabilitiesController.OutagesWrapper testWrapper = msNonavailabilitiesController.getDowntimes(testMeter.Id);
            System.assert(!testWrapper.generationUnits.isEmpty(), 'The Outages should contain a List of GenUnits');
            System.assert(!testWrapper.outages.isEmpty(), 'The Mock response has an Outage, it should be listed');
        }
        System.Test.stopTest();
    }
    @IsTest
    static void testGetMasterData() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            System.assert(!msNonavailabilitiesController.getGenUnits(testMeter.Id).isEmpty(), 'The Meter should have Generation Units to present');

        }
        System.Test.stopTest();
    }
    @IsTest
    static void testAddPartialDowntime() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"id":"3c98a0b8-3a1d-441f-a019-b20d2df4fd50","version":1,"country":"Germany",' +
                        '"entityName":"AN 00530 Windpark Oer-Erkenschwick","entityId":"a0F1j0000008Xe3EAE",' +
                        '"entityType":"Asset","outageStatus":"Open","startDate":"2018-10-11T09:51:00Z",' +
                        '"endDate":"2018-10-12T09:51:00Z","level":0.0,"generators":[],"reason":"Unplanned_failure",' +
                        '"outageType":"Shutdown","changeUser":"Testi Naundorf","changeTime":"2018-10-11T09:51:15.9401967Z"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Downtimes_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];

        System.Test.startTest();

        System.runAs(testUser) {
            msNonavailabilitiesController.upsertDowntime(testMeter.Id,
                    msUtility.parseUtcDateTime('' + Datetime.now().addDays(2)),
                    msUtility.parseUtcDateTime('' + Datetime.now().addDays(2)),
                    'abc',
                    'abc',
                    JSON.serialize(new List<msNonavailabilitiesController.GeneratorOutage>()),
                    5.4,
                    null,
                    'test comment'
            );
            System.Test.stopTest();
        }
    }
    @IsTest
    static void testAddGeneratorDowntime() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"id":"3c98a0b8-3a1d-441f-a019-b20d2df4fd50","version":1,"country":"Germany",' +
                        '"entityName":"AN 00530 Windpark Oer-Erkenschwick","entityId":"a0F1j0000008Xe3EAE",' +
                        '"entityType":"Asset","outageStatus":"Open","startDate":"2018-10-11T09:51:00Z",' +
                        '"endDate":"2018-10-12T09:51:00Z","level":0.0,"generators":[],"reason":"Unplanned_failure",' +
                        '"outageType":"Shutdown","changeUser":"Testi Naundorf","changeTime":"2018-10-11T09:51:15.9401967Z"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Downtimes_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            msNonavailabilitiesController.upsertDowntime(testMeter.Id,
                    msUtility.parseUtcDateTime('' + Datetime.now().addDays(-1)),
                    msUtility.parseUtcDateTime('' + Datetime.now()).addDays(2),
                    'abc',
                    'abc',
                    JSON.serialize(
                        new List<msNonavailabilitiesController.GeneratorOutage>{
                                new msNonavailabilitiesController.GeneratorOutage(testMeter.Id, 'Generation Unit1', 3.4)
                        }),
                    5.4,
                    '123',
                    'test comment'
            );
            System.Test.stopTest();
        }
    }
    @IsTest
    static void testDeleteDowntimeApex(){
        String downtimeId = '';
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"id":"3c98a0b8-3a1d-441f-a019-b20d2df4fd50","version":1,"country":"Germany",' +
                        '"entityName":"AN 00530 Windpark Oer-Erkenschwick","entityId":"a0F1j0000008Xe3EAE",' +
                        '"entityType":"Asset","outageStatus":"Open","startDate":"2018-10-11T09:51:00Z",' +
                        '"endDate":"2018-10-12T09:51:00Z","level":0.0,"generators":[],"reason":"Unplanned_failure",' +
                        '"outageType":"Shutdown","changeUser":"Testi Naundorf","changeTime":"2018-10-11T09:51:15.9401967Z"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Downtimes_Endpoint__c + '/' + downtimeId, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            msNonavailabilitiesController.deleteDowntimeApex(testMeter.Id, downtimeId);
        }
        System.Test.stopTest();
    }
    @IsTest
    private static void getOutageReasonsTest() {
        User testUserDE = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        User testUserUK = [SELECT Id, Name, ContactId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        User testUserFR = [SELECT Id, Name, ContactId FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Meter__c testMeterDE = [SELECT Id, Name FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];
        Meter__c testMeterUKFLEX = [SELECT Id, Name FROM Meter__c WHERE Name = 'ukMeter1' LIMIT 1];
        Meter__c testMeterFR = [SELECT Id, Name FROM Meter__c WHERE Name = 'frMeter10' LIMIT 1];
        Test.startTest();
        System.runAs(testUserDE) {
            List<msNonavailabilitiesController.OutageReasonWrapper> reasons = msNonavailabilitiesController.getOutageReasons(testMeterDE.Id);
            System.assert(!reasons.isEmpty(), 'There should be reasons stored for Market Germany');
        }
        System.runAs(testUserUK) {
            List<msNonavailabilitiesController.OutageReasonWrapper> reasons = msNonavailabilitiesController.getOutageReasons(testMeterUKFLEX.Id);
            System.assert(!reasons.isEmpty(), 'There should be reasons stored for Market UK FLex');
        }
        System.runAs(testUserFR) {
            List<msNonavailabilitiesController.OutageReasonWrapper> reasons = msNonavailabilitiesController.getOutageReasons(testMeterFR.Id);
            System.assert(!reasons.isEmpty(), 'There should be reasons stored for Market France');
        }
        Test.stopTest();

    }
}