/****************************************************************************************************
* Class msSubmeterControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   11.10.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)        11.10.2018      	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      29.05.2019      	    Version for new msSubmeter
*****************************************************************************************************/


@IsTest
public with sharing class msSubmeterControllerTest {

    @TestSetup public static void generateTestData() {
        msTestDataFactory.createTestPortalContext();

        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Portfolio_ID__c != NULL AND Country__c = 'Germany' LIMIT 1];
        List<Generation_Unit__c> deGenerationUnits = new List<Generation_Unit__c>();
        deGenerationUnits.add(new Generation_Unit__c(
                Name = 'DE Generation Unit SubTest 1',
                Annual_Production__c = 320,
                Portfolio_ID__c = 'as_de2_an_00510_windpark_slo',
                Country__c = 'Germany'
        ));
        deGenerationUnits.add(new Generation_Unit__c(
                Name = 'DE Generation Unit SubTest 2',
                Annual_Production__c = 320,
                Portfolio_ID__c = 'as_de2_an_00511_windpark_slo',
                Country__c = 'Germany'
        ));
        insert(deGenerationUnits);
        List<Meter2GenerationUnitRelationship__c> m2gRelList = new List<Meter2GenerationUnitRelationship__c>();
        m2gRelList.add(new Meter2GenerationUnitRelationship__c (
                Name = 'DE Meter 2 Generation Unit Relationship SubTest 1',
                Meter__c = testMeter.Id,
                Generator_Unit__c = deGenerationUnits[0].Id,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = null,
                Active__c = true));
        m2gRelList.add(new Meter2GenerationUnitRelationship__c (
                Name = 'DE Meter 2 Generation Unit Relationship SubTest 2',
                Meter__c = testMeter.Id,
                Generator_Unit__c = deGenerationUnits[1].Id,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = null,
                Active__c = true));
        insert(m2gRelList);

    }

    @IsTest
    static void testAddSubmeterSuccess() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccessWrite = new HttpResponse();
        responseSuccessWrite.setHeader('Content-Type', 'application/json');
        responseSuccessWrite.setStatus('OK');
        responseSuccessWrite.setStatusCode(200);
        responseSuccessWrite.setBody('[]');
        endpointToResponseMap.put(msUtility.getMetadata().Submeter_Endpoint_Write__c, responseSuccessWrite);

        HttpResponse responseSuccessRead = new HttpResponse();
        responseSuccessRead.setHeader('Content-Type', 'application/json');
        responseSuccessRead.setStatus('OK');
        responseSuccessRead.setStatusCode(200);
        responseSuccessRead.setBody('[{"name":"/as_de2_an_00510_windpark_slo/sub_meter/power/portal/monthly","values":[{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T01:00:00Z","value":99.54},' +
                '{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T04:00:00Z","value":99.54}]},' +
                '{"name":"/as_de2_an_00511_windpark_slo/sub_meter/power/portal/monthly","values":[{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T01:00:00Z","value":99.54},' +
                '{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T04:00:00Z","value":99.54}]}]');
        endpointToResponseMap.put(msUtility.getMetadata().Submeter_Endpoint_Read__c, responseSuccessRead);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter2GenerationUnitRelationship__c testConnection = [
                SELECT Id, Meter__c, Generator_Unit__c, Generator_Unit__r.Portfolio_ID__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Meter__r.Portfolio_ID__c != NULL
                AND Generator_Unit__r.Portfolio_ID__c != NULL
                AND Meter__r.Country__c = 'Germany'
                AND Meter__c IN (
                        SELECT Meter__c
                        FROM Site_Role__c
                        WHERE Contact__c = :testUser.ContactId
                )
                LIMIT 1
        ];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Portfolio_ID__c != NULL AND Country__c = 'Germany' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            List<msSubmeterController.SubmeterSeries> testSeriesList = new List<msSubmeterController.SubmeterSeries>();
            msSubmeterController.SubmeterSeries testSeries = new msSubmeterController.SubmeterSeries();
            testSeries.name = testConnection.Generator_Unit__r.Portfolio_ID__c;
            testSeries.portfolioId = testConnection.Generator_Unit__r.Portfolio_ID__c;
            testSeries.values = new List<msSubmeterController.SubmeterEntry>();

            msSubmeterController.SubmeterEntry testEntry = new msSubmeterController.SubmeterEntry();
            testEntry.startDate = (Date.today().year() - 1) + '-01-01T00:00:00Z';
            testEntry.value = '1350';

            testSeries.values.add(testEntry);
            testSeriesList.add(testSeries);

            msSubmeterController.addSubmeter(new List<Id>{testConnection.Meter__c}, testSeriesList, 'yearly', testMeter.Id, ('' + Date.today().year()));
            System.Test.stopTest();
        }
    }

    @IsTest
    static void testAddSubmeterError() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccessWrite = new HttpResponse();
        responseSuccessWrite.setHeader('Content-Type', 'application/json');
        responseSuccessWrite.setStatus('ERROR');
        responseSuccessWrite.setStatusCode(404);
        endpointToResponseMap.put(msUtility.getMetadata().Submeter_Endpoint_Write__c, responseSuccessWrite);

        HttpResponse responseSuccessRead = new HttpResponse();
        responseSuccessRead.setHeader('Content-Type', 'application/json');
        responseSuccessRead.setStatus('OK');
        responseSuccessRead.setStatusCode(200);
        responseSuccessRead.setBody('[{"name":"/as_de2_an_00510_windpark_slo/sub_meter/power/portal/monthly","values":[{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T01:00:00Z","value":99.54},' +
                '{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T04:00:00Z","value":99.54}]},' +
                '{"name":"/as_de2_an_00511_windpark_slo/sub_meter/power/portal/monthly","values":[{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T01:00:00Z","value":99.54},' +
                '{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T04:00:00Z","value":99.54}]}]');
        endpointToResponseMap.put(msUtility.getMetadata().Submeter_Endpoint_Read__c, responseSuccessRead);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter2GenerationUnitRelationship__c testConnection = [
                SELECT Id, Meter__c, Generator_Unit__c, Generator_Unit__r.Portfolio_ID__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Meter__r.Portfolio_ID__c != NULL
                AND Generator_Unit__r.Portfolio_ID__c != NULL
                AND Meter__r.Country__c = 'Germany'
                AND Meter__c IN (
                        SELECT Meter__c
                        FROM Site_Role__c
                        WHERE Contact__c = :testUser.ContactId
                )
                LIMIT 1
        ];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Portfolio_ID__c != NULL AND Country__c = 'Germany' LIMIT 1];

        System.Test.startTest();
        System.runAs(testUser) {
            List<msSubmeterController.SubmeterSeries> testSeriesList = new List<msSubmeterController.SubmeterSeries>();
            msSubmeterController.SubmeterSeries testSeries = new msSubmeterController.SubmeterSeries();
            testSeries.name = testConnection.Generator_Unit__r.Portfolio_ID__c;
            testSeries.portfolioId = testConnection.Generator_Unit__r.Portfolio_ID__c;
            testSeries.values = new List<msSubmeterController.SubmeterEntry>();

            msSubmeterController.SubmeterEntry testEntry = new msSubmeterController.SubmeterEntry();
            testEntry.startDate = (Date.today().year() - 1) + '-01-01T00:00:00Z';
            testEntry.value = '1350';

            testSeries.values.add(testEntry);
            testSeriesList.add(testSeries);

            msSubmeterController.addSubmeter(new List<Id>{testConnection.Meter__c}, testSeriesList, 'yearly', testMeter.Id, ('' + Date.today().year()));
            System.Test.stopTest();
        }
    }

    @IsTest
    static void testRetrieveSubmeter() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new HttpResponse();
        responseSuccess.setHeader('Content-Type', 'application/json');
        responseSuccess.setStatus('OK');
        responseSuccess.setStatusCode(200);
        responseSuccess.setBody('[{"name":"/as_de2_an_00510_windpark_slo/sub_meter/power/portal/monthly","values":[{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T01:00:00Z","value":99.54},' +
                '{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T04:00:00Z","value":99.54}]},' +
                '{"name":"/as_de2_an_00511_windpark_slo/sub_meter/power/portal/monthly","values":[{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T01:00:00Z","value":99.54},' +
                '{"metadata":{"modifiedUser":"abc","modifiedDate":"2020-09-11T07:01:23.013Z"},"time":"2020-01-01T04:00:00Z","value":99.54}]}]');
        endpointToResponseMap.put(msUtility.getMetadata().Submeter_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Portfolio_ID__c != NULL AND Country__c = 'Germany' LIMIT 1];
        String year = '' + Date.today().year();

        System.Test.startTest();
        System.runAs(testUser) {
            List<msSubmeterController.SubmeterSeries> submeterSeries = msSubmeterController.retrieveSubmeter(testMeter.Id, year).values;
            System.assert(submeterSeries.size() == 2, 'The Callout Mock includes 2 data sets and so should the submeterSeriesList');
            System.assert(!submeterSeries[0].values.isEmpty(), 'The Callout contains values and so should the values of Series [0]');

            Map<String, List<msSubmeterController.SubmeterSeries>> submeterCSVResult = msSubmeterController.retrieveSubmeterForCSV(new List<Id>{testMeter.Id}, year);
            System.assert(submeterCSVResult.keySet().size() == 1, 'The Callback should yield a result of one meter');
            for (String meterName : submeterCSVResult.keySet()) {
                System.assert(submeterCSVResult.get(meterName).size() == 2, 'The Callout should yield 2 entries for GenUnits');
                System.assert(!submeterCSVResult.get(meterName)[0].values.isEmpty(), 'There should be values stored in the time series');
            }

        }
        System.Test.stopTest();
    }

    @IsTest
    static void testRetrieveSubmeterError() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseError = new HttpResponse();
        responseError.setHeader('Content-Type', 'application/json');
        responseError.setStatus('ERROR');
        responseError.setStatusCode(404);
        endpointToResponseMap.put(msUtility.getMetadata().Submeter_Endpoint_Read__c, responseError);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c testMeter = [SELECT Id, Name FROM Meter__c WHERE Portfolio_ID__c != NULL AND Country__c = 'Germany' LIMIT 1];
        String year = '' + Date.today().year();

        System.Test.startTest();
        System.runAs(testUser) {
            msSubmeterController.SubmeterResultWrapper submeterSeries = msSubmeterController.retrieveSubmeter(testMeter.Id, year);
            System.assert(submeterSeries == null, 'Should not serve any values because of error');
        }
        System.Test.stopTest();
    }
}