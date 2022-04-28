@IsTest
private class msContractSapCheckboxesQueueableTest {

    private static Integer numberOfContractsToProcess = 5;
    private static List<PicklistEntry> validAttachmentTypes = ContentVersion.Attachement_Type__c.getDescribe().getPicklistValues();
    private static String testAttachmentType1 = validAttachmentTypes[0].getValue();
    private static String testAttachmentType2 = validAttachmentTypes[1].getValue();

    @TestSetup
    static void setup() {
        List<Attachmenttypes__c> attachmenttypes = new List<Attachmenttypes__c>();
        attachmenttypes.add(new Attachmenttypes__c(
                Name = testAttachmentType1,
                msPicklist_Value_API_Name__c = testAttachmentType1,
                Tax_or_VAT__c = true)
        );
        attachmenttypes.add(new Attachmenttypes__c(
                Name = testAttachmentType2,
                msPicklist_Value_API_Name__c = testAttachmentType2,
                Double_Signed_Contract__c = true,
                Company_Registration__c = true)
        );
        insert attachmenttypes;

        Account acc = new Account(Name = 'Test Name', Sandbox_Migration_Id__c = 'Test');
        insert acc;

        List<Contract__c> contractsToInsert = new List<Contract__c>();
        for(Integer i=0; i < numberOfContractsToProcess; i++) {
            Contract__c testContract = new Contract__c();
            testContract.RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE;
            testContract.Status__c = 'Active';
            testContract.Contract_Holder__c = acc.Id;
            testContract.Contract_Type__c = null;
            testContract.Start_Date__c = Date.today();
            testContract.End_Date__c = Date.today();
            testContract.Country__c = 'Germany';
            testContract.Approved__c = true;
            testContract.Name = 'test Contract';
            contractsToInsert.add(testContract);
        }
        insert contractsToInsert;

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        for(Integer i=0; i < 2; i++) {
            Blob testBlob = Blob.valueOf('FileName' + i);
            ContentVersion contentVer = new ContentVersion();
            contentVer.VersionData = testBlob;
            contentVer.Title = 'TestTitle' + i;
            contentVer.PathOnClient ='/somepath' + i + '.txt';
            contentVer.Attachement_Type__c = validAttachmentTypes[i].getValue();
            contentVersionsToInsert.add(contentVer);
        }
        insert contentVersionsToInsert;
    }

    @IsTest
    static void shouldCalculateOnContractCDLInsert() {
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Attachement_Type__c = :testAttachmentType2];
        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();

        Test.startTest();

        List<Contract__c> contracts = [SELECT Id, Approved__c, Contract_Holder__c FROM Contract__c];
        for(Contract__c testContract : contracts) {
            ContentDocumentLink testLink = new ContentDocumentLink();
            testLink.ContentDocumentId = contentVersions[0].ContentDocumentId;
            testLink.LinkedEntityId = testContract.Id;
            testLink.ShareType = 'I';
            contentDocumentLinksToInsert.add(testLink);
        }
        insert contentDocumentLinksToInsert;

        Test.stopTest();

        System.assertEquals(numberOfContractsToProcess, [SELECT COUNT() FROM Contract__c WHERE Double_Signed_Contract__c = TRUE]);
    }

    @IsTest
    static void shouldCalculateOnAccountCDLInsert() {
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Attachement_Type__c = :testAttachmentType1];
        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();

        Test.startTest();

        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test'];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = contentVersions[0].ContentDocumentId;
        testLink.LinkedEntityId = acc.Id;
        testLink.ShareType = 'I';
        insert testLink;

        Test.stopTest();

        System.assert(![SELECT Id FROM Account WHERE Tax_or_VAT__c = TRUE AND Company_Registration__c = FALSE].isEmpty());
        System.assertEquals(numberOfContractsToProcess, [SELECT COUNT() FROM Contract__c WHERE Tax_or_VAT__c = TRUE AND Company_Registration__c = FALSE]);
    }

    @IsTest
    static void shouldCalculateOnContractCDLDelete() {
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Attachement_Type__c = :testAttachmentType2];
        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
        List<Contract__c> contracts = [SELECT Id FROM Contract__c];
        for(Contract__c testContract : contracts) {
            ContentDocumentLink testLink = new ContentDocumentLink();
            testLink.ContentDocumentId = contentVersions[0].ContentDocumentId;
            testLink.LinkedEntityId = testContract.Id;
            testLink.ShareType = 'I';
            contentDocumentLinksToInsert.add(testLink);
        }
        insert contentDocumentLinksToInsert;

        Test.startTest();

        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :contracts[0].Id];
        delete cdl;

        Test.stopTest();

        System.assertEquals(4, [SELECT COUNT() FROM Contract__c WHERE Double_Signed_Contract__c = TRUE]);
        System.assertEquals(1, [SELECT COUNT() FROM Contract__c WHERE Double_Signed_Contract__c = FALSE]);
    }

    @IsTest
    static void shouldCalculateOnAccountCDLDelete() {
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Attachement_Type__c = :testAttachmentType2];
        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test'];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = contentVersions[0].ContentDocumentId;
        testLink.LinkedEntityId = acc.Id;
        testLink.ShareType = 'I';
        insert testLink;

        Test.startTest();

        delete testLink;

        Test.stopTest();

        System.assert(![SELECT Id FROM Account WHERE Tax_or_VAT__c = FALSE AND Company_Registration__c = FALSE].isEmpty());
    }
}