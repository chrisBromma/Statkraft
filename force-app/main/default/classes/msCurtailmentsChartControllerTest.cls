/**
 * Created by frank on 19.09.2018.
 */
@IsTest
private class msCurtailmentsChartControllerTest {

    @IsTest
    private static void testGetSeries() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c meter = [SELECT Id FROM Meter__c WHERE Name = 'deMeter1' AND Portfolio_ID__c != NULL LIMIT 1];

        String plantId = meter.Id;
        String startDate = '2018-01-01T00:00:00';
        String endDate = '2018-01-01T10:00:00';
        List<Object> returnList = new List<Object>();

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"name":"/charting/downregulation/series/","values":[{"time":"2019-08-01T07:45:00Z","value":0.3},{"time":"2019-08-02T07:45:00Z","value":0.5}]},{"name":"/charting/production/series/","values":[{"time":"2019-08-01T07:45:00Z","value":0.3},{"time":"2019-08-02T07:45:00Z","value":0.5}]}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Time_Series_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        System.Test.startTest();
        System.runAs(testUser) {
            returnList = msCurtailmentsChartController.getSeries(plantId, startDate, endDate);
            System.Test.stopTest();
        }
        System.assert(returnList.size() > 0, 'The resulting list is empty');
        System.assert(returnList.size() > 1, 'not all Series was added to the resulting list.');
        System.assert(returnList.size() < 3, 'to much Series was added to the resulting list.');
    }

    @IsTest
    private static void testImage() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Meter__c meter = [SELECT Id FROM Meter__c WHERE Name = 'deMeter1' AND Portfolio_ID__c != NULL LIMIT 1];
        String plantId = meter.Id;

        system.Test.startTest();
        System.runAs(testUser) {
            msCurtailmentsChartController.getImage('test', plantId);
            system.Test.stopTest();
        }
    }

    @TestSetup
    static void setup(){
        msTestDataFactory.createTestPortalContext();
    }
}