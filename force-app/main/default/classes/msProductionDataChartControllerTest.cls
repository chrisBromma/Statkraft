/****************************************************************************************************
* Class msProductionDataChartControllerTest
*
*   Create By	:   Macjei Dudek (mindsquare GmbH)
*   Create Date	:
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Maciej Dudek (mindsquare GmbH)        -      	                Init version.
*   * Lukasz Bak (mindsquare GmbH)          -      	                Updated for new UK requirements
*****************************************************************************************************/

@IsTest
private class msProductionDataChartControllerTest {

    @TestSetup
    static void setup(){
        msTestDataFactory.createTestPortalContext();
    }

    private static final String EXPECTED_RESULT =
            '{"rows":[["ts","/mt_de3_bwp_westerhausen/forecast/power/ems/default"],[1562637600000,10.0]],"columns": [["ts",1567296000000,1567297800000],["Schedule",10,10],["Availability", 20, 20]]}';


    private static void testSetupMock() {
        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new HttpResponse();
        responseSuccess.setHeader('Content-Type', 'application/json');
        responseSuccess.setStatus('OK');
        responseSuccess.setStatusCode(200);
        responseSuccess.setBody(EXPECTED_RESULT);
        endpointToResponseMap.put(msUtility.getMetadata().Charting_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
    }

    @IsTest
    private static void testGetChartResults() {
        msProductionDataChartController.ChartResult results = null;
        testSetupMock();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.runAs(testUser) {
            msUtility.UserDetails userDetails = msUtility.getUserDetails();
            Datetime startDate = Datetime.now();
            Datetime endDate = Datetime.now().addDays(2);
            List<String> plantIds = new List<String>();
            plantIds.add(userDetails.plants[0].Id);
            Test.startTest();
            results = msProductionDataChartController.getChartResult(plantIds, startDate, endDate, 'default', 'MW');
            Test.stopTest();
        }
        System.debug(results);
        System.assertNotEquals(null, results);
    }

    @IsTest
    private static void testGetOverviewChartResults() {
        msProductionDataChartController.ChartResult results = null;
        testSetupMock();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.runAs(testUser) {
            msUtility.UserDetails userDetails = msUtility.getUserDetails();
            Datetime startDate = Datetime.now();
            Datetime endDate = Datetime.now().addDays(2);
            List<String> plantIds = new List<String>();
            plantIds.add(userDetails.plants[0].Id);
            Test.startTest();
            results = msProductionDataChartController.getChartResult(plantIds, startDate, endDate, 'overview','MW');
            Test.stopTest();
        }

        System.debug(results);
        System.assertNotEquals(null, results);
    }

    @IsTest
    private static void testGetUKFlexCashflowsChartResults() {
        msProductionDataChartController.ChartResult results = null;
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        testSetupMock();
        
        System.runAs(testUser) {
            msUtility.UserDetails userDetails = msUtility.getUserDetails();
            Datetime startDate = Datetime.now();
            Datetime endDate = Datetime.now().addDays(2);
            List<String> plantIds = new List<String>();
            plantIds.add(userDetails.plants[0].Id);
            Test.startTest();
            results = msProductionDataChartController.getChartResult(plantIds, startDate, endDate, 'chart_pnl', 'MW');
            Test.stopTest();
        }

        System.debug(results);
        System.assertNotEquals(null, results);
    }

    @IsTest
    private static void testGetUKFlexMeteringChartResults() {
        msProductionDataChartController.ChartResult results = null;
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        testSetupMock();

        System.runAs(testUser) {
            msUtility.UserDetails userDetails = msUtility.getUserDetails();
            Datetime startDate = Datetime.now();
            Datetime endDate = Datetime.now().addDays(2);
            List<String> plantIds = new List<String>();
            plantIds.add(userDetails.plants[0].Id);
            Test.startTest();
            results = msProductionDataChartController.getChartResult(plantIds, startDate, endDate, 'chart_prod', 'MW');
            Test.stopTest();
        }

        System.debug(results);
        System.assertNotEquals(null, results);
    }
}