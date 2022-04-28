/**
 * Created by frank on 07.10.2018.
 */
@IsTest
public with sharing class msRestResourceInformationTest {

    static testmethod void testRestRequestItems() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/information/request_items';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceInformation.information();
        Test.stopTest();
        system.assert(res.statusCode == 200, 'The request was not successfull.');

    }
    static testmethod void testRestLanguageKeys() {

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/information/language_keys';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceInformation.information();
        Test.stopTest();
        system.assert(res.statusCode == 200, 'The request was not successfull.');

    }
    static testmethod void testRestMessageTypes() {

        msTestDataFactory.createTestRecords();
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/information/message_types';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceInformation.information();
        Test.stopTest();
        system.debug(res.responseBody.toString());
        system.assert(res.statusCode == 200, 'The request was not successfull.');

    }
    static testmethod void testRestMessageTypesFailure() {

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/information/message_types';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceInformation.information();
        Test.stopTest();
        system.debug(res.responseBody.toString());
       // system.assert(res.statusCode == 400, 'The request was not successfull.');

    }
    static testmethod void testRestFailure() {

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/information/failure';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceInformation.information();
        Test.stopTest();
        system.assert(res.statusCode == 400, 'Failure does not work.');

    }
    static testmethod void testRestFailure2() {

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/information';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceInformation.information();
        Test.stopTest();
        system.assert(res.statusCode == 400, 'Failure does not work.');
    }
}