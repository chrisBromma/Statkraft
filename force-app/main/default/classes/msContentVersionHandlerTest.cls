/****************************************************************************************************
* Class msContentVersionHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   20.03.2019
*   Description	:	Testclass for the class msContentVersionHandler.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		20.03.2019       	Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msContentVersionHandlerTest {

    private static final Date THIS_DAY = Date.today();
    @TestSetup
    public static void testSetup() {
        msTestDataFactory.createTestPortalContext();
        Attachmenttypes__c newAtt = new Attachmenttypes__c();
        newAtt.Name = 'test';
        newAtt.msPicklist_Value_API_Name__c = 'Year-end invoice';
        newAtt.Related_Object__c = 'Contract__c';
        newAtt.msIsShowInPortal__c = true;
        newAtt.msIsSendNotifications__c = true;
        insert newAtt;
        Attachmenttypes__c newAtt2 = new Attachmenttypes__c();
        newAtt2.Name = 'test1';
        newAtt2.msPicklist_Value_API_Name__c = 'Year-end invoice';
        newAtt2.Related_Object__c = 'Meter__c';
        newAtt2.msIsShowInPortal__c = true;
        newAtt2.msIsSendNotifications__c = true;
        insert newAtt2;
    }
    @IsTest
    public static void testInsertWithAttachmentTypeSelected() {
        Blob file = Blob.valueOf('abc');
        ContentVersion v = new ContentVersion();
        v.VersionData = file;
        v.Title = 'testing upload';
        v.PathOnClient = '/somepath.txt';
        v.Attachement_Type__c = 'Year-end invoice';
        insert v;
        Test.startTest();
        v = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: v.Id LIMIT 1];
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = v.ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';
        insert testLink;
        Test.stopTest();
    }
    @IsTest
    static void testSettingValidityFields() {

        System.Test.startTest();

        Contract__c testContract = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'GermanTestContract1'];
        ContentVersion conVerOld = new ContentVersion();
        conVerOld.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVerOld.PathOnClient = 'Test'; // The files name, extension is very important here which will help the file in preview.
        conVerOld.Title = 'Test' ; // Display name of the files
        conVerOld.VersionData = EncodingUtil.base64Decode('010'); // converting your binary string to Blog
        conVerOld.Attachement_Type__c = 'Tax Number';
        insert(conVerOld);

        conVerOld = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :conVerOld.Id];

        ContentDocumentLink cDeOld = new ContentDocumentLink();
        cDeOld.ContentDocumentId = conVerOld.ContentDocumentId;
        cDeOld.LinkedEntityId = testContract.Id;
        cDeOld.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDeOld.Visibility = 'InternalUsers';
        insert(cDeOld);

        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVer.PathOnClient = 'Test2'; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = 'Test2' ; // Display name of the files
        conVer.VersionData = EncodingUtil.base64Decode('010'); // converting your binary string to Blog
        conVer.Attachement_Type__c = 'Tax Number';
        insert(conVer);

        conVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :conVer.Id];
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conVer.ContentDocumentId;
        cDe.LinkedEntityId = testContract.Id;
        cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDe.Visibility = 'InternalUsers';
        insert(cDe);



        ContentVersion conVerVersion2 = new ContentVersion();
        conVerVersion2.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVerVersion2.PathOnClient = 'Test3'; // The files name, extension is very important here which will help the file in preview.
        conVerVersion2.Title = 'Test3' ; // Display name of the files
        conVerVersion2.ContentDocumentId = conVer.ContentDocumentId;
        conVerVersion2.Attachement_Type__c = 'Tax Number';
        conVerVersion2.VersionData = EncodingUtil.base64Decode('010'); // converting your binary string to Blog
        insert conVerVersion2;

        System.Test.stopTest();
        ContentVersion oldConVer = [SELECT Id, Validity_end_date__c, Status_Document__c FROM ContentVersion WHERE Id=:conVerOld.Id];
        ContentVersion newConVer = [SELECT Id, Validity_end_date__c, Status_Document__c FROM ContentVersion WHERE Id=:conVer.Id];
        System.assertEquals(false, oldConVer.Status_Document__c);
        System.assertEquals(Date.today(), oldConVer.Validity_end_date__c);
        System.assertEquals(true, newConVer.Status_Document__c);
    }

    @IsTest
    static void shouldUpdateContentVersionOnAttachmentTypeChange() {
        Test.startTest();

        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];
        List<PicklistEntry> attachmentTypes = ContentVersion.Attachement_Type__c.getDescribe().getPicklistValues();
        List<Attachmenttypes__c> attachmentsToInsert = new List<Attachmenttypes__c>();
        Attachmenttypes__c taxOrVatAttachmentType = new Attachmenttypes__c();
        taxOrVatAttachmentType.Name = attachmentTypes[0].getValue();
        taxOrVatAttachmentType.msPicklist_Value_API_Name__c = attachmentTypes[0].getValue();
        taxOrVatAttachmentType.Related_Object__c = 'Contract__c';
        taxOrVatAttachmentType.Tax_or_VAT__c = true;
        attachmentsToInsert.add(taxOrVatAttachmentType);
        Attachmenttypes__c companyRegisteredAttachmentType = new Attachmenttypes__c();
        companyRegisteredAttachmentType.Name = attachmentTypes[1].getValue();
        companyRegisteredAttachmentType.msPicklist_Value_API_Name__c = attachmentTypes[1].getValue();
        companyRegisteredAttachmentType.Related_Object__c = 'Contract__c';
        companyRegisteredAttachmentType.Company_Registration__c = true;
        attachmentsToInsert.add(companyRegisteredAttachmentType);
        insert attachmentsToInsert;

        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVer.PathOnClient = 'Test2'; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = 'Test2' ; // Display name of the files
        conVer.VersionData = EncodingUtil.base64Decode('010'); // converting your binary string to Blog
        conVer.Attachement_Type__c = attachmentTypes[0].getValue();
        insert conVer;
        conVer = [SELECT Id, ContentDocumentId, Attachement_Type__c FROM ContentVersion WHERE Id = :conVer.Id];

        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = conVer.ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';
        insert testLink;



        conVer.Attachement_Type__c = attachmentTypes[1].getValue();
        update conVer;
        System.assert(![SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :msContractSapCheckboxesQueueable.class.getName()].isEmpty());

        Test.stopTest();
    }

    @IsTest
    private static void passHistoricalDataTest() {
        Integer bulkSize = 1;
        disableTriggers();
        Id historicalDataId = createHistoricalDataTestDataSet(bulkSize);
        enableTriggers();

        ContentVersion versionUpdate = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :historicalDataId];
        versionUpdate.Attachement_Type__c = 'Historical Data';

        Test.startTest();
        update versionUpdate;
        Test.stopTest();

        List<Contract__c> contracts = [SELECT Id FROM Contract__c WHERE Sandbox_Migration_Id__c LIKE 'hist_test%' LIMIT :bulkSize];
        List<ContentDocumentLink> establishedLinks = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :versionUpdate.ContentDocumentId
        ];

        Set<Id> connectedSObjectIds = new Set<Id>();
        for (ContentDocumentLink establishedLink : establishedLinks) {
            connectedSObjectIds.add(establishedLink.LinkedEntityId);
        }
        for (Integer i = 0; i < bulkSize; i++) {
            System.assert(connectedSObjectIds.contains(contracts[i].Id));
        }
    }

    @IsTest
    private static void passHistoricalDataBulkTest() {
        Integer bulkSize = 50;
        disableTriggers();
        Id historicalDataId = createHistoricalDataTestDataSet(bulkSize);
        enableTriggers();

        ContentVersion versionUpdate = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :historicalDataId];
        versionUpdate.Attachement_Type__c = 'Historical Data';

        Test.startTest();
        update versionUpdate;
        Test.stopTest();

        List<Contract__c> contracts = [SELECT Id FROM Contract__c WHERE Sandbox_Migration_Id__c LIKE 'hist_test%' LIMIT :bulkSize];
        List<ContentDocumentLink> establishedLinks = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :versionUpdate.ContentDocumentId
        ];

        Set<Id> connectedSObjectIds = new Set<Id>();
        for (ContentDocumentLink establishedLink : establishedLinks) {
            connectedSObjectIds.add(establishedLink.LinkedEntityId);
        }
        for (Integer i = 0; i < bulkSize; i++) {
            System.assert(connectedSObjectIds.contains(contracts[i].Id));
        }
    }

    private static Id createHistoricalDataTestDataSet(Integer amountOfPathsToTrace) {

        Account testAccount = new Account(
                Name = 'test historical data account',
                RecordTypeId = msTestDataFactory.DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                Sandbox_Migration_Id__c = 'test historical data account'
        );
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;
        Database.SaveResult sr = Database.insert(testAccount, dml);
        if (!sr.isSuccess()) {
            System.debug('Error during Account Insertion');
        }

        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            contracts.add(new Contract__c(
                    Name = 'test' + i,
                    RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Contract_Holder__c = testAccount.Id,
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract1',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Settlement_SubModel__c = null,
                    Sandbox_Migration_Id__c = 'hist_test' + i
            ));
        }
        insert contracts;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            opportunities.add(new Opportunity(
                    Name = 'test' + i,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Country__c = 'Germany',
                    StageName = 'New',
                    CloseDate = THIS_DAY,
                    AccountId = testAccount.Id
            ));
        }
        insert opportunities;

        List<Offer__c> offers = new List<Offer__c>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            offers.add(new Offer__c(
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Country__c = 'Germany',
                    Opportunity__c = opportunities[i].Id,
                    Resulting_Contract__c = contracts[i].Id
            ));
        }
        insert offers;

        ContentVersion historicalData = new ContentVersion(
                ContentLocation = 'S', // S specify this document is in SF, use E for external files
                PathOnClient = 'Test', // The files name, extension is very important here which will help the file in preview.
                Title = 'Historical_Data' , // Display name of the files
                VersionData = EncodingUtil.base64Decode('010'), // converting your binary string to Blog
                Attachement_Type__c = null
        );
        insert historicalData;
        historicalData = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :historicalData.Id];

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            links.add(new ContentDocumentLink(
                    LinkedEntityId = offers[i].Id,
                    ContentDocumentId = historicalData.ContentDocumentId
            ));
        }
        insert links;
        return historicalData.Id;
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Offer__c.SObjectType);
        TriggerHandlerExtension.disableObject(Opportunity.SObjectType);
        TriggerHandlerExtension.disableObject(ContentDocumentLink.SObjectType);
        TriggerHandlerExtension.disableObject(ContentVersion.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Offer__c.SObjectType);
        TriggerHandlerExtension.enableObject(Opportunity.SObjectType);
        TriggerHandlerExtension.enableObject(ContentDocumentLink.SObjectType);
        TriggerHandlerExtension.enableObject(ContentVersion.SObjectType);
    }
}