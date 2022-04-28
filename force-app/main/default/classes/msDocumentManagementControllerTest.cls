/****************************************************************************************************
* Class msDocumentManagementControllerTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   09.07.2019
*   Description	:	Test class for the Controller of the msDocumentManagement Aura Component
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            09.07.2019       	Init version.
*****************************************************************************************************/
@IsTest private with sharing class msDocumentManagementControllerTest {

    @TestSetup private static void testSetup() {
        Id AccRecId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId();
        Id ConRecId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId();
        Account newAccount = new Account(
                Name = 'testAccount',
                Country__c = 'Germany',
                RecordTypeId= AccRecId,
                Customer_Segment_industry__c = 'Tech companies',
                Customer_Type__c = 'B - Single country, multiple product owners',
                BillingCountry = 'Germany'
        );
        insert newAccount;
        Contract__c newContract = new Contract__c(
                Contract_Holder__c = newAccount.Id,
                Country__c = 'Germany',
                Name='DE_Document_Management',
                RecordTypeId = ConRecId,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today());
        insert newContract;
    }
    @IsTest private static void getContractTest() {
        msDocumentManagementController.getContracts(null);
    }
    @IsTest private static void getAttachmentTypesTest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];

        Test.startTest();
        msDocumentManagementController.getAttachmentTypes(testAccount.Id);
        msDocumentManagementController.getAttachmentTypes(testContract.Id);
        Test.stopTest();
    }
    @IsTest private static void handleInitialUploadTest() {
        Blob file = Blob.valueOf('testdata');
        ContentVersion testVersion = new ContentVersion(
                Title = 'testVersionCREATION20190603DATE20190506',
                VersionData = file,
                PathOnClient = '/somepath.txt',
                Community_available__c = true
        );
        Database.insert(testVersion);
        testVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:testVersion.Id];
        msDocumentManagementController.handleInitialUpload(
                new List<Id>{testVersion.ContentDocumentId},
                'Other',
                Date.today(),
                Date.today(),
                new List<Id>(),
                'Submission'
        );
    }
    @IsTest private static void updateAndConnectTest() {
        Blob file = Blob.valueOf('testdata');
        ContentVersion testVersion = new ContentVersion(
                Title = 'testVersionCREATION20190603DATE20190506',
                VersionData = file,
                PathOnClient = '/somepath.txt',
                Community_available__c = true
        );
        Database.insert(testVersion);
        testVersion = [
                SELECT
                        Id,
                        ContentDocumentId,
                        Title,
                        Validity_start_date__c,
                        Validity_end_date__c,
                        Attachement_Type__c
                FROM ContentVersion WHERE Id =:testVersion.Id
        ];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];
        msDocumentManagementController.fileWrapper fileWrapperItem = new msDocumentManagementController.fileWrapper(testVersion);
        fileWrapperItem.relatedContractIds = new List<Id>{testContract.Id};
        List<msDocumentManagementController.fileWrapper> fileWrapperList = new List<msDocumentManagementController.fileWrapper>{fileWrapperItem};
        Test.startTest();
        msDocumentManagementController.updateAndConnect(testAccount.Id, fileWrapperList);
        Test.stopTest();
    }
}