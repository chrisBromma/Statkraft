/****************************************************************************************************
* Class msContentDocumentLinkHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   20.03.2019
*   Description	:	Testclass for the class msContentDocumentLinkHandler.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		20.03.2019       	Init version.
*   * Christian Gottlieb (mindsquare GmbH)      29.04.2019          V2 for New Core Model
*****************************************************************************************************/
@IsTest
public without sharing class msContentDocumentLinkHandlerTest {

    public static final String DE_ACC_RECORD_TYPE =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId();

    private static final Date THIS_DAY = Date.today();

    @TestSetup
    public static void testSetup() {
        String validAttachmentTypeName = ContentVersion.Attachement_Type__c.getDescribe().getPicklistValues()[0].getValue();
        List<Attachmenttypes__c> attachmentTypesToInsert = new List<Attachmenttypes__c>();
        Attachmenttypes__c newAtt = new Attachmenttypes__c();
        newAtt.Name = 'Year-end invoice';
        newAtt.msPicklist_Value_API_Name__c = 'Year-end invoice';
        newAtt.Related_Object__c = 'Contract__c';
        newAtt.msIsShowInPortal__c = true;
        newAtt.msIsSendNotifications__c = true;
        attachmentTypesToInsert.add(newAtt);
        Attachmenttypes__c newAtt1 = new Attachmenttypes__c();
        newAtt1.Name = validAttachmentTypeName;
        newAtt1.msPicklist_Value_API_Name__c = validAttachmentTypeName;
        newAtt1.Related_Object__c = 'Contract__c';
        newAtt1.msIsShowInPortal__c = true;
        newAtt1.msIsSendNotifications__c = true;
        newAtt1.Tax_or_VAT__c = true;
        newAtt1.Double_Signed_Contract__c = true;
        attachmentTypesToInsert.add(newAtt1);
        insert attachmentTypesToInsert;

        Account acc = new Account(
                Name = 'Test Name',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert acc;

        Contract__c testContract = new Contract__c();
        testContract.RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE;
        testContract.Status__c = 'Draft';
        testContract.Contract_Holder__c = acc.Id;
        testContract.Start_Date__c = Date.today();
        testContract.End_Date__c = Date.today();
        testContract.Approved__c = true;
        testContract.Status__c = 'Active';
        testContract.Name = 'test Contract unique';
        insert testContract;

        ContentVersion v = new ContentVersion();
        v.VersionData = Blob.valueOf('Test File');
        v.Title = 'Test file';
        v.PathOnClient = '/somepath.txt';
        v.Attachement_Type__c = validAttachmentTypeName;
        insert v;
    }

    @IsTest
    public static void testInsertAndDeleteContract() {
        System.debug([SELECT Id FROM Account]);
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Blob file = Blob.valueOf('abc');
        ContentVersion v = new ContentVersion();
        v.VersionData = file;
        v.Title = 'testing upload';
        v.PathOnClient = '/somepath.txt';
        v.Attachement_Type__c = 'Year-end invoice';
        insert v;
        v = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Contract__c testContract = new Contract__c(
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addDays(10),
                Status__c = 'Draft',
                Contract_Holder__c = accId,
                Name = 'test Contract 2'
        );
        insert testContract;
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = v.ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';
        Test.startTest();
        insert testLink;
        testLink.ShareType = 'V';
        testLink.Visibility = 'AllUsers';
        update testLink;
        delete testLink;
        Test.stopTest();
    }

    @IsTest
    public static void testInsertEsales() {
        Test.startTest();
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Contract__c testContract = new Contract__c(
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addDays(10),
                Status__c = 'Draft',
                Contract_Holder__c = accId,
                Name = 'test Contract 2'
        );
        testContract.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId();
        insert testContract;
        Contact testContact = new Contact(LastName = 'testcontact');
        testContact.Email = 'unit@test.mail';
        insert testContact;
        Contract_Role__c testContractRole = new Contract_Role__c();
        testContractRole.Contact__c = testContact.Id;
        testContractRole.Contract__c = testContract.Id;
        testContractRole.Role__c = 'Notice Contact - invoices';
        insert testContractRole;
        Blob file = Blob.valueOf('abc');
        ContentVersion v = new ContentVersion();
        v.VersionData = file;
        v.Title = 'EM_TYPE12_MPM1_CREATION12345678123456';
        v.PathOnClient = '/somepath.txt';
        v.Attachement_Type__c = 'Year-end invoice';
        insert v;
        v = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :v.Id LIMIT 1];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = v.ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';

        insert testLink;
        Test.stopTest();
    }

    @IsTest
    static void testSettingValidityFields() {
        msTestDataFactory.createTestPortalContext();
        System.Test.startTest();
        Contract__c testContract = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'GermanTestContract1'];
        ContentVersion conVerOld = new ContentVersion();
        conVerOld.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVerOld.PathOnClient = 'Test'; // The files name, extension is very important here which will help the file in preview.
        conVerOld.Title = 'Test' ; // Display name of the files
        conVerOld.VersionData = EncodingUtil.base64Decode('010'); // converting your binary string to Blog
        conVerOld.Attachement_Type__c = 'EEG Billing document';
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
        conVer.Attachement_Type__c = 'EEG Billing document';
        insert(conVer);

        conVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :conVer.Id];
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conVer.ContentDocumentId;
        cDe.LinkedEntityId = testContract.Id;
        cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDe.Visibility = 'InternalUsers';
        insert(cDe);
        System.Test.stopTest();
        ContentVersion oldConVer = [SELECT Id, Validity_end_date__c, Status_Document__c FROM ContentVersion WHERE Id = :conVerOld.Id];
        ContentVersion newConVer = [SELECT Id, Validity_end_date__c, Status_Document__c FROM ContentVersion WHERE Id = :conVer.Id];
        System.assertEquals(false, oldConVer.Status_Document__c);
        System.assertEquals(Date.today(), oldConVer.Validity_end_date__c);
        System.assertEquals(true, newConVer.Status_Document__c);
    }

    @IsTest
    static void testSettingValidityFields_negativeForContractAttachmentTypes() {
        msTestDataFactory.createTestPortalContext();
        Attachmenttypes__c newContractType = new Attachmenttypes__c(
                Name = 'Invoice',
                msPicklist_Value_API_Name__c = 'Invoice',
                Related_Object__c = 'Contract__c',
                msIsShowInPortal__c = true,
                msIsSendNotifications__c = true
        );
        insert newContractType;

        Test.startTest();
        Contract__c testContract = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'GermanTestContract1'];
        ContentVersion conVerOld = new ContentVersion();
        conVerOld.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVerOld.PathOnClient = 'Test'; // The files name, extension is very important here which will help the file in preview.
        conVerOld.Title = 'Test' ; // Display name of the files
        conVerOld.VersionData = EncodingUtil.base64Decode('010'); // converting your binary string to Blog
        conVerOld.Attachement_Type__c = 'Invoice';
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
        conVer.Attachement_Type__c = 'Invoice';
        insert(conVer);

        conVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :conVer.Id];
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conVer.ContentDocumentId;
        cDe.LinkedEntityId = testContract.Id;
        cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDe.Visibility = 'InternalUsers';
        insert(cDe);

        System.Test.stopTest();
        ContentVersion oldConVer = [SELECT Id, Validity_end_date__c, Status_Document__c FROM ContentVersion WHERE Id = :conVerOld.Id];
        ContentVersion newConVer = [SELECT Id, Validity_end_date__c, Status_Document__c FROM ContentVersion WHERE Id = :conVer.Id];
        System.assertEquals(false, oldConVer.Status_Document__c);
        System.assertEquals(null, oldConVer.Validity_end_date__c);
        System.assertEquals(false, newConVer.Status_Document__c);
        System.assertEquals(null, oldConVer.Validity_end_date__c);
    }

    @IsTest
    static void shouldCalculateSapCheckboxesOnInsertForAccount() {
        ContentVersion conVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = conVersion.ContentDocumentId;
        testLink.LinkedEntityId = acc.Id;
        testLink.ShareType = 'I';
        insert testLink;
        System.assert(![SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :msContractSapCheckboxesQueueable.class.getName()].isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void shouldCalculateSapCheckboxesOnInsertForContract() {
        ContentVersion conVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];

        Test.startTest();

        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = conVersion.ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';
        insert testLink;
        System.assert(![SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :msContractSapCheckboxesQueueable.class.getName()].isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void shouldCalculateSapCheckboxesOnDeleteForAccount() {
        ContentVersion conVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = conVersion.ContentDocumentId;
        testLink.LinkedEntityId = acc.Id;
        testLink.ShareType = 'I';
        insert testLink;

        Test.startTest();

        delete testLink;
        System.assert(![SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :msContractSapCheckboxesQueueable.class.getName()].isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void shouldCalculateSapCheckboxesOnDeleteForContract() {
        ContentVersion conVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = conVersion.ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';
        insert testLink;

        Test.startTest();

        delete testLink;
        System.assert(![SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :msContractSapCheckboxesQueueable.class.getName()].isEmpty());

        Test.stopTest();
    }

    @IsTest
    private static void passHistoricalDataTest() {
        Integer bulkSize = 1;
        disableTriggers();
        List<Id> offerIds = createHistoricalDataTestDataSet(bulkSize);
        enableTriggers();

        ContentVersion historicalData = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Attachement_Type__c = 'Historical Data'
                LIMIT 1
        ];

        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for (Id offerId : offerIds) {
            linksToInsert.add(new ContentDocumentLink(
                    LinkedEntityId = offerId,
                    ContentDocumentId = historicalData.ContentDocumentId
            ));
        }

        Test.startTest();
        insert linksToInsert;
        Test.stopTest();

        List<Contract__c> contracts = [SELECT Id FROM Contract__c WHERE Sandbox_Migration_Id__c LIKE 'hist_test%' LIMIT :bulkSize];
        List<ContentDocumentLink> establishedLinks = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :historicalData.ContentDocumentId
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
        List<Id> offerIds = createHistoricalDataTestDataSet(bulkSize);
        enableTriggers();

        ContentVersion historicalData = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Attachement_Type__c = 'Historical Data'
                LIMIT 1
        ];

        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for (Id offerId : offerIds) {
            linksToInsert.add(new ContentDocumentLink(
                    LinkedEntityId = offerId,
                    ContentDocumentId = historicalData.ContentDocumentId
            ));
        }

        Test.startTest();
        insert linksToInsert;
        Test.stopTest();

        List<Contract__c> contracts = [SELECT Id FROM Contract__c WHERE Sandbox_Migration_Id__c LIKE 'hist_test%' LIMIT :bulkSize];
        List<ContentDocumentLink> establishedLinks = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :historicalData.ContentDocumentId
        ];

        Set<Id> connectedSObjectIds = new Set<Id>();
        for (ContentDocumentLink establishedLink : establishedLinks) {
            connectedSObjectIds.add(establishedLink.LinkedEntityId);
        }
        for (Integer i = 0; i < bulkSize; i++) {
            System.assert(connectedSObjectIds.contains(contracts[i].Id));
        }
    }

    private static List<Id> createHistoricalDataTestDataSet(Integer amountOfPathsToTrace) {

        Account testAccount = new Account(
                Name = 'Test Account DE',
                RecordTypeId = msTestDataFactory.DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                Sandbox_Migration_Id__c = 'Test Account DE'
        );
        insert testAccount;
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
                Title = 'Historical_Data', // Display name of the files
                VersionData = EncodingUtil.base64Decode('010'), // converting your binary string to Blog
                Attachement_Type__c = 'Historical Data'
        );
        insert historicalData;
        historicalData = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :historicalData.Id];


        List<Id> offerIds = new List<Id>();
        for (Offer__c newOffer : offers) {
            offerIds.add(newOffer.Id);
        }
        return offerIds;
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