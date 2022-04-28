/****************************************************************************************************
* Class msDataProtectionControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   22.05.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   22.05.2020      	    Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msDataProtectionControllerTest {

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }
    @IsTest
    private static void testGerman(){
        User user = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder().setBody('<div>Dies ist ein Test</div>').build();
        endpointToResponseMap.put(msUtility.getPortalSettings().DataProtectionDE__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        Test.startTest();
        System.runAs(user) {
            msDataProtectionController.getDataProtection();
        }
        Test.stopTest();
    }
    @IsTest
    private static void testFrench(){
        User user = [SELECT Id FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder().setBody('<div>Ceci est un test</div>').build();
        endpointToResponseMap.put(msUtility.getPortalSettings().DataProtectionFR__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        Test.startTest();
        System.runAs(user) {
            msDataProtectionController.getDataProtection();
        }
        Test.stopTest();
    }
    @IsTest
    private static void testEnglish(){
        User user = [SELECT Id FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder().setBody('<div>This is a Test</div>').build();
        endpointToResponseMap.put(msUtility.getPortalSettings().DataProtectionEN__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        Test.startTest();
        System.runAs(user) {
            msDataProtectionController.getDataProtection();
        }
        Test.stopTest();
    }
}