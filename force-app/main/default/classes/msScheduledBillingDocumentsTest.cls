/**
 *   Create By	 : Georg Luch (Statkraft)
 *   Create Date : 26.05.2021
 *   Description : Test class for msScheduledBillingDocuments
 */

@IsTest
public with sharing class msScheduledBillingDocumentsTest {

    @TestSetup static void setup() {
        msTestDataFactory.createTestPortalContext();

        Contact msContact1 = [
                SELECT Id, (
                        SELECT Id, Contract__c
                        FROM Contract_Roles__r
                        WHERE Role__c = 'Customer Portal'
                        AND Start_Date__c <= TODAY
                        AND (End_Date__c = NULL OR End_Date__c >= TODAY)
                        LIMIT 1
                )
                FROM Contact
                WHERE Email = 'decontact@mail.com.testdatafactory'
        ];
        Id contractId = null;
        for (Contract_Role__c roleItem : msContact1.Contract_Roles__r) {
            contractId = roleItem.Contract__c;
        }
        Contract__c testContract = [SELECT Id FROM Contract__c WHERE Id = :contractId LIMIT 1];

        Attachmenttypes__c at = new Attachmenttypes__c();
        at.Related_Object__c = 'Contract__c';
        at.msIsSendNotifications__c = true;
        at.msIsShowInPortal__c = true;
        at.Name = 'EisMan invoice';
        at.msPicklist_Value_API_Name__c = 'EisMan invoice';
        insert at;

        List<ContentVersion> lcv = new List<ContentVersion>();

        // Billing Document. customer was NOT informed about
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test-Billing-Document_NOT-NOTIFIED';
        cv.VersionData = Blob.valueOf('BillingDocument.PDF');
        cv.PathOnClient = '/BillingDocument.PDF';
        cv.customerNotInformed__c = true;
        cv.Attachement_Type__c = 'EisMan invoice';
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion BillingDocument');
        cv.VersionData = bodyBlob;
        cv.CreatedDate = Datetime.newInstanceGmt(2021, 01, 01);
        cv.ContentDocumentId = null;
        cv.customerNotInformed__c = true;
        lcv.add(cv);

        // Billing Document. customer was already informed about
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Test-Billing-Document_NOTIFIED2';
        cv2.VersionData = Blob.valueOf('BillingDocument2.PDF');
        cv2.PathOnClient = '/BillingDocument2.PDF';
        cv2.customerNotInformed__c = false;
        cv2.Attachement_Type__c = 'Billing document';
        Blob bodyBlob2 = Blob.valueOf('Unit Test ContentVersion BillingDocument2');
        cv2.VersionData = bodyBlob2;
        cv2.CreatedDate = Datetime.newInstanceGmt(2021, 01, 01);
        lcv.add(cv2);
        insert lcv;

        ContentVersion ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = testContract.Id;
        contentLink.ContentDocumentId = ContentDocumentId.ContentDocumentId;
        contentLink.ShareType = 'V';
        insert contentLink;

        msUserNotificationSetting__c un1 = new msUserNotificationSetting__c();
        un1.msContact__c = msContact1.Id;
        un1.msNotificationType__c = 'new_invoice';
        insert un1;
    }

    @IsTest static void runTest() {
        Test.startTest();
        msScheduledBillingDocuments r = new msScheduledBillingDocuments();
        r.run('new_invoice');
        List<msUserNotificationSetting__c> userNotificationSettings = r.getSubscribedUsersToNotification('new_invoice');

        System.assert(userNotificationSettings != null, 'No user found for notification, please add user with notification type new_invoice to msUserNotificationSetting__c.');
        Test.stopTest();
    }

    @IsTest static void runTest_NoSubscribedUsersFound() {
        Test.startTest();
        msScheduledBillingDocuments r = new msScheduledBillingDocuments();
        r.run('new_invoice_BAD_INVOICE_TYPE_GIVEN');
        List<msUserNotificationSetting__c> userNotificationSettings = r.getSubscribedUsersToNotification('new_invoice_BAD_INVOICE_TYPE_GIVEN');

        System.assert(userNotificationSettings.isEmpty(), 'Assuming that there is no subscribed users. Why the hack have we found users here ?????');
        Test.stopTest();
    }

    @IsTest
    private static void getSubscribedUsersToNotificationTest() {
        Test.startTest();
        msScheduledBillingDocuments s = new msScheduledBillingDocuments();
        List<msUserNotificationSetting__c> userNotificationSettings = s.getSubscribedUsersToNotification('new_invoice');

        System.assert(userNotificationSettings != null, 'No user found for notification, please add user with notification type new_invoice to msUserNotificationSetting__c.');
        Test.stopTest();
    }

    @IsTest
    private static void getContractIdsGivenSubscribedUsersTest() {
        Test.startTest();
        msScheduledBillingDocuments s = new msScheduledBillingDocuments();
        List<msUserNotificationSetting__c> subscribedUsers = s.getSubscribedUsersToNotification('new_invoice');
        List<String> userNotificationSettings = s.getContractIdsGivenSubscribedUsers(subscribedUsers);

        System.assert(!userNotificationSettings.isEmpty(), 'There is no Contracts for the subscribed user, please create a contract.');
        Test.stopTest();
    }

    @IsTest
    private static void createContractIdToListOfContentVersionsTest() {
        Test.startTest();
        Datetime currentDate = Datetime.now();

        msScheduledBillingDocuments s = new msScheduledBillingDocuments();
        List<msUserNotificationSetting__c> subscribedUsers = s.getSubscribedUsersToNotification('new_invoice');
        List<String> contractsToNotifyAboutNewBillingDocument = s.getContractIdsGivenSubscribedUsers(subscribedUsers);
        Map<Id, List<ContentVersion>> mapWithIdsAndContentVersion = s.createContractIdToListOfContentVersions(currentDate, contractsToNotifyAboutNewBillingDocument);

        System.assert(!mapWithIdsAndContentVersion.isEmpty(), 'No Contracts and ContentVersion found. Create contract + upload a document and link it in ContentDocumentLink');
        Test.stopTest();
    }

    @IsTest
    private static void setCustomerNotInformedFieldInContentVersionToFalseTest() {
        Test.startTest();
        Datetime currentDate = Datetime.now();

        msScheduledBillingDocuments s = new msScheduledBillingDocuments();
        List<msUserNotificationSetting__c> subscribedUsers = s.getSubscribedUsersToNotification('new_invoice');
        List<String> contractsToNotifyAboutNewBillingDocument = s.getContractIdsGivenSubscribedUsers(subscribedUsers);
        Map<Id, List<ContentVersion>> mapWithIdsAndContentVersion = s.createContractIdToListOfContentVersions(currentDate, contractsToNotifyAboutNewBillingDocument);
        s.setCustomerNotInformedFieldInContentVersionToFalse(mapWithIdsAndContentVersion);

        System.assert(!mapWithIdsAndContentVersion.isEmpty(), 'Map with Ids and content version should not be empty at this point.'); // customerNotInformed__c == FALSE
        Test.stopTest();
    }

}