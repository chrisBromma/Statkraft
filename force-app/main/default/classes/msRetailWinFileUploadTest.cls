/****************************************************************************************************
* Class msRetailWinFileUploadTest
*
*   Create By	:   Michael Demars (Statkraft)
*   Create Date	:
*   Description	:	Test class for the Apex Controller msRetailWinFileUpload
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Michael Demars (Statkraft)                                  	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      27.11.2019              New asynchronous API version
*****************************************************************************************************/
@IsTest
public class msRetailWinFileUploadTest {
	
    // Setup test data for Accounts, Contacts and a portal users
    @TestSetup
    private static void setupTestData() {
        msTestDataFactory.createTestPortalContext();
    }
    
    @IsTest
    private static void checklatestUploads() {
        User usr = [SELECT Id FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account UK' LIMIT 1];
        Test.startTest();
        System.runAs(usr){
            msRetailWinFileUpload.UserFileWrapper files = msRetailWinFileUpload.getUploads();
            System.assertEquals(acc.Id, files.recordId);
            System.assertEquals(null, files.contentVersionList);
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void uploadSingleFile() {
        User usr = [SELECT Id FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account UK' LIMIT 1];
        Test.startTest();
        // mock upload, as this is handled by a lightning component internally
        // create an upload file        
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = 'Test_File_1.txt';
        file.IsMajorVersion = true;
        insert file;
        List<ContentVersion> insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile[0].ContentDocumentId;
        cvl.LinkedEntityId = acc.Id;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
		insert cvl;
        
        // test get uploads
        System.runAs(usr) {
            msRetailWinFileUpload.UserFileWrapper files = msRetailWinFileUpload.getUploads();
            System.assertEquals(acc.Id, files.recordId);
            System.assertEquals(1, files.contentVersionList.size());
        }
        Test.stopTest();
    }
    @IsTest
    private static void uploadTwoFiles() {
        User usr = [SELECT Id FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account UK' LIMIT 1];
        Test.startTest();
        // mock upload, as this is handled by a lightning component internally
        // create an upload file        
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = 'Test_File_1.txt';
        file.IsMajorVersion = true;
        insert file;
        List<ContentVersion> insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile[0].ContentDocumentId;
        cvl.LinkedEntityId = acc.Id;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
		insert cvl;
        // create an upload file        
        ContentVersion file2 = new ContentVersion();
        file2.VersionData = Blob.valueOf('populated');
        file2.Title = 'Test File 1';
        file2.PathOnClient = 'Test_File_1.txt';
        file2.IsMajorVersion = true;
        insert file2;
        List<ContentVersion> insertedFile2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file2.Id];
        ContentDocumentLink cvl2 = new ContentDocumentLink();
        cvl2.ContentDocumentId = insertedFile2[0].ContentDocumentId;
        cvl2.LinkedEntityId = acc.Id;
        cvl2.ShareType= 'V';
        cvl2.Visibility = 'AllUsers';
		insert cvl2;
        // test get uploads
        System.runAs(usr){
            msRetailWinFileUpload.UserFileWrapper files = msRetailWinFileUpload.getUploads();
            System.assertEquals(acc.Id, files.recordId);
            System.assertEquals(2, files.contentVersionList.size());
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void uploadTwoFilesDifferentAccounts() {

        User usr = [SELECT Id FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account UK' LIMIT 1];
        Test.startTest();
        // mock upload, as this is handled by a lightning component internally
        // create an upload file        
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = 'Test_File_1.txt';
        file.IsMajorVersion = true;
        insert file;
        List<ContentVersion> insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile[0].ContentDocumentId;
        cvl.LinkedEntityId = acc.Id;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
		insert cvl;
        // create an upload file   
        Account secondAccount = new Account(Name = 'UK other Account');
        insert secondAccount;
        ContentVersion file2 = new ContentVersion();
        file2.VersionData = Blob.valueOf('populated');
        file2.Title = 'Test File 1';
        file2.PathOnClient = 'Test_File_1.txt';
        file2.IsMajorVersion = true;
        insert file2;
        
        ContentVersion insertedFile2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file2.Id LIMIT 1];
        ContentDocumentLink cvl2 = new ContentDocumentLink();
        cvl2.ContentDocumentId = insertedFile2.ContentDocumentId;
        cvl2.LinkedEntityId = secondAccount.Id;
        cvl2.ShareType= 'V';
        cvl2.Visibility = 'AllUsers';
		insert cvl2;
        
        // test get uploads
        System.runAs(usr) {
            msRetailWinFileUpload.UserFileWrapper files = msRetailWinFileUpload.getUploads();
            System.assertEquals(acc.Id, files.recordId);
            System.assertEquals(1, files.contentVersionList.size());
        }
        Test.stopTest();
    }

    @IsTest private static void initiateFileValidationSuccess() {

        Id AccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account testAccount = new Account(
                Name = 'Squeaky',
                RecordTypeId = AccRecId,
                Customer_Type__c = 'not yet identified'
        );
        insert(testAccount);
        User usr = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Contact testUserContact = [SELECT Id, AccountId FROM Contact WHERE Id =: usr.ContactId LIMIT 1];
        testUserContact.AccountId = testAccount.Id;
        update testUserContact;
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testAccount.Id;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Success":true,"Errors":["bla","bla"],"FileName":"FIXED_BRYT_20190206_1530_success.xlsx","FileId":"'+ insertedFile.ContentDocumentId + '"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinFile_Upload_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        // test get uploads
        Test.startTest();
        System.runAs(usr) {
            System.debug('Validing file-id: ' + cvl);
            List<msRetailWinFileUpload.UploadResult> results = msRetailWinFileUpload.initiateFilesValidation(new List<Id>{cvl.ContentDocumentId});
            System.assertEquals(true, results[0].Success);
        }
        Test.stopTest();
    }
    @IsTest private static void initiateFileValidationError() {

        Id AccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account testAccount = new Account(
                Name = 'Squeaky',
                RecordTypeId = AccRecId,
                Customer_Type__c = 'not yet identified'
        );
        insert(testAccount);
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Contact testUserContact = [SELECT Id, AccountId FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];
        testUserContact.AccountId = testAccount.Id;
        update testUserContact;
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testAccount.Id;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Success":false,"Errors":["bla","bla"],"FileName":"FIXED_BRYT_20190206_1530_success.xlsx","FileId":"'+ insertedFile.ContentDocumentId + '"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinFile_Upload_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        // test get uploads
        Test.startTest();
        System.runAs(testUser) {
            System.debug('Validing file-id: ' + cvl);
            List<msRetailWinFileUpload.UploadResult> results = msRetailWinFileUpload.initiateFilesValidation(new List<Id>{cvl.ContentDocumentId});
            System.assertEquals(false, results[0].Success);
        }
        Test.stopTest();
    }
    @IsTest private static void initiateFileValidationNoAnswer() {

        Id AccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account testAccount = new Account(
                Name = 'Squeaky',
                RecordTypeId = AccRecId,
                Customer_Type__c = 'not yet identified'
        );
        insert(testAccount);
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Contact testUserContact = [SELECT Id, AccountId FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];
        testUserContact.AccountId = testAccount.Id;
        update testUserContact;
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testAccount.Id;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Success":false,"Errors":["bla","bla"],"FileName":"FIXED_BRYT_20190206_1530_success.xlsx","FileId":"0694E000000asI6QAI"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinFile_Upload_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        // test get uploads
        Test.startTest();
        System.runAs(testUser) {
            System.debug('Validing file-id: ' + cvl);
            List<msRetailWinFileUpload.UploadResult> results = msRetailWinFileUpload.initiateFilesValidation(new List<Id>{cvl.ContentDocumentId});
        }
        Test.stopTest();
    }
    @IsTest private static void validateNoAccount() {

        Id AccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account testAccount = new Account(
                Name = 'NoName',
                RecordTypeId = AccRecId,
                Customer_Type__c = 'not yet identified'
        );
        insert(testAccount);
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Contact testUserContact = [SELECT Id, AccountId FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];
        testUserContact.AccountId = testAccount.Id;
        update testUserContact;
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testAccount.Id;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;
        // test get uploads
        Test.startTest();
        System.runAs(testUser) {
            System.debug('Validing file-id: ' + cvl);
            List<msRetailWinFileUpload.UploadResult> results = msRetailWinFileUpload.initiateFilesValidation(new List<Id>{cvl.ContentDocumentId});
            System.assertEquals(false, results[0].Success);
            System.assertEquals('Unexpected Parent Account: ' + testAccount.Name, results[0].Errors[0]);
        }
        Test.stopTest();
    }
    @IsTest private static void callValidationTestQueuedResult() {

        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        file.msIsUploaded__c = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testUser.Contact.AccountId;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Status":-9,"Messages":["bla","bla"],"FileName": "FIXED_BRYT_20190206_1530_success.xlsx","FileId":"'+ insertedFile.ContentDocumentId+'"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinfile_Validation_Status_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        Test.startTest();
        System.runAs(testUser) {
            List<msRetailWinFileUpload.ValidationResult> results = msRetailWinFileUpload.retrieveValidationResults();
        }
        Test.stopTest();
    }
    @IsTest private static void callValidationTestProcessingResult() {

        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        file.msIsUploaded__c = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testUser.Contact.AccountId;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Status":0,"Messages":["bla","bla"],"FileName": "FIXED_BRYT_20190206_1530_success.xlsx","FileId":"'+ insertedFile.ContentDocumentId+'"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinfile_Validation_Status_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        Test.startTest();
        System.runAs(testUser) {
            List<msRetailWinFileUpload.ValidationResult> results = msRetailWinFileUpload.retrieveValidationResults();
        }
        Test.stopTest();
    }
    @IsTest private static void callValidationTestSuccessResult() {

        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        file.msIsUploaded__c = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testUser.Contact.AccountId;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Status":1,"Messages":["bla","bla"],"FileName": "FIXED_BRYT_20190206_1530_success.xlsx","FileId":"'+ insertedFile.ContentDocumentId+'"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinfile_Validation_Status_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        Test.startTest();
        System.runAs(testUser) {
            List<msRetailWinFileUpload.ValidationResult> results = msRetailWinFileUpload.retrieveValidationResults();
        }
        Test.stopTest();
    }

    @IsTest private static void callValidationTestErrorResult() {

        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        file.msIsUploaded__c = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testUser.Contact.AccountId;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Status":-1,"Messages":["bla","bla"],"FileName": "FIXED_BRYT_20190206_1530_success.xlsx","FileId":"'+ insertedFile.ContentDocumentId+'"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinfile_Validation_Status_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        Test.startTest();
        System.runAs(testUser) {
            List<msRetailWinFileUpload.ValidationResult> results = msRetailWinFileUpload.retrieveValidationResults();
        }
        Test.stopTest();
    }
    @IsTest private static void callValidationTestNotMatchingResult() {

        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        String fileName = 'upload_success.xlsx';
        // create an upload file
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf('populated');
        file.Title = 'Test File 1';
        file.PathOnClient = fileName;
        file.IsMajorVersion = true;
        file.msIsUploaded__c = true;
        insert file;
        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        ContentDocumentLink cvl = new ContentDocumentLink();
        cvl.ContentDocumentId = insertedFile.ContentDocumentId;
        cvl.LinkedEntityId = testUser.Contact.AccountId;
        cvl.ShareType= 'V';
        cvl.Visibility = 'AllUsers';
        insert cvl;

        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"Status":0,"Messages":["bla","bla"],"FileName": "FIXED_BRYT_20190206_1530_success.xlsx","FileId":"0694E000000asI6QAI"}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().RetailWinfile_Validation_Status_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        Test.startTest();
        System.runAs(testUser) {
            List<msRetailWinFileUpload.ValidationResult> results = msRetailWinFileUpload.retrieveValidationResults();
        }
        Test.stopTest();
    }
    @IsTest
    private static void isInBusinessHoursTest() {
        Date today = Date.today();
        Date saturday = Date.newInstance(1900, 1, 6);
        Date sunday = Date.newInstance(1900, 1, 7);
        Integer modSaturday = Math.mod(today.daysBetween(saturday),7);
        Integer modSunday = Math.mod(today.daysBetween(sunday),7);

        msPortalSystemSetting__mdt portalSettings = msUtility.getPortalSettings();
        Time targetTimeStart = Time.newInstance((Integer)portalSettings.RetailStartTimeHour__c,
                (Integer) portalSettings.RetailStartTimeMinute__c, 0, 0);
        Time targetTimeEnd = Time.newInstance((Integer)portalSettings.RetailEndTimeHour__c,
                (Integer) portalSettings.RetailEndTimeMinute__c, 0, 0);

        TimeZone targetTimezone = TimeZone.getTimeZone('Europe/London');
        Integer offsetSeconds = targetTimezone.getOffset(today) / 1000;

        Datetime targetDatetimeStart = Datetime.newInstanceGmt(today, targetTimeStart)
                .addSeconds(-offsetSeconds);
        Datetime targetDatetimeEnd = Datetime.newInstanceGmt(today, targetTimeEnd)
                .addSeconds(-offsetSeconds);
        Test.startTest();
        if(modSaturday == 0 || modSunday == 0 ||
                Datetime.now() < targetDatetimeStart ||
                Datetime.now() > targetDatetimeEnd) {
            System.assert(!msRetailWinFileUpload.isInBusinessHours(), 'Today is on a weekend or out of the Time Range of business hours');
        } else {
            System.assert(msRetailWinFileUpload.isInBusinessHours(), 'Today is on a weekday and in the time range for business hours');
        }
        insert new Operational_Holiday__c(Name = 'test', Affected_Date__c = Date.today(), Market__c = 'UK');
        System.assert(!msRetailWinFileUpload.isInBusinessHours(), 'This should fail since today is a holiday');
        Test.stopTest();
    }
}