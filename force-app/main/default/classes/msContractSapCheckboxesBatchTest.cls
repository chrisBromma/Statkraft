@IsTest
private class msContractSapCheckboxesBatchTest {

    private static final String ACCOUNT_ATTACHMENT_TYPE = ContentVersion.Attachement_Type__c.getDescribe().getPicklistValues()[0].getValue();
    private static final String CONTRACT_ATTACHMENT_TYPE = ContentVersion.Attachement_Type__c.getDescribe().getPicklistValues()[1].getValue();

    @TestSetup
    static void setup() {
        Attachmenttypes__c accountAttachmentType = new Attachmenttypes__c(
                Name = ACCOUNT_ATTACHMENT_TYPE,
                msPicklist_Value_API_Name__c = ACCOUNT_ATTACHMENT_TYPE,
                Tax_or_VAT__c = true
        );
        Attachmenttypes__c contractAttachmentType = new Attachmenttypes__c(
                Name = CONTRACT_ATTACHMENT_TYPE,
                msPicklist_Value_API_Name__c = CONTRACT_ATTACHMENT_TYPE,
                Double_Signed_Contract__c = true
        );
        insert new List<Attachmenttypes__c>{accountAttachmentType, contractAttachmentType};

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contract__c testContract = new Contract__c();
        testContract.RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE;
        testContract.Status__c = 'Active';
        testContract.Contract_Holder__c = acc.Id;
        testContract.Contract_Type__c = null;
        testContract.Start_Date__c = Date.today();
        testContract.End_Date__c = Date.today();
        testContract.Country__c = 'Germany';
        testContract.Approved__c = true;
        testContract.Name = 'Test Unique';
        insert testContract;

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        Blob testBlob = Blob.valueOf('FileName');
        ContentVersion accContentVer = new ContentVersion();
        accContentVer.VersionData = testBlob;
        accContentVer.Title = 'TestTitle Account';
        accContentVer.PathOnClient ='/somepathAccount.txt';
        accContentVer.Attachement_Type__c = accountAttachmentType.msPicklist_Value_API_Name__c;
        contentVersionsToInsert.add(accContentVer);
        ContentVersion contractContentVersion = new ContentVersion();
        contractContentVersion.VersionData = testBlob;
        contractContentVersion.Title = 'TestTitle Contract';
        contractContentVersion.PathOnClient ='/somepathContract.txt';
        contractContentVersion.Attachement_Type__c = contractAttachmentType.msPicklist_Value_API_Name__c;
        contentVersionsToInsert.add(contractContentVersion);
        insert contentVersionsToInsert;

        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion];
        ContentDocumentLink accountTestLink = new ContentDocumentLink();
        accountTestLink.ContentDocumentId = contentVersions[0].ContentDocumentId;
        accountTestLink.LinkedEntityId = acc.Id;
        accountTestLink.ShareType = 'I';
        contentDocumentLinksToInsert.add(accountTestLink);
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = contentVersions[1].ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';
        contentDocumentLinksToInsert.add(testLink);
        insert contentDocumentLinksToInsert;
    }

    @IsTest
    static void shouldCalculateCheckboxes() {
        Map<String, Attachmenttypes__c> attachmentTypes = Attachmenttypes__c.getAll();
        attachmentTypes.get(ACCOUNT_ATTACHMENT_TYPE).Tax_or_VAT__c = false;
        attachmentTypes.get(ACCOUNT_ATTACHMENT_TYPE).Company_Registration__c = true;
        attachmentTypes.get(CONTRACT_ATTACHMENT_TYPE).Double_Signed_Contract__c = false;
        update attachmentTypes.values();

        System.assert(![SELECT Id FROM Account WHERE Tax_or_VAT__c = TRUE AND Company_Registration__c = FALSE].isEmpty());
        System.assert(![SELECT Id FROM Contract__c WHERE Double_Signed_Contract__c = TRUE AND Tax_or_VAT__c = TRUE AND Company_Registration__c = FALSE].isEmpty());

        Test.startTest();

        Database.executeBatch(new msContractSapCheckboxesBatch());

        Test.stopTest();

        System.assert(![SELECT Id FROM Account WHERE Tax_or_VAT__c = FALSE AND Company_Registration__c = TRUE].isEmpty());
        System.assert(![SELECT Id FROM Contract__c WHERE Double_Signed_Contract__c = FALSE AND Tax_or_VAT__c = FALSE AND Company_Registration__c = TRUE].isEmpty());
    }
}