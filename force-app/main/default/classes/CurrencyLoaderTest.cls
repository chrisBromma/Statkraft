@isTest
public with sharing class CurrencyLoaderTest {
    public static Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();

    @TestSetup
    private static void setUp() {
		msGranularTestDataFactory.createLoggerSetting();
    }

    @isTest
    public static void testGetApiToken() {
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        System.Test.startTest();
        String token = CurrencyLoader.getApiToken();
        System.Test.stopTest();

        System.assertEquals('1234', token);
    }

    @isTest
    public static void testExecuteSuccess() {
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();

        HttpResponse responseConversionRate = new HttpResponse();
        responseConversionRate.setHeader('Content-Type', 'application/json');
        responseConversionRate.setStatus('OK');
        responseConversionRate.setStatusCode(200);
        responseConversionRate.setBody('{"frequencyDefinition":{"olsonTimeZone":"Etc/GMT","anchor":637492896000000000,"frequencyBase":"Daily","frequencyMultiplier":1},"indexName":"FX_RATE/SPOT/FX/_/MID/ECB/EUR/USD/B","ticks":[637492896000000000],"values":[1.2139],"endTime":637493760000000000,"fixedFrequency":true}');
        endpointToResponseMap.put(ApiSettings.BlueSeaEndpoint__c, responseConversionRate);

        HttpResponse responseSaving = new HttpResponse();
        responseSaving.setHeader('Content-Type', 'application/json');
        responseSaving.setStatus('OK');
        responseSaving.setStatusCode(200);
        responseSaving.setBody('[{"id":"04w1q00000005vTAAQ","success":true,"errors":[]},{"id":"04w1q00000005vUAAQ","success":true,"errors":[]},{"id":"04w1q00000005vVAAQ","success":true,"errors":[]},{"id":"04w1q00000005vWAAQ","success":true,"errors":[]},{"id":"04w1q00000005vXAAQ","success":true,"errors":[]},{"id":"04w1q00000005vYAAQ","success":true,"errors":[]},{"id":"04w1q00000005vZAAQ","success":true,"errors":[]},{"id":"04w1q00000005vaAAA","success":true,"errors":[]},{"id":"04w1q00000005vbAAA","success":true,"errors":[]},{"id":"04w1q00000005vcAAA","success":true,"errors":[]},{"id":"04w1q00000005vdAAA","success":true,"errors":[]}]');
        endpointToResponseMap.put(URL.getSalesforceBaseUrl().toExternalForm(), responseSaving);

        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        System.Test.startTest();
        CurrencyLoader myLoader = new CurrencyLoader();
        System.enqueueJob(myLoader);
        System.Test.stopTest();
    }

    @isTest
    public static void testExecuteNaN() {
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();

        HttpResponse responseConversionRate = new HttpResponse();
        responseConversionRate.setHeader('Content-Type', 'application/json');
        responseConversionRate.setStatus('OK');
        responseConversionRate.setStatusCode(200);
        responseConversionRate.setBody('{"frequencyDefinition":{"olsonTimeZone":"Etc/GMT","anchor":637492896000000000,"frequencyBase":"Daily","frequencyMultiplier":1},"indexName":"FX_RATE/SPOT/FX/_/MID/ECB/EUR/USD/B","ticks":[637492896000000000],"values":["NaN"],"endTime":637493760000000000,"fixedFrequency":true}');
        endpointToResponseMap.put(ApiSettings.BlueSeaEndpoint__c, responseConversionRate);

        HttpResponse responseSaving = new HttpResponse();
        responseSaving.setHeader('Content-Type', 'application/json');
        responseSaving.setStatus('OK');
        responseSaving.setStatusCode(200);
        responseSaving.setBody('[{"id":"04w1q00000005vTAAQ","success":true,"errors":[]},{"id":"04w1q00000005vUAAQ","success":true,"errors":[]},{"id":"04w1q00000005vVAAQ","success":true,"errors":[]},{"id":"04w1q00000005vWAAQ","success":true,"errors":[]},{"id":"04w1q00000005vXAAQ","success":true,"errors":[]},{"id":"04w1q00000005vYAAQ","success":true,"errors":[]},{"id":"04w1q00000005vZAAQ","success":true,"errors":[]},{"id":"04w1q00000005vaAAA","success":true,"errors":[]},{"id":"04w1q00000005vbAAA","success":true,"errors":[]},{"id":"04w1q00000005vcAAA","success":true,"errors":[]},{"id":"04w1q00000005vdAAA","success":true,"errors":[]}]');
        endpointToResponseMap.put(URL.getSalesforceBaseUrl().toExternalForm(), responseSaving);

        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        System.Test.startTest();
        CurrencyLoader myLoader = new CurrencyLoader();
        System.enqueueJob(myLoader);
        System.Test.stopTest();
    }

    @isTest
    public static void testExecuteError() {
        Statkraft_API_Settings__mdt ApiSettings = Statkraft_API_Settings__mdt.getInstance('Production'); //msUtility.getMetadata();

        HttpResponse responseConversionRate = new HttpResponse();
        responseConversionRate.setHeader('Content-Type', 'application/json');
        responseConversionRate.setStatus('Error');
        responseConversionRate.setStatusCode(400);
        responseConversionRate.setBody('{"frequencyDefinition":"NaN","message":"Something went wrong","values":["NaN"]}');
        endpointToResponseMap.put(ApiSettings.BlueSeaEndpoint__c, responseConversionRate);

        HttpResponse responseSaving = new HttpResponse();
        responseSaving.setHeader('Content-Type', 'application/json');
        responseSaving.setStatus('OK');
        responseSaving.setStatusCode(400);
        responseSaving.setBody('[{"id":"04w1q00000005vTAAQ","success":true,"errors":[]},{"id":"04w1q00000005vUAAQ","success":true,"errors":[]},{"id":"04w1q00000005vVAAQ","success":true,"errors":[]},{"id":"04w1q00000005vWAAQ","success":true,"errors":[]},{"id":"04w1q00000005vXAAQ","success":true,"errors":[]},{"id":"04w1q00000005vYAAQ","success":true,"errors":[]},{"id":"04w1q00000005vZAAQ","success":true,"errors":[]},{"id":"04w1q00000005vaAAA","success":true,"errors":[]},{"id":"04w1q00000005vbAAA","success":true,"errors":[]},{"id":"04w1q00000005vcAAA","success":true,"errors":[]},{"id":"04w1q00000005vdAAA","success":true,"errors":[]}]');
        endpointToResponseMap.put(URL.getSalesforceBaseUrl().toExternalForm(), responseSaving);

        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        System.Test.startTest();
        CurrencyLoader myLoader = new CurrencyLoader();
        System.enqueueJob(myLoader);
        System.Test.stopTest();
    }

    @isTest
    public static void testExecuteSavingFailed() {
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();

        HttpResponse responseConversionRate = new HttpResponse();
        responseConversionRate.setHeader('Content-Type', 'application/json');
        responseConversionRate.setStatus('OK');
        responseConversionRate.setStatusCode(200);
        responseConversionRate.setBody('{"frequencyDefinition":{"olsonTimeZone":"Etc/GMT","anchor":637492896000000000,"frequencyBase":"Daily","frequencyMultiplier":1},"indexName":"FX_RATE/SPOT/FX/_/MID/ECB/EUR/USD/B","ticks":[637492896000000000],"values":[1.2139],"endTime":637493760000000000,"fixedFrequency":true}');
        endpointToResponseMap.put(ApiSettings.BlueSeaEndpoint__c, responseConversionRate);

        HttpResponse responseSaving = new HttpResponse();
        responseSaving.setHeader('Content-Type', 'application/json');
        responseSaving.setStatus('OK');
        responseSaving.setStatusCode(200);
        responseSaving.setBody('[{"id":"04w1q00000005vTAAQ","success":false,"errors":[]},{"id":"04w1q00000005vUAAQ","success":true,"errors":[]},{"id":"04w1q00000005vVAAQ","success":true,"errors":[]},{"id":"04w1q00000005vWAAQ","success":true,"errors":[]},{"id":"04w1q00000005vXAAQ","success":true,"errors":[]},{"id":"04w1q00000005vYAAQ","success":true,"errors":[]},{"id":"04w1q00000005vZAAQ","success":true,"errors":[]},{"id":"04w1q00000005vaAAA","success":true,"errors":[]},{"id":"04w1q00000005vbAAA","success":true,"errors":[]},{"id":"04w1q00000005vcAAA","success":true,"errors":[]},{"id":"04w1q00000005vdAAA","success":true,"errors":[]}]');
        endpointToResponseMap.put(URL.getSalesforceBaseUrl().toExternalForm(), responseSaving);

        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        System.Test.startTest();
        CurrencyLoader myLoader = new CurrencyLoader();
        System.enqueueJob(myLoader);
        System.Test.stopTest();
    }
}