/**
 * Created by Fabian on 09.04.2019.
 */

@IsTest
private with sharing class msBrytUtilityTest {
    private static final Id BrytContractId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
    private static final List<String> TEST_CONTRACT_ID = new List<String>{'12345', '67890'};
    private static final String CSV_CONTENT = 'Contract Name,Bryt Contract ID,Tradable Quarters\r\ntestName,' + TEST_CONTRACT_ID[0] + ',4\r\ntestName2,' + TEST_CONTRACT_ID[1] + ',12';
    private static final String CSV_REFCAP_NON_EXISTING_TO_TEST = 'Bryt Contract Id,Capacity Base,Capacity Peak,Month\r\n' +
            '141050,14.8,12,09/12/2049';

    @TestSetup
    private static void setup() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    private static void getUserDetailsTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser) {
            msBrytUtility.getUserDetails();
        }
    }

    @IsTest
    private static void getMetaDataTest() {
        msBrytUtility.getMetadata();
    }

    @IsTest
    private static void checkAccessTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser) {
            msBrytUtility.UserDetails details = msBrytUtility.getUserDetails();
            Id contractId = details.contracts[0].Id;
            Boolean access = null;
            Test.startTest();
            access = msBrytUtility.checkObjectAccess(contractId);
            Test.stopTest();
            System.assert(access, 'User should have access to their Contract');
        }
    }

    @IsTest
    private static void checkNoAccessTest() {

        User testUser = [SELECT Id FROM User WHERE Username = 'brytNoAdminTestUser@statkraft.mindsquare.user.dev'];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Id ContractRecId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
        Contract__c testContract = new Contract__c();
        testContract.RED_Contract_ID__c = 'TestContract1';
        testContract.Approved__c = true;
        testContract.Start_Date__c = Date.today().addMonths(-12).toStartOfMonth();
        testContract.End_Date__c = Date.today().addMonths(25).toStartOfMonth();
        testContract.Status__c = 'Draft';
        testContract.Contract_Holder__c = testAccount.Id;
        testContract.RecordTypeId = ContractRecId;
        testContract.POD_ID__c = 'test';
        testContract.Name = 'testAccessContract';
        insert testContract;

        System.runAs(testUser) {
            Boolean access = null;
            Test.startTest();
            try {
                access = msBrytUtility.checkObjectAccess(testContract.Id);
                System.assert(false, 'User should not have access to Statkraft User Record');
            } catch (Exception e) {
                System.assert(true, 'User should not have access to Statkraft User Record');
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void getHoursInMonthTest() {
        msBrytUtility.getHoursInMonth(Date.newInstance(2019, 1, 1));
    }

    @IsTest
    private static void getDataTypeFromStringTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'brytNoAdminTestUser@statkraft.mindsquare.user.dev'];
        String stringTest = 'abcdefg';
        String decimalTest = '1.2';
        String integerTest = '123';
        String dateTest = '23.10.1976';
        String boolTest = 'true';
        String nullTest = '';

        System.runAs(testUser) {
            Test.startTest();
            msBrytUtility.getDataTypeFromString(stringTest);
            msBrytUtility.getDataTypeFromString(decimalTest);
            msBrytUtility.getDataTypeFromString(integerTest);
            msBrytUtility.getDataTypeFromString(dateTest);
            msBrytUtility.getDataTypeFromString(boolTest);
            msBrytUtility.getDataTypeFromString(nullTest);
            Test.stopTest();
        }
    }
    @IsTest // Id ContentDocumentId
    private static void getCsvFromContentVersionGivenContentDocumentIdTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'brytNoAdminTestUser@statkraft.mindsquare.user.dev'];

        // Account: NANDO LIMITED
        Account acc1 = new Account();
        acc1.Name = 'NANDO LIMITED';
        acc1.RecordTypeId = msBrytUtility.BRYT_ACCOUNT_REC_TYPE_ID; // For Accounts with type "Bryt"
        acc1.Country__c = 'United Kingdom';
        acc1.BillingCountry = 'United Kingdom';
        acc1.Customer_Type__c = 'not yet identified';
        acc1.Customer_Segment_industry__c = 'Other segments';
        insert acc1;

        // A Bryt-Contract
        List<Contract__c> contractList = new List<Contract__c>();
        Contract__c c1 = new Contract__c();
        c1.Name = 'NANDO LIMITED';
        c1.Bryt_Contract_ID__c = '141053';
        c1.Start_Date__c = Date.today();
        c1.Contract_Holder__c = acc1.Id;
        c1.Approved__c = true;
        c1.Status__c = 'Active';
        c1.RecordTypeId = BrytContractId;
        contractList.add(c1);

        // CSV to test
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        Blob file = Blob.valueOf(CSV_CONTENT);
        ContentVersion version = new ContentVersion();
        version.Title = 'testCsvContentVersion';
        version.VersionData = file;
        version.PathOnClient = '/somepath.csv';
        version.Community_available__c = true;
        version.IsMajorVersion = false;
        version.Bryt_Content_Type__c = 'Contracts';
        contentVersionList.add(version);

        // CSV-template to test (One header + one row)
        Blob file4 = Blob.valueOf(CSV_REFCAP_NON_EXISTING_TO_TEST);
        ContentVersion version4 = new ContentVersion();
        version4.Title = 'testCsvContentVersion4';
        version4.VersionData = file4;
        version4.PathOnClient = '/somepath.csv';
        version4.Community_available__c = true;
        version4.IsMajorVersion = false;
        version4.Bryt_Content_Type__c = 'Contracts';
        contentVersionList.add(version4);
        insert contentVersionList;

        ContentDocument conDoc2 = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :version4.Id];

        // ContentDocumentLink
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = c1.Id;
        docLink.ContentDocumentId = conDoc2.Id;
        docLink.ShareType = 'I';
        docLink.Visibility = 'AllUsers';
        cdlList.add(docLink);

        System.runAs(testUser) {
            Test.startTest();
            msBrytUtility.getCsvFromContentVersionGivenContentDocumentId(conDoc2.Id);
            Test.stopTest();
        }
    }
    @IsTest
    public static void testGetInstance(){
        Map<String, Account> accountNameToAccountMap = msBrytUtility.getInstance();
        Account acc = [SELECT Name, RecordTypeId FROM Account WHERE Id = :(accountNameToAccountMap.get('TestAccount'.toUpperCase()).Id)];

        System.assertEquals(msBrytUtility.BRYT_ACCOUNT_REC_TYPE_ID, acc.RecordTypeId);
        System.assertEquals('TestAccount', acc.Name);
    }

}