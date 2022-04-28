/****************************************************************************************************
* Class msMenuBarController
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   07.10.2018
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)        07.10.2018      	    Init version.
*   * Steffen Naundorf (mindsquare GmbH)    02.05.2019              V2 for New Core Model
*****************************************************************************************************/
@IsTest
private with sharing class msRestREsourceNotificationsTest {

    @TestSetup
    private static void testSetup(){
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    private static void testRestFailureId() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "a0F1j0000004EqlEAE",' +
                '"ObjectType": "Meter__c",' +
                '"Subject":"Hello World",' +
                '"Body": "This is just a awsome test.",' +
                '"MessageType":"email",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure id does not work');
    }

    @IsTest
    private static void testRestFailureAttributes() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "a0F1j0000004EqlEAE",' +
                '"ObjectType": "Meter__c",' +
                '"Subject":"Hello World",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure attributes does not work');
    }

    @IsTest
    private static void testRestFailureObjectType() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "a0F1j0000004EqlEAE",' +
                '"ObjectType": "ABCD",' +
                '"Subject":"Hello World",' +
                '"Body": "This is just a awsome test.",' +
                '"MessageType":"email",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure object type does not work');
    }

    @IsTest
    private static void testRestFailureMessageType() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "a0F1j00XXX04EqlEAE",' +
                '"ObjectType": "Meter__c",' +
                '"Subject":"Hello World",' +
                '"Body": "This is just a awsome test.",' +
                '"MessageType":"new_invoice",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure message type does not work');
    }

    @IsTest
    private static void testRestSuccess() {
        Meter__c met = [SELECT Id FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "' + met.Id + '", '+
                '"ObjectType": "Meter__c",' +
                '"Subject":"Hello World",' +
                '"Body": "This is just an awesome test.",' +
                '"MessageType":"pp1_pp2_daily",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        msRestResourceNotifications.information();

        Test.stopTest();
        System.assert(res.statusCode == 200, 'Request does not work with correct credentials.');
    }

    @IsTest
    private static void testRestFailureBodyRequest() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure body request does not work');
    }

    @IsTest
    private static void testRestFailureSubject() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "a0F1j0000004EqlEAE",' +
                '"ObjectType": "Meter__c",' +
                '"Subject":"",' +
                '"Body": "This is just a awsome test.",' +
                '"MessageType":"test1",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure subject does not work');
    }

    @IsTest
    private static void testRestFailureBodyNotification() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "a0F1j0000004EqlEAE",' +
                '"ObjectType": "Meter__c",' +
                '"Subject":"Hello World",' +
                '"Body": "",' +
                '"MessageType":"test1",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure notification body does not work');
    }

    @IsTest
    private static void testRestFailureLanguageKey() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "a0F1j0000004EqlEAE",' +
                '"ObjectType": "Meter__c",' +
                '"Subject":"Hello World",' +
                '"Body": "Test",' +
                '"MessageType":"test1",' +
                '"Language":"abcdef"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure language key does not work');
    }

    @IsTest
    private static void testRestFailureUser() {
        Meter__c met = new Meter__c();
        met.Alternative_Meter_ID__c = '12345678901';
        insert met;
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl() + '/services/apexrest/notification';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String body = '{"Id": "' + met.Id + '", '+
                '"ObjectType": "Meter__c",' +
                '"Subject":"Hello World",' +
                '"Body": "This is just an awesome test.",' +
                '"MessageType":"test1",' +
                '"Language":"en_US"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        msRestResourceNotifications.information();
        System.debug(res.statusCode);
        System.debug(res.responseBody.toString());
        Test.stopTest();
        System.assert(res.statusCode == 400, 'Failure dependent user does not work');
    }
}