/****************************************************************************************************
* Class msNotificationLogicTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	Testclass for the class msNotificationLogic.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019       	Init version.
*   * Christian Gottlieb (mindsquare GmbH)		02.05.2019       	V2 for NewCoreModel
*****************************************************************************************************/
@IsTest
private with sharing class msNotificationLogicTest {
    @TestSetup
    static void setup() {
        msTestDataFactory.createTestPortalContext();
    }
    @IsTest
    static void distributeMessagesTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        List<Meter__c> testMeters = [
                SELECT Id
                FROM Meter__c
                WHERE Id IN (
                        SELECT Meter__c
                        FROM Site_Role__c
                        WHERE Contact__c = :testUser.ContactId
                        AND Start_Date__c <= :Date.today()
                        AND End_Date__c >= :Date.today()
                )
                LIMIT 1
        ];
        List<String> testMeterIds = new List<String>();
        for (Meter__c meterItem : testMeters) {
            testMeterIds.add(meterItem.Id);
        }
        List<Contract__c> testContracts = [
                SELECT Id
                FROM Contract__c
                WHERE Id IN (
                        SELECT Contract__c
                        FROM Contract_Role__c
                        WHERE Contact__c = :testUser.ContactId
                        AND Start_Date__c <= :Date.today()
                        AND End_Date__c >= :Date.today()
                )
        ];
        List<String> testContractIds = new List<String>();
        for (Contract__c contractItem : testContracts) {
            testContractIds.add(contractItem.Id);
        }
        Test.startTest();
        msNotificationLogic.distributeMessage('Meter__c', testMeterIds, 'new_invoice', 'de', 'test subject', 'test body of message', null);
        msNotificationLogic.distributeMessage('Contract__c', testContractIds, 'new_invoice', 'de', 'test subject', 'test body of message', null);
        msNotificationLogic.distributeMessage('Contract__c', testContractIds, 'downreg_notification', null, null, null, null);
        msNotificationLogic.distributeMessage('Contact', new List<Id>{
                testUser.ContactId
        }, 'new_invoice', 'de', 'test subject', 'test body of message', null);
        msNotificationLogic.distributeMessage('User', new List<Id>{
                testUser.Id
        }, 'new_invoice', 'de', 'test subject', 'test body of message', null);
        msNotificationLogic.distributeMessage('Meter__c', testMeterIds, 'live_metering_missing_reminder', 'de', 'test subject', 'test body of message', null);
        Test.stopTest();
    }
    @IsTest
    static void testMessagesByDocumentTrigger() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        List<Meter__c> testMeters = [
                SELECT Id
                FROM Meter__c
                WHERE Id IN (
                        SELECT Meter__c
                        FROM Site_Role__c
                        WHERE Contact__c = :testUser.ContactId
                        AND Start_Date__c <= :Date.today()
                        AND End_Date__c >= :Date.today()
                )
                LIMIT 1
        ];
        List<String> testMeterIds = new List<String>();
        for (Meter__c meterItem : testMeters) {
            testMeterIds.add(meterItem.Id);
        }
        List<Contract__c> testContracts = [
                SELECT Id
                FROM Contract__c
                WHERE Id IN (
                        SELECT Contract__c
                        FROM Contract_Role__c
                        WHERE Contact__c = :testUser.ContactId
                        AND Start_Date__c <= :Date.today()
                        AND End_Date__c >= :Date.today()
                )
        ];
        List<String> testContractIds = new List<String>();
        for (Contract__c contractItem : testContracts) {
            testContractIds.add(contractItem.Id);
        }
        Test.startTest();
        Blob file = Blob.valueOf('testdata');
        ContentVersion testVersion = new ContentVersion(
                Title = 'testVersionCREATION20190603DATE20190506',
                VersionData = file,
                PathOnClient = '/somepath.txt',
                Community_available__c = true,
                Attachement_Type__c = 'Billing Document'
        );
        Database.insert(testVersion);

        testVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = 'testVersionCREATION20190603DATE20190506' LIMIT 1];

        // ContentDocumentLink
        List<ContentDocumentLink> testLinkList = new List<ContentDocumentLink>();
        for (Contract__c contractItem : testContracts) {
            testLinkList.add(new ContentDocumentLink(
                    LinkedEntityId = contractItem.Id,
                    ContentDocumentId = testVersion.ContentDocumentId,
                    ShareType = 'V'
            ));
        }
        insert(testLinkList);
        Test.stopTest();
    }

    @IsTest
    static void testSMSBatch() {
        User testUser = [SELECT Id, Name, ContactId, MobilePhone FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Contact testContact = [SELECT Id, Name, MobilePhone FROM Contact WHERE Id = :testUser.ContactId];

        msNotificationLogic.notificationWrapper wrapper = new msNotificationLogic.notificationWrapper();
        wrapper.contact = testContact;
        wrapper.user = testUser;
        wrapper.userId = testUser.Id;
        wrapper.subject = 'Test';
        wrapper.body = 'Test';

        List<msNotificationLogic.notificationWrapper> messagesSMS = new List<msNotificationLogic.notificationWrapper>();
        messagesSMS.add(wrapper);


        Test.startTest();
        msSMSControllerBatch batch = new msSMSControllerBatch(JSON.serialize(messagesSMS));
        Database.executeBatch(batch);
        Test.stopTest();
    }

    @IsTest
    static void testRegisterEmailNotification() {
        String notificationType = 'new_invoice';
        User testUser1 = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Contact testContact1 = [SELECT Id FROM Contact WHERE Id = :testUser1.ContactId];
        User testUser2 = [SELECT Id, ContactId FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Contact testContact2 = [SELECT Id FROM Contact WHERE Id = :testUser2.ContactId];
        msUserNotificationSetting__c notificationSetting = new msUserNotificationSetting__c();
        notificationSetting.msIsEmail__c = false;
        notificationSetting.msContact__c = testContact1.Id;
        notificationSetting.msNotificationType__c = notificationType;
        insert notificationSetting;

        Test.startTest();
        msNotificationLogic.registerEmailNotification(notificationType, new Set<Id>{
                testContact1.Id, testContact2.Id
        });
        Test.stopTest();

        msUserNotificationSetting__c settingsUser1 = [
                SELECT Id, msIsEmail__c
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = :notificationType
                AND msContact__c = :testContact1.Id
                LIMIT 1
        ];
        msUserNotificationSetting__c settingsUser2 = [
                SELECT Id, msIsEmail__c
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = :notificationType
                AND msContact__c = :testContact2.Id
                LIMIT 1
        ];
        System.assertEquals(false, settingsUser1.msIsEmail__c, 'email notification settings should not be changed');
        System.assertEquals(true, settingsUser2.msIsEmail__c, 'email notification settings should be enabled');
    }

    @IsTest
    static void shouldGetEmailTemplateByName() {
        String templateName = NpaiDeadlineNotifScheduledQueueable.ASSESSMENT_DUE_TEMPLATE_NAME;

        Test.startTest();

        EmailTemplate template = msNotificationLogic.getEmailTemplateByName(templateName);

        Test.stopTest();

        System.assertNotEquals(null, template);
    }

    @IsTest
    static void shouldNotGetEmailTemplateByName() {
        String templateName = 'Fake template name';

        Test.startTest();

        EmailTemplate template = msNotificationLogic.getEmailTemplateByName(templateName);

        Test.stopTest();

        System.assertEquals(null, template);
    }

    @IsTest
    static void shouldCreateSingleEmailMessageWithTemplateId() {
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        NPC_Cases__c testCase = new NPC_Cases__c(Name = 'Test Case Name');
        insert testCase;
        String department = NPC_Assessment__c.Statkraft_Department__c.getDescribe().getPicklistValues()[0].getValue();
        NPC_Assessment__c assessment = new NPC_Assessment__c(
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = department,
                FARA__c = ai_PicklistValueController.getDependentPicklist(NPC_Assessment__c.FARA__c).get(department)[0]
        );
        insert assessment;
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :NpaiDeadlineNotifScheduledQueueable.ASSESSMENT_DUE_TEMPLATE_NAME];

        Test.startTest();

        Messaging.SingleEmailMessage msg = msNotificationLogic.createSingleEmailMessageWithTemplateId(testUser.Id, assessment.Id, template.Id);

        Test.stopTest();

        System.assertEquals(template.Id, msg.getTemplateId());
        System.assertEquals(testUser.Id, msg.getTargetObjectId());
        System.assertEquals(assessment.Id, msg.getWhatId());
        System.assert(!msg.getSaveAsActivity());
        System.assert(!msg.getUseSignature());
        System.assert(!msg.getBccSender());
    }

    @IsTest
    static void shouldSendTemplatedEmailToAddressesForRecords() {
        NPC_Cases__c testCase = new NPC_Cases__c(Name = 'Test Case Name');
        insert testCase;
        String department = NPC_Assessment__c.Statkraft_Department__c.getDescribe().getPicklistValues()[0].getValue();
        NPC_Assessment__c assessment = new NPC_Assessment__c(
                OwnerId = UserInfo.getUserId(),
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = department,
                FARA__c = ai_PicklistValueController.getDependentPicklist(NPC_Assessment__c.FARA__c).get(department)[0]
        );
        insert assessment;
        Map<Id, NPC_Assessment__c> recipientsByRecordIds = new Map<Id, NPC_Assessment__c>{
                assessment.Id => assessment
        };

        Test.startTest();

        OrgWideEmailAddress orgAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'npai_salesforce@statkraft.com' LIMIT 1];
        List<Messaging.SendEmailResult> results = msNotificationLogic.sendTemplatedEmailToAddressesForRecords(
                orgAddress,
                recipientsByRecordIds,
                NpaiDeadlineNotifScheduledQueueable.ASSESSMENT_DUE_TEMPLATE_NAME
        );
        Integer getEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();

        System.assertEquals(1, getEmailsSent, 'Should send out email');
        System.assertEquals(1, results.size());
    }

    @IsTest
    static void failureToSend1001Emails_Test() {
        Id randomUserId = UserInfo.getUserId();
        msNotificationLogic.debugModeWrapper debugMode = new msNotificationLogic.debugModeWrapper();
        List<msNotificationLogic.notificationWrapper> moreThanOneThousandEmails =
                new List<msNotificationLogic.notificationWrapper>();
        for (Integer i = 0; i < 1001; i++) {
            msNotificationLogic.notificationWrapper newWrapper = new msNotificationLogic.notificationWrapper();
            newWrapper.userId = randomUserId;
            newWrapper.messageType = 'test';
            moreThanOneThousandEmails.add(newWrapper);
        }

        Test.startTest();

        try {
            msNotificationLogic.sendEmailMessages(moreThanOneThousandEmails, debugMode);
            System.assert(false, 'The expected Error was not thrown to stop the distribution of too many Emails');
        } catch (msNotificationLogic.NotificationFrameworkException e) {
            System.assert(e.getMessage().contains(Label.NotificationFrameworkEmailOverloadErrorMessage));
        } catch (Exception e) {
            System.assert(false, 'An unexpected Error happened: ' + e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    static void createMeteringLiveDataCase_Test() {
        Id randomUserId = UserInfo.getUserId();

        List<msNotificationLogic.notificationWrapper> list_1 = new List<msNotificationLogic.notificationWrapper>();
        msNotificationLogic.notificationWrapper wrapper_notify = new msNotificationLogic.notificationWrapper();
        wrapper_notify.userId = randomUserId;
        list_1.add(wrapper_notify);

        List<msNotificationLogic.meterIdToUserIdForTasksWrapper> list_2 = new List<msNotificationLogic.meterIdToUserIdForTasksWrapper>();
        msNotificationLogic.meterIdToUserIdForTasksWrapper meterWrapper = new msNotificationLogic.meterIdToUserIdForTasksWrapper();
        meterWrapper.userId = randomUserId;
        list_2.add(meterWrapper);

        List<msNotificationLogic.contractualContactsWrapper> list_3 = new List<msNotificationLogic.contractualContactsWrapper>();
        msNotificationLogic.contractualContactsWrapper contractWrapper = new msNotificationLogic.contractualContactsWrapper();
        list_3.add(contractWrapper);

        String messageTypeForLiveMeter = 'test';

        Test.startTest();

        List<Case> cases = msNotificationLogic.createLiveMetringCases(list_1, list_2, list_3, messageTypeForLiveMeter);

        Test.stopTest();

        System.assert(!cases.isEmpty());
    }

    @IsTest
    static void createMeteringLiveDatatask_Test() {
        Id randomUserId = UserInfo.getUserId();

        List<msNotificationLogic.notificationWrapper> list_1 = new List<msNotificationLogic.notificationWrapper>();
        msNotificationLogic.notificationWrapper wrapper_notify = new msNotificationLogic.notificationWrapper();
        wrapper_notify.userId = randomUserId;
        list_1.add(wrapper_notify);

        List<msNotificationLogic.meterIdToUserIdForTasksWrapper> list_2 = new List<msNotificationLogic.meterIdToUserIdForTasksWrapper>();
        msNotificationLogic.meterIdToUserIdForTasksWrapper meterWrapper = new msNotificationLogic.meterIdToUserIdForTasksWrapper();
        meterWrapper.userId = randomUserId;
        list_2.add(meterWrapper);

        List<msNotificationLogic.contractualContactsWrapper> list_3 = new List<msNotificationLogic.contractualContactsWrapper>();
        msNotificationLogic.contractualContactsWrapper contractWrapper = new msNotificationLogic.contractualContactsWrapper();
        list_3.add(contractWrapper);

        String messageTypeForLiveMeter = 'test';
        List<Case> cases = msNotificationLogic.createLiveMetringCases(list_1, list_2, list_3, messageTypeForLiveMeter);
        Test.startTest();

        List<Task> tasks = msNotificationLogic.createLiveMetringTasks(cases, list_2);

        Test.stopTest();

        System.assert(!tasks.isEmpty());
    }

    @IsTest
    static void sendLessThan500ChatterMessages_Test() {
        Id randomUserId = UserInfo.getUserId();
        msNotificationLogic.debugModeWrapper debugMode = new msNotificationLogic.debugModeWrapper();
        List<msNotificationLogic.notificationWrapper> lessThan500Emails =
                new List<msNotificationLogic.notificationWrapper>();
        for (Integer i = 0; i < 100; i++) {
            msNotificationLogic.notificationWrapper newWrapper = new msNotificationLogic.notificationWrapper();
            newWrapper.userId = randomUserId;
            newWrapper.messageType = 'test';
            lessThan500Emails.add(newWrapper);
        }

        Test.startTest();
        msNotificationLogic.sendInPortalMessages(lessThan500Emails, debugMode);
        Test.stopTest();
    }

    @IsTest
    static void sendMoreThan500ChatterMessages_Test() {
        Id randomUserId = UserInfo.getUserId();
        msNotificationLogic.debugModeWrapper debugMode = new msNotificationLogic.debugModeWrapper();
        List<msNotificationLogic.notificationWrapper> moreThan500Emails =
                new List<msNotificationLogic.notificationWrapper>();
        for (Integer i = 0; i < 502; i++) {
            msNotificationLogic.notificationWrapper newWrapper = new msNotificationLogic.notificationWrapper();
            newWrapper.userId = randomUserId;
            newWrapper.messageType = 'test';
            moreThan500Emails.add(newWrapper);
        }

        Test.startTest();
        msNotificationLogic.sendInPortalMessages(moreThan500Emails, debugMode);
        Test.stopTest();
    }

    @IsTest
    static void formatSMS_Test_NoTranslationsAvailable() {
        msNotificationLogic.translationIndexingWrapper tanslationsIsEmpty = new msNotificationLogic.translationIndexingWrapper();
        Map<String, String> glossary = new Map<String, String>();
        User testUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Test.startTest();
        msNotificationLogic.notificationWrapper formattedSMS = msNotificationLogic.formatSMS(testUser, tanslationsIsEmpty, '', glossary);
        Test.stopTest();

        System.assert(formattedSMS == null); // As no translations are available, we should get NULL
    }

    @IsTest
    static void formatSMS_Test_TranslationsAvailable() {
        User testUser = [SELECT Id, Name, LastName, ContactId, MobilePhone, LanguageLocaleKey, Contact.Salutation, Contact.MobilePhone, Contact.Email FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        msNotificationLogic.translationWrapper tW = new msNotificationLogic.translationWrapper();
        msNotificationLogic.translationIndexingWrapper tanslationsIsNotEmpty = new msNotificationLogic.translationIndexingWrapper();
        tanslationsIsNotEmpty.languages = new Map<String, msNotificationLogic.translationWrapper>();
        tanslationsIsNotEmpty.languages.put('en', tW);

        Map<String, String> glossary = new Map<String, String>();

        Test.startTest();
        msNotificationLogic.notificationWrapper wrapper = msNotificationLogic.formatSMS(testUser, tanslationsIsNotEmpty, '', glossary);
        Test.stopTest();

        System.assert(wrapper != null); // As translations are available in english(en), we should NOT get a NULL return value
    }
}