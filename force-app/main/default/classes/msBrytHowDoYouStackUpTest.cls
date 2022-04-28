/**
 * Created by Fabian on 09.04.2019.
 */

@IsTest
public with sharing class msBrytHowDoYouStackUpTest {

    public static Integer thisYear = Date.today().year();

    @TestSetup public static void createTestData() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest public static void testGetSeriesForChart() {
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"meteringPoint": "mt_de_bwp_westerhausen","startTime": "2019-08-01T07:45:00Z","endTime": "2019-08-01T07:45:00Z","isValid": true,"lastModifiedUser": "Michael","lastModifiedTime": "2019-09-19T07:40:27","points": [{"ts": "2019-08-01T07:30:00Z","originalLevel": null,"correctedLevel": null,"metering":21.001},{"ts": "2019-08-01T07:45:00Z","originalLevel": 20.0,"correctedLevel": 25.0,"metering":45.14},{"ts": "2019-08-01T08:00:00Z","originalLevel": null,"correctedLevel": null,"metering":25.45}]}]')
                .build();
        endpointToResponseMap.put(apiSettings.Time_Series_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        String [] selectedProduct = new String []{
                '2019', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Summer 19', '2020', 'Q1 19'
        };
        String startDate = String.valueOf(thisYear) + '-01-01T16:14:33+00:00';
        String endDate = String.valueOf(thisYear) + '-01-15T16:14:33+00:00';
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        Test.startTest();
        System.runAs(testUser) {
            msBrytHowDoYouStackUpBEC.getSeriesForChart(selectedProduct, startDate, endDate);
        }
        Test.stopTest();
    }

    @IsTest public static void testGetPc() {
        User testUser = [SELECT Id,ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        List<Contract_Role__c> cRList = [
                SELECT Contract__c
                FROM Contract_Role__c
                WHERE Contact__c = :testUser.ContactId
                AND RecordType.DeveloperName = 'Bryt_Contract_Role'
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today()
                OR End_Date__c = NULL)
                LIMIT 1
        ];
        Test.startTest();
        System.runAs(testUser) {
            msBrytHowDoYouStackUpBEC.getPc(cRList[0].Contract__c);
        }
        Test.stopTest();
    }

    @IsTest public static void testGetWrapper() {
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"meteringPoint": "mt_de_bwp_westerhausen","startTime": "2019-08-01T07:45:00Z","endTime": "2019-08-01T07:45:00Z","isValid": true,"lastModifiedUser": "Michael","lastModifiedTime": "2019-09-19T07:40:27","points": [{"ts": "2019-08-01T07:30:00Z","originalLevel": null,"correctedLevel": null,"metering":21.001},{"ts": "2019-08-01T07:45:00Z","originalLevel": 20.0,"correctedLevel": 25.0,"metering":45.14},{"ts": "2019-08-01T08:00:00Z","originalLevel": null,"correctedLevel": null,"metering":25.45}]}]')
                .build();
        endpointToResponseMap.put(apiSettings.Time_Series_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        User testUser = [SELECT Id,ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        List<Contract_Role__c> cRList = [
                SELECT Contract__c
                FROM Contract_Role__c
                WHERE Contact__c = :testUser.ContactId
                AND RecordType.DeveloperName = 'Bryt_Contract_Role'
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today()
                OR End_Date__c = NULL)
                LIMIT 1
        ];
        Test.startTest();
        String [] selectedProduct = new String []{
                'Apr 19', 'May 19', 'Jun 19', '2020', 'Q1 19', 'Summer 19'
        };
        String startDate = String.valueOf(thisYear) + '-01-01T16:14:33+00:00';
        String endDate = String.valueOf(thisYear) + '-01-15T16:14:33+00:00';
        System.runAs(testUser) {
            msBrytHowDoYouStackUpBEC.getWrapper(cRList[0].Contract__c, selectedProduct, startDate, endDate);
        }
        Test.stopTest();
    }
}