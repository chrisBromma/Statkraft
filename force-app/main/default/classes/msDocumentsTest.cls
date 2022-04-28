/****************************************************************************************************
* Class msDocumentsTest
*
*   Create By	:   Robert Pagels (mindsquare GmbH)
*   Create Date	:   24.09.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Robert Pagels (mindsquare GmbH)      24.09.2018      	    Init version.
*****************************************************************************************************/

@IsTest
private class msDocumentsTest {

    @TestSetup static void setup() {
        msTestDataFactory.createTestPortalContext();
        User userInfo = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Id conId = userInfo.ContactId;
        String documentTitle = 'FR_TYPE1_DATE201910_MPM100010_CN9058223623_CREATION20200114T153230';
        String documentTitleBs = 'BS_TYPE3_DATE201600_CON42620_INV1701805_CREATION201702222051250';

        List<Meter__c> userMeters = [
                SELECT Id
                FROM Meter__c
                WHERE Id IN (
                        SELECT Meter__c
                        FROM Site_Role__c
                        WHERE Contact__c = :conId
                        AND Role__c INCLUDES ('Customer Portal')
                        AND Start_Date__c <= :Date.today()
                        AND (End_Date__c >= :Date.today()
                        OR End_Date__c = NULL)
                )
        ];
        List<MeterRegistration__c> meterRegistrations = [
                SELECT Contract__r.Name,Contract__c,Meter__r.Name
                FROM MeterRegistration__c
                WHERE Meter__c IN :userMeters
                AND Valid_from__c <= :Date.today()
                AND (Valid_to__c >= :Date.today()
                OR Valid_to__c = NULL)
        ];
        Blob file = Blob.valueOf('abc');
        ContentVersion v1 = new ContentVersion();
        v1.VersionData = file;
        v1.Title = documentTitle;
        v1.PathOnClient = '/somepath.txt';
        v1.Community_available__c = true;
        insert v1;

        ContentVersion v2 = new ContentVersion();
        v2.VersionData = file;
        v2.Title = documentTitleBs;
        v2.PathOnClient = '/somepath.txt';
        v2.Community_available__c = true;
        insert v2;

        ContentVersion conVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = :documentTitle LIMIT 1];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = conVer.ContentDocumentId;
        testLink.LinkedEntityId = meterRegistrations[0].Contract__c;
        testLink.ShareType = 'I';
        insert testLink;

        ContentVersion conVerBs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = :documentTitleBs LIMIT 1];
        ContentDocumentLink testLinkBs = new ContentDocumentLink();
        testLinkBs.ContentDocumentId = conVerBs.ContentDocumentId;
        testLinkBs.LinkedEntityId = meterRegistrations[0].Contract__c;
        testLinkBs.ShareType = 'I';
        insert testLinkBs;
    }
    static testMethod void testRetrieveDocuments() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.runAs(testUser) {
            System.Test.startTest();
            msDocuments.fetchDocuments();
            System.Test.stopTest();
        }
    }
    static testMethod void testStaticDocuments() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        System.debug(testUser);
        System.Test.startTest();
        System.runAs(testUser) {
            msDocuments.getStaticDocuments();
            System.Test.stopTest();
        }
    }

}