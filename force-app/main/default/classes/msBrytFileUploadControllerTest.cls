@IsTest
public with sharing class msBrytFileUploadControllerTest {

    @TestSetup
    private static void setupData() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    private static void getUploadsTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser) {
            Test.startTest();
            msBrytFileUploadController.UserFileWrapper userUploadsWrapper = msBrytFileUploadController.getUploads();
            Test.stopTest();

            System.assertEquals(null, userUploadsWrapper.files, 'Files should be retrieved');

            if (userUploadsWrapper.files != null) {
                System.assertEquals(0, userUploadsWrapper.files.size(), 'Wrong Files list size');
            }

            System.assertEquals(testUser.Contact.AccountId, userUploadsWrapper.recordId, 'User related AccountId should be retrieved');
        }
    }

    @IsTest
    private static void updateInsertedFilesTest_Contracts() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        String ContentDocumentId2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = 'testCsvContentVersion2' LIMIT 1].ContentDocumentId; // conDoc2

        List<String> fileIds = new List<String>();
        fileIds.add(ContentDocumentId2);

        String fileType = 'Contracts';
        System.runAs(testUser){
            Test.startTest();
            msBrytFileUploadController.updateInsertedFiles(fileIds, fileType);
            Test.stopTest();
        }
    }

    @IsTest
    private static void updateInsertedFilesTest_ReferenceCapacities() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        String ContentDocumentId3 = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = 'testCsvContentVersion3' LIMIT 1].ContentDocumentId; // conDoc2

        List<String> fileIds = new List<String>();
        fileIds.add(ContentDocumentId3);

        String fileType = 'Reference Capacities';
        System.runAs(testUser){
            Test.startTest();
            msBrytFileUploadController.updateInsertedFiles(fileIds, fileType);
            Test.stopTest();
        }
    }

    @IsTest
    private static void getAffectedContractIdsTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        List<String> TEST_CONTRACT_ID = new List<String>{'12345', '67890'};
        String CSV_CONTENT = 'Contract Name,Bryt Contract ID,Tradable Quarters\r\ntestName,' + TEST_CONTRACT_ID[0] + ',4\r\ntestName2,' + TEST_CONTRACT_ID[1] + ',12';
        String CSV_CONTRACT_TO_TEST = 'Company,Allow Sell Back,Ask Premium,Bid Premium,Bryt Contract ID,Contract Name,Cost Per Trade,End Date,Expiry Days,Fixed Clip Percent,Start Date,Tradable Months,Tradable Quarters,Tradable Seasons,Tradable Years,Contract RecordType,Account RecordType\r\n' +
                'NANDO LIMITED,TRUE,0,0,141053,NANDO LIMITED,0,30/09/2021,3,,01/10/2018,2,1,4,0,Bryt Contract,Bryt Account';

        System.runAs(testUser) {
            Test.startTest();
            Blob file = Blob.valueOf(CSV_CONTENT);
            String result = msBrytFileUploadController.getAffectedContractIds(file);
            System.assertEquals(String.join(TEST_CONTRACT_ID, ','), result);
            Test.stopTest();
        }
    }

    @IsTest
    private static void upsertContractsTest_NoListGiven() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();
            List<String> fileIdsList = new List<String>();
            msBrytFileUploadController.upsertContracts(fileIdsList); // No fileIdsList given
            Test.stopTest();
        }
    }

    @IsTest
    private static void upsertContractsTest_ListGiven() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        String ContentDocumentId5 = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = 'testCsvContentVersion5' LIMIT 1].ContentDocumentId; // conDoc2

        List<String> fileIdsList = new List<String>();
        fileIdsList.add(ContentDocumentId5);

        System.runAs(testUser){
            Test.startTest();
            msBrytFileUploadController.upsertContracts(fileIdsList);
            Test.stopTest();
        }

    }

    @IsTest public static void getContractIdGivenBrytContractIdTest() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();

            AggregateResult[] brytContractId_check = [SELECT COUNT(Bryt_Contract_ID__c) countedBrytContractIds FROM Contract__c WHERE Bryt_Contract_ID__c = '141053'];
            Object countedBrytContractIds = brytContractId_check[0].get('countedBrytContractIds');

            if (countedBrytContractIds == 1) {
                String brytContractId = [SELECT Bryt_Contract_ID__c FROM Contract__c WHERE Bryt_Contract_ID__c = '141053' LIMIT 1].Bryt_Contract_ID__c;
                String contractIdsGivenBrytIds = msBrytFileUploadController.getContractIdGivenBrytContractId(brytContractId);
                System.assertNotEquals(null, contractIdsGivenBrytIds, 'BrytContractId was created');
            }
            Test.stopTest();
        }
    }

    @IsTest public static void getContractIdsGivenListOfBrytContractIdsTest() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();
            Set<String> brytContractIds = new Set<String>();
            brytContractIds.add('142042');
            brytContractIds.add('142043');
            msBrytFileUploadController.getContractIdsGivenListOfBrytContractIds(brytContractIds);
            Test.stopTest();
        }
    }

    @IsTest
    public static void mapCsvToApiNamesForContractTest() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();
            List<Map<String, Object>> csvDataListOfMaps = new List<Map<String, Object>>();
            Map<String, Object> csvColumnRowValues = new Map<String, Object>();

            // CSV test data
            csvColumnRowValues.put('Company', 'NANDO LIMITED');
            csvColumnRowValues.put('Allow Sell Back', 'TRUE');
            csvColumnRowValues.put('Ask Premium', '0');
            csvColumnRowValues.put('Bid Premium', '0');
            csvColumnRowValues.put('Bryt Contract ID', '141053');
            csvColumnRowValues.put('Contract Name', 'NANDO LIMITED');
            csvColumnRowValues.put('Cost Per Trade', '0');
            csvColumnRowValues.put('End Date', '30/09/2021');
            csvColumnRowValues.put('Expiry Days', '3');
            csvColumnRowValues.put('Fixed Clip Percent', '');
            csvColumnRowValues.put('Start Date', '01/10/2018');
            csvColumnRowValues.put('Tradable Months', '2');
            csvColumnRowValues.put('Tradable Quarters', '1');
            csvColumnRowValues.put('Tradable Seasons', '4');
            csvColumnRowValues.put('Tradable Years', '0');
            csvColumnRowValues.put('Contract RecordType', 'Bryt Contract');
            csvColumnRowValues.put('Account RecordType', 'Bryt Account');
            csvDataListOfMaps.add(csvColumnRowValues);

            List<Object> result = msBrytFileUploadController.mapCsvToApiNamesForContract(csvDataListOfMaps);
            System.assertNotEquals(null, result[0], 'CSV data is missing, and should be passed to method to UPDATE.');
            Test.stopTest();
        }

    }

    @IsTest
    public static void mapCsvToApiNamesForContractTest_AccountFoundButNoBrytConract() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();

            List<Map<String, Object>> csvDataListOfMaps = new List<Map<String, Object>>();
            Map<String, Object> csvColumnRowValues = new Map<String, Object>();

            // CSV test data
            csvColumnRowValues.put('Company', 'NANDO LIMITED');
            csvColumnRowValues.put('Allow Sell Back', 'TRUE');
            csvColumnRowValues.put('Ask Premium', '0');
            csvColumnRowValues.put('Bid Premium', '0');
            csvColumnRowValues.put('Bryt Contract ID', '941053');
            csvColumnRowValues.put('Contract Name', 'NANDO LIMITED');
            csvColumnRowValues.put('Cost Per Trade', '0');
            csvColumnRowValues.put('End Date', '30/09/2021');
            csvColumnRowValues.put('Expiry Days', '3');
            csvColumnRowValues.put('Fixed Clip Percent', '');
            csvColumnRowValues.put('Start Date', '01/10/2018');
            csvColumnRowValues.put('Tradable Months', '2');
            csvColumnRowValues.put('Tradable Quarters', '1');
            csvColumnRowValues.put('Tradable Seasons', '4');
            csvColumnRowValues.put('Tradable Years', '0');
            csvColumnRowValues.put('Contract RecordType', 'Bryt Contract');
            csvColumnRowValues.put('Account RecordType', 'Bryt Account');
            csvDataListOfMaps.add(csvColumnRowValues);

            List<Object> result = msBrytFileUploadController.mapCsvToApiNamesForContract(csvDataListOfMaps);
            System.assertNotEquals(null, result[1], 'CSV data is missing, and should be passed to method to INSERT.');
            Test.stopTest();
        }
    }

    @IsTest
    public static void mapCsvToApiNamesForContractTest_NoAccountFound() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();

            List<Map<String, Object>> csvDataListOfMaps = new List<Map<String, Object>>();
            Map<String, Object> csvColumnRowValues = new Map<String, Object>();

            // CSV test data
            csvColumnRowValues.put('Company', 'AccountNotFound');
            csvColumnRowValues.put('Allow Sell Back', 'TRUE');
            csvColumnRowValues.put('Ask Premium', '0');
            csvColumnRowValues.put('Bid Premium', '0');
            csvColumnRowValues.put('Bryt Contract ID', '941053');
            csvColumnRowValues.put('Contract Name', 'AccountNotFound');
            csvColumnRowValues.put('Cost Per Trade', '0');
            csvColumnRowValues.put('End Date', '30/09/2021');
            csvColumnRowValues.put('Expiry Days', '3');
            csvColumnRowValues.put('Fixed Clip Percent', '');
            csvColumnRowValues.put('Start Date', '01/10/2018');
            csvColumnRowValues.put('Tradable Months', '2');
            csvColumnRowValues.put('Tradable Quarters', '1');
            csvColumnRowValues.put('Tradable Seasons', '4');
            csvColumnRowValues.put('Tradable Years', '0');
            csvColumnRowValues.put('Contract RecordType', 'Bryt Contract');
            csvColumnRowValues.put('Account RecordType', 'Bryt Account');
            csvDataListOfMaps.add(csvColumnRowValues);

            List<Object> result = msBrytFileUploadController.mapCsvToApiNamesForContract(csvDataListOfMaps);
            System.assertNotEquals(null, result[1], 'Account not found in CSV.');
            Test.stopTest();
        }
    }

    @IsTest
    public static void mapCsvToApiNamesForReferenceCapacitiesTest() { // List<Map<String, Object>> csvListOfMapsRefCap
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        String ContentDocumentId4 = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = 'testCsvContentVersion4' LIMIT 1].ContentDocumentId;
        List<String> fileIds = new List<String>();
        fileIds.add(ContentDocumentId4);

        System.runAs(testUser) {
            Test.startTest();
            List<Map<String, Object>> csvListReferenceCapacities =  msBrytUtility.getCsvFromContentVersionGivenContentDocumentId(fileIds[0]);
            msBrytFileUploadController.mapCsvToApiNamesForReferenceCapacities(csvListReferenceCapacities);
            Test.stopTest();
        }
    }

    @IsTest public static void checkIfStringInMapTest_NotFound() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();
            Map<Id, String> myMap = new Map<Id, String>();

            myMap.put('0694E000000fZnHQAU', 'testString');
            String myString = 'randomString';
            Boolean boolTest = msBrytFileUploadController.checkIfStringInMap(myMap, myString);
            Test.stopTest();

            System.assertEquals(false, boolTest, 'Should be False');
        }

    }

    @IsTest public static void checkIfStringInMapTest_Found() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();
            Map<Id, String> myMap = new Map<Id, String>();

            myMap.put('0694E000000fZnHQAU', 'testString');
            String myString = 'testString';
            Boolean boolTest = msBrytFileUploadController.checkIfStringInMap(myMap, myString);
            Test.stopTest();

            System.assertEquals(true, boolTest, 'Should be TRUE');
        }

    }

    @IsTest public static void createAccountWithRecordTypeBrytTest() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser) {
            Test.startTest();
            String testAccount = 'testAccountName';
            Id testAccountId = msBrytFileUploadController.createAccountWithRecordTypeBryt(testAccount);
            Test.stopTest();

            System.assertNotEquals(null, testAccountId, 'No Account created');
        }
    }

}