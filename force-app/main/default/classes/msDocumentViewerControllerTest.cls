@IsTest
public with sharing class msDocumentViewerControllerTest {

    private static final String WRONG_ATTACHMENT_TYPE = ContentVersion.Attachement_Type__c.getDescribe().getPicklistValues()[0].getValue();
    private static final String CORRECT_ATTACHMENT_TYPE = ContentVersion.Attachement_Type__c.getDescribe().getPicklistValues()[1].getValue();

    @TestSetup
    static void setup() {
        List<Attachmenttypes__c> attachmentTypesToInsert = new List<Attachmenttypes__c>();
        Attachmenttypes__c correctAttachmentTypeSetting = new Attachmenttypes__c();
        correctAttachmentTypeSetting.Name = CORRECT_ATTACHMENT_TYPE;
        correctAttachmentTypeSetting.msPicklist_Value_API_Name__c = CORRECT_ATTACHMENT_TYPE;
        correctAttachmentTypeSetting.msIsShowInPortal__c = false;
        correctAttachmentTypeSetting.msIsSendNotifications__c = false;
        attachmentTypesToInsert.add(correctAttachmentTypeSetting);

        Attachmenttypes__c incorrectAttachmentTypeSetting = new Attachmenttypes__c();
        incorrectAttachmentTypeSetting.Name = WRONG_ATTACHMENT_TYPE;
        incorrectAttachmentTypeSetting.msPicklist_Value_API_Name__c = WRONG_ATTACHMENT_TYPE;
        incorrectAttachmentTypeSetting.msIsShowInPortal__c = true;
        incorrectAttachmentTypeSetting.msIsSendNotifications__c = false;
        attachmentTypesToInsert.add(incorrectAttachmentTypeSetting);
        insert attachmentTypesToInsert;

        Account acc = new Account();
        acc.RecordTypeId = msTestDataFactory.DE_ACC_RECORD_TYPE;
        acc.Name = 'TestName';
        acc.Country__c = 'Germany';
        acc.Customer_Segment_industry__c = 'Tech companies';
        acc.Customer_Type__c = 'C - Single country, single product owner';
        acc.BillingCountry = 'Germany';
        insert acc;

        Contract__c testContract = new Contract__c();
        testContract.RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE;
        testContract.Status__c = 'Draft';
        testContract.Name='DE_Document_Viewer';
        testContract.Contract_Holder__c = acc.Id;
        testContract.Contract_Type__c = null;
        testContract.Start_Date__c = Date.today();
        testContract.End_Date__c = Date.today();
        testContract.Country__c = 'Germany';
        insert testContract;

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        Blob file = Blob.valueOf('FileName');
        ContentVersion v = new ContentVersion();
        v.VersionData = file;
        v.Title = 'TestTitle';
        v.PathOnClient ='/somepath.txt';
        v.Attachement_Type__c = WRONG_ATTACHMENT_TYPE;
        contentVersionsToInsert.add(v);

        for(Integer i=0; i < 10; i++) {
            Blob testBlob = Blob.valueOf('FileName' + i);
            ContentVersion contentVer = new ContentVersion();
            contentVer.VersionData = testBlob;
            contentVer.Title = 'TestTitle' + i;
            contentVer.PathOnClient ='/somepath' + i + '.txt';
            contentVer.Attachement_Type__c = CORRECT_ATTACHMENT_TYPE;
            contentVersionsToInsert.add(contentVer);
        }
        insert contentVersionsToInsert;

        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
        for(ContentVersion contentVer :  [SELECT Id, ContentDocumentId FROM ContentVersion]) {
            ContentDocumentLink accountTestLink = new ContentDocumentLink();
            accountTestLink.ContentDocumentId = contentVer.ContentDocumentId;
            accountTestLink.LinkedEntityId = acc.Id;
            accountTestLink.ShareType = 'I';
            contentDocumentLinksToInsert.add(accountTestLink);
            ContentDocumentLink contractTestLink = new ContentDocumentLink();
            contractTestLink.ContentDocumentId = contentVer.ContentDocumentId;
            contractTestLink.LinkedEntityId = testContract.Id;
            contractTestLink.ShareType = 'I';
            contentDocumentLinksToInsert.add(contractTestLink);
        }
        insert contentDocumentLinksToInsert;
    }

    @IsTest
    static void shouldReturnAllFilesForAccount() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = '';
        filterWrapper.fileRange = 'all';
        filterWrapper.showActiveDocuments = false;
        filterWrapper.showChildAccounts = false;
        filterWrapper.showCommercialDocuments = false;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(acc.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assertEquals(10, resultWrapper.accountDocumentWrappers.size());
        System.assertEquals(10, resultWrapper.contractDocumentWrappers.size());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.accountDocumentWrappers[0].contentVersionAttachmentType);
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldReturnAccountFilesForAccount() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = '';
        filterWrapper.fileRange = 'accounts';
        filterWrapper.showActiveDocuments = false;
        filterWrapper.showChildAccounts = false;
        filterWrapper.showCommercialDocuments = false;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(acc.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assertEquals(10, resultWrapper.accountDocumentWrappers.size());
        System.assert(resultWrapper.contractDocumentWrappers.isEmpty());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.accountDocumentWrappers[0].contentVersionAttachmentType);
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldReturnContractFilesForAccount() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = '';
        filterWrapper.fileRange = 'contracts';
        filterWrapper.showActiveDocuments = false;
        filterWrapper.showChildAccounts = false;
        filterWrapper.showCommercialDocuments = false;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(acc.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assertEquals(10, resultWrapper.contractDocumentWrappers.size());
        System.assert(resultWrapper.accountDocumentWrappers.isEmpty());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.contractDocumentWrappers[0].contentVersionAttachmentType);
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldReturnAllFilesForAccountByAttachmentType() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = CORRECT_ATTACHMENT_TYPE;
        filterWrapper.fileRange = 'all';
        filterWrapper.showActiveDocuments = false;
        filterWrapper.showChildAccounts = false;
        filterWrapper.showCommercialDocuments = false;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(acc.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assertEquals(10, resultWrapper.accountDocumentWrappers.size());
        System.assertEquals(10, resultWrapper.contractDocumentWrappers.size());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.accountDocumentWrappers[0].contentVersionAttachmentType);
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldReturnAllActiveFilesForAccount() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = '';
        filterWrapper.fileRange = 'all';
        filterWrapper.showActiveDocuments = true;
        filterWrapper.showChildAccounts = false;
        filterWrapper.showCommercialDocuments = false;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(acc.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assert(!resultWrapper.accountDocumentWrappers.isEmpty());
        System.assert(!resultWrapper.contractDocumentWrappers.isEmpty());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldReturnAllCommercialFilesForAccount() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = '';
        filterWrapper.fileRange = 'all';
        filterWrapper.showActiveDocuments = false;
        filterWrapper.showChildAccounts = false;
        filterWrapper.showCommercialDocuments = true;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(acc.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assert(resultWrapper.accountDocumentWrappers.isEmpty());
        System.assert(resultWrapper.contractDocumentWrappers.isEmpty());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldReturnAllFilesWithChildrenForAccount() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Account childAccount = new Account();
        childAccount.RecordTypeId = msTestDataFactory.DE_ACC_RECORD_TYPE;
        childAccount.Name = 'ChildTestName';
        childAccount.Country__c = 'Germany';
        childAccount.Negotiating_Party__c = acc.Id;
        childAccount.Customer_Segment_industry__c = 'Tech companies';
        childAccount.Customer_Type__c = 'C - Single country, single product owner';
        childAccount.BillingCountry = 'Germany';
        insert childAccount;

        Blob file = Blob.valueOf('ChildFileName');
        ContentVersion v = new ContentVersion();
        v.VersionData = file;
        v.Title = 'ChildTestFile';
        v.PathOnClient ='/childpath.txt';
        v.Attachement_Type__c = CORRECT_ATTACHMENT_TYPE;
        //Hotfix until msContentVersionHandler.calculateSapCheckboxes() is refactored:
        TriggerHandlerExtension.disableObject(ContentDocumentLink.SObjectType);
        insert v;
        TriggerHandlerExtension.enableObject(ContentDocumentLink.SObjectType);

        
        ContentVersion contentVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :v.Id];
        ContentDocumentLink childAccountTestLink = new ContentDocumentLink();
        childAccountTestLink.ContentDocumentId = contentVer.ContentDocumentId;
        childAccountTestLink.LinkedEntityId = childAccount.Id;
        childAccountTestLink.ShareType = 'I';
        insert childAccountTestLink;


        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = '';
        filterWrapper.fileRange = 'all';
        filterWrapper.showActiveDocuments = false;
        filterWrapper.showChildAccounts = true;
        filterWrapper.showCommercialDocuments = false;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(acc.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assertEquals(11, resultWrapper.accountDocumentWrappers.size());
        System.assertEquals(10, resultWrapper.contractDocumentWrappers.size());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.accountDocumentWrappers[0].contentVersionAttachmentType);
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldReturnAllFilesForContract() {
        //given
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];
        msDocumentViewerController.FilterWrapper filterWrapper = new msDocumentViewerController.FilterWrapper();
        filterWrapper.attachmentType = '';
        filterWrapper.fileRange = 'all';
        filterWrapper.showActiveDocuments = false;
        filterWrapper.showChildAccounts = false;
        filterWrapper.showCommercialDocuments = false;

        //when
        Test.startTest();
        msDocumentViewerController.DocumentViewerWrapper resultWrapper = msDocumentViewerController.getContentDocuments(testContract.Id, filterWrapper);
        Test.stopTest();

        //then
        System.assert(resultWrapper.accountDocumentWrappers.isEmpty());
        System.assertEquals(10, resultWrapper.contractDocumentWrappers.size());
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.contractDocumentWrappers[0].contentVersionAttachmentType);
        System.assertEquals(CORRECT_ATTACHMENT_TYPE, resultWrapper.availableAttachmentTypes[0]);
        System.assert(!resultWrapper.availableAttachmentTypes.contains(WRONG_ATTACHMENT_TYPE));
    }

    @IsTest
    static void shouldDeleteContentDocumentLink() {
        //given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink contentDocumentLink = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id LIMIT 1];

        //when
        Test.startTest();
        msDocumentViewerController.deleteContentDocumentLinkId(contentDocumentLink.Id);
        Test.stopTest();

        //then
        System.assert([SELECT Id FROM ContentDocumentLink WHERE Id = :contentDocumentLink.Id].isEmpty());
    }
}