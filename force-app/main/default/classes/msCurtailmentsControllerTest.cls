/****************************************************************************************************
* Class msCurtailmentsControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   25.09.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   25.09.2018      	    Init version.
*****************************************************************************************************/

@IsTest
private class msCurtailmentsControllerTest {
    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }
    @IsTest
    private static void testGetCurtailment(){

        Meter__c meter= [SELECT Id FROM Meter__c WHERE Name = 'deMeter1'];
        meter.Portfolio_ID__c = 'mt_de_bwp_westerhausen';
        update meter;

        User user = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Test.setCurrentPageReference(new PageReference('msCurtailmentDownload.page'));
        Map<String, String> parameterMap = System.currentPageReference().getParameters();
        parameterMap.put('plantid', meter.Id);
        parameterMap.put('startDate', JSON.serialize(Datetime.now().addDays(-10)).replace('"', ''));
        parameterMap.put('endDate', JSON.serialize(Datetime.now()).replace('"', ''));
        parameterMap.put('isMrl', 'false');

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"meteringPoint": "mt_de_bwp_westerhausen","startTime": "2019-08-01T07:45:00Z","endTime": "2019-08-01T07:45:00Z","isValid": true, "type": "Downreg","lastModifiedUser": "Michael","lastModifiedTime": "2019-09-19T07:40:27","points": [{"ts": "2019-08-01T07:30:00Z","originalLevel": null,"correctedLevel": null,"metering":21.001},{"ts": "2019-08-01T07:45:00Z","originalLevel": 20.0,"correctedLevel": 25.0,"metering":45.14},{"ts": "2019-08-01T08:00:00Z","originalLevel": null,"correctedLevel": null,"metering":25.45}]}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Curtailments_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        Test.startTest();

        System.runAs(user) {
            msCurtailmentsController controller = new msCurtailmentsController();
            controller.getCurtailment();
        }

        Test.stopTest();
    }
    @IsTest
    private static void testCanDeserializeTimestamp() {
        Test.startTest();
        String ts = '[{"name":"/as_fr_ensinet1/regulation/power/ems/default","values":[{"timeDate":"2018-11-17T13:00:00Z","value":15.0}, {"timeDate":"2018-11-17T13:00:00Z","value":15.0}]}]';
        List<msCurtailmentsController.TimeSeries> p = (List<msCurtailmentsController.TimeSeries>) System.JSON.deserializeStrict(ts, List<msCurtailmentsController.TimeSeries>.class);
        System.debug('ts deserialized to ' + p);
        System.assert(p != null, 'Failed to parse object ' + ts);
        System.assert(p.size() > 0, 'Failed to parse object ' + ts);
        Test.stopTest();
    }
    @IsTest
    private static void testGetSeries() {

        Meter__c meter= [SELECT Id FROM Meter__c WHERE Name = 'deMeter1'];
        meter.Portfolio_ID__c = 'mt_de_bwp_westerhausen';
        update meter;
        String plantId = meter.Id;
        User testuser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"meteringPoint": "mt_de_bwp_westerhausen","startTime": "2019-08-01T07:45:00Z","endTime": "2019-08-01T07:45:00Z","isValid": true, "type": "Downreg", "lastModifiedUser": "Michael","lastModifiedTime": "2019-09-19T07:40:27","points": [{"ts": "2019-08-01T07:30:00Z","originalLevel": null,"correctedLevel": null,"metering":21.001},{"ts": "2019-08-01T07:45:00Z","originalLevel": 20.0,"correctedLevel": 25.0,"metering":45.14},{"ts": "2019-08-01T08:00:00Z","originalLevel": null,"correctedLevel": null,"metering":25.45}]}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Curtailments_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        Test.startTest();
        System.runAs(testuser) {
            msCurtailmentsController.getCurtailments(plantId, false);
        }
        Test.stopTest();
    }
    @IsTest
    private static void testSetCurtailment() {
        Meter__c meter= [SELECT Id FROM Meter__c WHERE Name = 'deMeter1'];
        meter.Portfolio_ID__c = 'mt_de_bwp_westerhausen';
        update meter;
        String plantId = meter.Id;
        User testuser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"meteringPoint":"mt_de_bwp_westerhausen","startTime":"2019-08-01T07:45:00Z","endTime":"2019-08-01T07:45:00Z","isValid":true,"lastModifiedUser":"Michael","lastModifiedTime":"2019-09-19T07:40:27","points": [{"ts": "2019-08-01T07:45:00Z","originalLevel": 20.0,"correctedLevel": 25.0}]}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Curtailments_Endpoint_Read__c, responseSuccess);
        endpointToResponseMap.put(msUtility.getMetadata().Curtailments_Endpoint_Write__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        Test.startTest();
        //Datetime startDate, Boolean paragraph51, Boolean changeParagraph51

        Datetime testDate = Datetime.valueOf('2018-09-12 03:15:00.000');

        System.runAs(testuser) {
            msCurtailmentsController.setCurtailment(plantId, '[{"startDate":"2018-09-12T03:15:00.000Z","value":"98"},{"startDate":"2018-09-12T03:30:00.000Z","value":"100"}]', testDate);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testCurtailmentsRetreivalError(){

        Meter__c meter= [SELECT Id FROM Meter__c WHERE Name = 'deMeter1'];
        meter.Portfolio_ID__c = 'mt_de_bwp_westerhausen';
        update meter;
        String plantId = meter.Id;
        User testuser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseError = new msCalloutMock.MockResponseBuilder()
                .build();

        responseError.setStatus('ERROR');
        responseError.setStatusCode(500);

        endpointToResponseMap.put(msUtility.getMetadata().Curtailments_Endpoint_Read__c, responseError);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        Test.startTest();
        System.runAs(testuser) {
            String result = msCurtailmentsController.getCurtailments(plantId, false);
            System.assert(result == null);
        }
        Test.stopTest();
    }
}