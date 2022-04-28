/****************************************************************************************************
* Class msUtilityTest
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   19.09.2018 
*   Description	:	Test class for the class msUtility
*
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            19.09.2018          Init version.
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019      	Version 1 for deploy to Prod
*****************************************************************************************************/
@IsTest
private class msUtilityTest {

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    private static void testHTTP() {
        String endpoint = 'https:test-endpoint.statkraft.com';
        String body = 'Just a test body';
        String body2 = null;
        String method = 'POST';
        HttpResponse response1 = new HttpResponse();
        HttpResponse response2 = new HttpResponse();
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('Test successfull')
                .build();
        endpointToResponseMap.put(endpoint, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        System.Test.startTest();
        response1 = msUtility.getHttp(endpoint, body, method);
        response2 = msUtility.getHttp(endpoint, body2, method);
        System.Test.stopTest();

        System.assert(response1.getBody() == 'Test successfull', 'The test with request body was not successfull.');
        System.assert(response2.getBody() == 'Test successfull', 'The test without request body was not successfull.');
    }

    @IsTest
    private static void testObjectAccsess() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];

        List<Site_Role__c> siteRoles = [
                SELECT Id, Meter__c
                FROM Site_Role__c
                WHERE Contact__c = :testUser.ContactId
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c = null OR End_Date__c >= :Date.today())
        ];
        List<Contract_Role__c> contractRoles = new List<Contract_Role__c> ([SELECT Id, Contract__c FROM Contract_Role__c WHERE Contact__c = :testUser.ContactId]);
        Account account = [SELECT Id FROM Account LIMIT 1];

        Meter__c newTestMeter = new Meter__c(
                Name = 'new Test Meter',
                Status__c = 'Active',
                Country__c = 'Germany',
                Portfolio_ID__c = 'as_de2_an_11210_windpark_hohenseefeld999'
        );
        insert newTestMeter;

        Contract__c newTestContract = new Contract__c(
                RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId(),
                Start_Date__c = Date.today().addDays(-20),
                End_Date__c = Date.today().addDays(20),
                Contract_Holder__c = account.Id,
                Status__c = 'Active',
                Country__c = 'Germany',
                Approved__c = true,
                Name = 'New test Contract'
        );
        insert newTestContract;

        System.Test.startTest();
        System.runAs(testUser) {
            //Meter
            Boolean entTrue = msUtility.checkObjectAccess(siteRoles[0].Meter__c, 'Meter__c');
            System.assert(entTrue == true, 'Failure for true meter');

            try {
                msUtility.checkObjectAccess(newTestMeter.Id, 'Meter__c');
                System.assert(false, 'User should not have access');
            } catch (AuraHandledException e) {
                System.debug(e.getMessage());
            }

            //Contract
            Boolean conTrue = msUtility.checkObjectAccess(contractRoles[0].Contract__c, 'Contract__c');
            System.assert(conTrue == true, 'Failure for true contract');

            try {
                msUtility.checkObjectAccess(newTestContract.Id, 'Contract__c');
                System.assert(false, 'User should not have access');
            } catch (AuraHandledException e) {
                System.debug(e.getMessage());
            }
        }
        System.Test.stopTest();

    }

    @IsTest
    private static void testStringToDateParsing() {
//        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
//        PIM-451
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE LastName = 'DEuser' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            Datetime dt = msUtility.parseUtcDateTime('2019-02-20T00:00:00Z');
            System.assertEquals(Datetime.newInstanceGmt(2019, 2, 20, 0, 0, 0), dt);
        }
        System.Test.stopTest();
    }

    @IsTest
    private static void testGetMarkets() {
//        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
//        PIM-451
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE LastName = 'DEuser' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            Set<String> markets = msUtility.getUserMarkets();
            System.assert(markets.contains('Germany'), 'testUser should be mapped to Germany');
        }
        System.Test.stopTest();
    }


    @IsTest
    private static void testGetUserDetails() {
//        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
//        PIM-451
        User testUser = [SELECT Id, Name, ContactId,Username,IsActive FROM User WHERE LastName = 'DEuser' LIMIT 1];

        List<Contract__c>contracts = [SELECT Id, Country__c, Global_Portal_Market__c FROM Contract__c];
        for (Contract__c tempContract : contracts) {
            System.debug(tempContract);
        }

        System.debug('testUserDetails ' + testUser);
        System.Test.startTest();
        System.runAs(testUser) {
            msUtility.getUserDetails();
            System.Test.stopTest();
        }
    }

    @IsTest
    private static void testGetMarketFeatures() {
//        Meter__c testMeter = [SELECT Id FROM Meter__c WHERE Name = 'Meter1' LIMIT 1];
//        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
//        PIM-451
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE LastName = 'DEuser' LIMIT 1];
        Meter__c testMeter = [SELECT Id FROM Meter__c WHERE Name LIKE 'deMeter%' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            msUtility.getMeterFeatures(testMeter);
            System.Test.stopTest();
        }
    }

    @IsTest
    private static void testGetAllTimeSeriesSettings() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE LastName = 'DEuser' LIMIT 1];
        System.runAs(testUser) {
            System.Test.startTest();
            Map<String, Statkraft_TimeSeries_Settings__mdt> settings = msUtility.getAllTimeSeriesSettings();
            System.Test.stopTest();
            System.assertNotEquals(null, settings, 'Timeseries settings could not be loaded');
        }
    }

    @IsTest
    static void testBackendMonitoring() {
        BackendMonitoring__e logEvent = msUtility.getEvent('Test Event');
        try {
            msUtility.ifTestThrowFakeException();
        } catch (Exception e) {
            logEvent = msUtility.handleException(logEvent, e);
        } finally {
            msUtility.publishEvent(logEvent);
        }
    }

    @IsTest
    private static void getValidationPassesTest() {
        msUtility.getValidationPasses();
    }
}