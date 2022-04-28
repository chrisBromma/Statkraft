/****************************************************************************************************
* Class msNotificationLogic
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   19.02.2019
*   Description	:	This class carries the logic and text gathering between the messageTypes and the actual
*                   messages in all available translations. See the msNotificationDetails Custom Meta Data for the
*                   translation details.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		19.02.2019       	Init version.
*   * Fabian Kramer (mindsquare GmbH)           06.03.2019
*   * Christian Gottlieb (mindsquare GmbH)      29.04.2019          V2 for New Core Model
*   * Christian Gottlieb (mindsquare GmbH)      03.07.2019          V3 with streamlined translations
*   * Christian Gottlieb (mindsquare GmbH)      22.08.2019          V4 with merge field glossary
*   * Christian Gottlieb (mindsquare GmbH)      12.12.2019          V5 with central Notification scheduler and debug mode
*****************************************************************************************************/
global without sharing class msNotificationLogic {
    private static final String CUSTOMER_PORTAL = 'Customer Portal';

    // Fixed values for or Case creation. Each Reminder-Notification will create a Case.
    private static final String CASE_STANDARD_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
    private static final Id CASE_OWNER_ID = [SELECT Id FROM Group WHERE DeveloperName = 'Sales_Coordinators_EEG' LIMIT 1].Id;
    private static final Id TASK_OWNER_ID = [SELECT Id FROM User WHERE Name = 'System' LIMIT 1].Id;
    private static final Id CASE_CREATOR = [SELECT Id FROM User WHERE LastName = 'System' LIMIT 1].Id;

    public static Integer distributeMessage(String objectType, List<String> recordIds, String messageType,
            String languageKey, String subject, String body, Map<Id, List<ContentVersion>> entityIdToContentVersions) {

        messageTypesTranslations allMessages = msChatterUtility.getMessageTranslations(messageType, languageKey, subject, body);
        Map<String, Map<String, String>> attachmentTypeTranslations = msChatterUtility.getAttachmentTypeTranslations();

        // Hold our messageType as it can be overwritten by the code-segment below.
        String messageTypeForLiveMeter = messageType;

        //Currently this is set up to generate only a map with a keySet containing only one message type
        //This might change in the future, if notifications get more complex
        messageType = new List<String> (allMessages.messageTypes.keySet())[0];

        debugModeWrapper debugMode = msChatterUtility.getDebugMode(messageType);

        translationIndexingWrapper translations = allMessages.messageTypes.get(messageType);
        List<notificationWrapper> messagesInPortal = new List<notificationWrapper>();
        List<notificationWrapper> messagesEmail = new List<notificationWrapper>();
        List<notificationWrapper> messagesSMS = new List<notificationWrapper>();
        Map<Id, Set<String>> contactIdToListOfContractNames = new Map<Id, Set<String>>();
        Map<Id, Set<Id>> contactIdToListOfContractIds = new Map<Id, Set<Id>>();
        Map<Id, List<MeterRegistration__c>> contactIdToListOfMeterRegs = new Map<Id, List<MeterRegistration__c>>();
        Set<Id>contactIds = new Set<Id>();
        Map<String, String> glossary = new Map<String, String>();
        Map<Id, MeterRegistration__c> contractIdToMeterRegistrationMap = new Map<Id, MeterRegistration__c>();
        Map<Id, MeterRegistration__c> meterIdToMeterRegistrationMap = new Map<Id, MeterRegistration__c>();
        Map<Id, User> userMap = receiveRecipients(objectType, recordIds, messageType);
        Date today = Date.today();
        msPortalSystemSetting__mdt portalSystemSetting = msUtility.getPortalSettings();

        List<Task> taskForLifeMeteringIssueCaseList = new List<Task>(); // Each user-email will create a task(activity)
        List<meterIdToUserIdForTasksWrapper> userIdToMeterIdList = new List<meterIdToUserIdForTasksWrapper>();
        List<contractualContactsWrapper> contractualContactsForEachMeter = receiveContractualContacts(recordIds);
        List<Case> casesForLifeMeteringIssues = new List<Case>();

        // Used for logging
        List<User> userListToLogIntoLoggerConsole = new List<User>();

        for (String userId : userMap.keySet()) {
            contactIds.add(userMap.get(userId).ContactId);
        }

        /**
         * Depending on the object type that we notify about, we identify the contacts that are eligible
         * to receive a notification in general. Also we use this opportunity to already gather information for the
         * user personalized glossary.
         *
         * Currently only Meter__c and Contract__c are supported.
         *
         * TODO: This is pretty ad-hoc, if it is needed more we need a more general way to store that information
        */
        if (objectType == 'Contract__c') {
            for (MeterRegistration__c regItem : [
                    SELECT Id, Contract__c, Contract__r.Name,Contract__r.Contract_Holder__r.Name,Meter__r.Name
                    FROM MeterRegistration__c
                    WHERE Contract__c IN :recordIds
                    AND Active__c = TRUE
            ]) {
                contractIdToMeterRegistrationMap.put(regItem.Contract__c, regItem);
            }
            for (Contract_Role__c role : [
                    SELECT Id, Contract__c, Contract__r.Name, Contact__c
                    FROM Contract_Role__c
                    WHERE Contact__c IN :contactIds
                    AND Contract__c IN :recordIds
                    AND Role__c INCLUDES ('Customer Portal')
                    AND Start_Date__c <= :Date.today()
                    AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
            ]) {
                if (!contactIdToListOfContractNames.containsKey(role.Contact__c)) {
                    contactIdToListOfContractNames.put(role.Contact__c, new Set<String>());
                }
                contactIdToListOfContractNames.get(role.Contact__c).add(role.Contract__r.Name.substringBeforeLast('/'));

                if (!contactIdToListOfContractIds.containsKey(role.Contact__c)) {
                    contactIdToListOfContractIds.put(role.Contact__c, new Set<Id>());
                }
                contactIdToListOfContractIds.get(role.Contact__c).add(role.Contract__c);

                if (!contactIdToListOfMeterRegs.containsKey(role.Contact__c)) {
                    contactIdToListOfMeterRegs.put(role.Contact__c, new List<MeterRegistration__c>());
                }
                contactIdToListOfMeterRegs.get(role.Contact__c).add(contractIdToMeterRegistrationMap.get(role.Contract__c));
            }
        } else if (objectType == 'Meter__c') {

            for (Meter__c meter : [
                    SELECT Id, (
                            SELECT Id, Valid_from__c, Contract__c, Contract__r.Name,Contract__r.Contract_Holder__r.Name,Meter__r.Name, Meter__c
                            FROM Meter_Registrations__r
                            ORDER BY Valid_from__c ASC
                    )
                    FROM Meter__c
                    WHERE Id IN :recordIds
            ]) {
                for (MeterRegistration__c regItem : meter.Meter_Registrations__r) {
                    if (regItem.Valid_from__c <= Date.today()) {
                        meterIdToMeterRegistrationMap.put(meter.Id, regItem);
                    } else if (meterIdToMeterRegistrationMap.get(meter.Id) == null) {
                        meterIdToMeterRegistrationMap.put(meter.Id, regItem);
                        break;
                    }
                }
            }
            for (Site_Role__c roleItem : [
                    SELECT Id, Meter__c, Contact__c
                    FROM Site_Role__c
                    WHERE Contact__c IN :contactIds
                    AND Meter__c IN :recordIds
                    AND Role__c INCLUDES ('Customer Portal')
                    AND Start_Date__c <= :Date.today()
                    AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
            ]) {
                if (!contactIdToListOfContractNames.containsKey(roleItem.Contact__c)) {
                    contactIdToListOfContractNames.put(roleItem.Contact__c, new Set<String>());
                }
                contactIdToListOfContractNames.get(roleItem.Contact__c).add(meterIdToMeterRegistrationMap.get(roleItem.Meter__c).Contract__r.Name.substringBeforeLast('/'));

                if (!contactIdToListOfContractIds.containsKey(roleItem.Contact__c)) {
                    contactIdToListOfContractIds.put(roleItem.Contact__c, new Set<Id>());
                }
                contactIdToListOfContractIds.get(roleItem.Contact__c).add(meterIdToMeterRegistrationMap.get(roleItem.Meter__c).Contract__c);

                if (!contactIdToListOfMeterRegs.containsKey(roleItem.Contact__c)) {
                    contactIdToListOfMeterRegs.put(roleItem.Contact__c, new List<MeterRegistration__c>());
                }
                contactIdToListOfMeterRegs.get(roleItem.Contact__c).add(meterIdToMeterRegistrationMap.get(roleItem.Meter__c));
            }
        }

        ListMapContainer contactIdToNotificationSettingsMap = getNotificationSettings(messageType, contactIds);

        /**
         * During this section, we define the glossary entries (aka Merge Fields) that are independent of the User Context
        */
        String billingDocumentsCommunityURL = '';
        String communityId = [SELECT Id FROM Network WHERE Name = :CUSTOMER_PORTAL LIMIT 1].Id;
        if (!Test.isRunningTest()) {
            try {
                ConnectApi.Community community = ConnectApi.Communities.getCommunity(communityId);
                billingDocumentsCommunityURL = community.siteUrl + '/s/downloads';
            } catch (ConnectApi.NotFoundException e) {
                //outside Rest API calls cause an issue with ConnectApi
                billingDocumentsCommunityURL = 'https://my.statkraft.com/s/downloads';
            }

        } else {
            billingDocumentsCommunityURL = 'https://sample-community.force.com/url';
        }
        glossary.put('##billingDocumentCommunityURL##', billingDocumentsCommunityURL);
        Integer annualSubmeterCloseDay = (Integer) portalSystemSetting.annual_submeter_disabled_day__c;
        Integer annualSubmeterCloseMonth = (Integer) portalSystemSetting.annual_submeter_disabled_month__c;
        Integer monthlySubmeterCloseDay = (Integer) portalSystemSetting.monthly_submeter_disabled_day__c;
        glossary.put('##monthlySubmeterDeadline##', Date.newInstance(today.year(), today.month(), monthlySubmeterCloseDay - 1).format());
        glossary.put('##annualSubmeterDeadline##', Date.newInstance(today.year(), annualSubmeterCloseMonth, annualSubmeterCloseDay - 1).format());
        glossary.put('##lastMonthDate##', Date.newInstance(today.addMonths(-1).year(), today.addMonths(-1).month(), 10).format().substring(3));
        glossary.put('##lastYearDate##', '' + (today.year() - 1));

        /**
        * In this section the messages are constructed on a per user basis.
        */
        for (String userId : userMap.keySet()) {

            /**
            *  1. The personal context glossary is being constructed
            */
            glossary.remove('##attachementType##');
            glossary.remove('##meterName##');

            User tmpUser = userMap.get(userId);

            if (objectType == 'Contract__c' || objectType == 'Meter__c') {
                List<String> contractNames = new List<String>(contactIdToListOfContractNames.get(tmpUser.Contact.Id));

                glossary.put('##contractNames##', String.join(contractNames, ', '));

                String contractMeterContractHolderTuple = '';
                String contractMeterTuple = '';
                String concatenatedMeterName = '';
                Set<Id> metersAlreadyNotifiedAbout = new Set<Id>();
                for (MeterRegistration__c usersMeterRegistration : contactIdToListOfMeterRegs.get(tmpUser.ContactId)) {

                    if (usersMeterRegistration != null && !metersAlreadyNotifiedAbout.contains(usersMeterRegistration.Meter__c)) {
                        metersAlreadyNotifiedAbout.add(usersMeterRegistration.Meter__c);
                        contractMeterContractHolderTuple += usersMeterRegistration.Contract__r.Name.substringBeforeLast('/') + ' (';
                        contractMeterContractHolderTuple += usersMeterRegistration.Meter__r.Name + ' - ';
                        concatenatedMeterName += usersMeterRegistration.Meter__r.Name + ' , ';
                        contractMeterContractHolderTuple += usersMeterRegistration.Contract__r.Contract_Holder__r.Name + '), ';
                        contractMeterTuple += usersMeterRegistration.Contract__r.Name.substringBeforeLast('/') + ' - ';
                        contractMeterTuple += usersMeterRegistration.Meter__r.Name + ', ';

                        // Each Task can have a different user/meter. meterId to userId relationship necessary.
                        meterIdToUserIdForTasksWrapper meterCasesObject = new meterIdToUserIdForTasksWrapper();
                        meterCasesObject.meterId = usersMeterRegistration.Meter__r.Id;
                        meterCasesObject.userId = tmpUser.Id;
                        userIdToMeterIdList.add(meterCasesObject);
                    }
                }

                glossary.put('##contractMeterContractHolderTuple##', contractMeterContractHolderTuple.removeEnd(', '));
                glossary.put('##contractMeterTuple##', contractMeterTuple.removeEnd(', '));
                glossary.put('##meterName##', concatenatedMeterName.removeEnd(', ')); // Merge-Field of a notification. e.g. Email->Subject, contains the meter-names.

                if (objectType == 'Contract__c') {
                    if (entityIdToContentVersions != null && contactIdToListOfContractIds.get(tmpUser.Contact.Id) != null) {
                        Set<String> attachmentTypes = new Set<String>();
                        for (Id contractIdItem : contactIdToListOfContractIds.get(tmpUser.Contact.Id)) {
                            if (entityIdToContentVersions.containsKey(contractIdItem)) {
                                for (ContentVersion versionItem : entityIdToContentVersions.get(contractIdItem)) {
                                    attachmentTypes.add(versionItem.Attachement_Type__c);
                                }
                            }
                        }
                        List<String> attachmentTypesList = new List<String>();
                        if (attachmentTypeTranslations.containsKey(tmpUser.LanguageLocaleKey.left(2))) {
                            attachmentTypesList = msChatterUtility.translateAttachmentTypes(attachmentTypes, attachmentTypeTranslations.get(tmpUser.LanguageLocaleKey.left(2)));
                        } else {
                            attachmentTypesList = new List<String>(attachmentTypes);
                        }
                        glossary.put('##attachementType##', String.join(attachmentTypesList, ', '));
                    }
                }
            }

            /**
            *  2.   All messages are being formatted for the media channels, respective to the user language.
            *       Defaults to English, if the default fails the message is discarded.
            *
            *       For Email and SMS, a subscription to the respective message type is required, Portal Messages are
            *       always issued and can not be unsubscribed.
            */
            List<msUserNotificationSetting__c> settings = contactIdToNotificationSettingsMap.get(tmpUser.ContactId);

            if (settings != null) {
                for (msUserNotificationSetting__c setting : settings) {
                    userListToLogIntoLoggerConsole.add(tmpUser); // We want to log every user who will get an mail.
                    if (setting.msIsEmail__c) {
                        notificationWrapper newObject = formatEmail(tmpUser, translations, messageType, glossary);
                        if (newObject != null && newObject.userId != null) {
                            newObject.meterId = null;
                            messagesEmail.add(newObject);
                        }
                    }
                    if (setting.msIsSMS__c) {
                        notificationWrapper newObject = formatSMS(tmpUser, translations, messageType, glossary);
                        if (newObject != null) {
                            if (newObject.messageType == debugMode.messageType) {
                                newObject.userId = debugMode.userTargetId;
                            }
                            if (newObject.userId != null) {
                                messagesSMS.add(newObject);
                            }
                        }
                    }
                }

            }
            notificationWrapper newObject = formatPortalMessage(tmpUser, translations, messageType, glossary);
            if (newObject != null && newObject.userId != null) {
                messagesInPortal.add(newObject);
            }
        }

        logAllUsersInLoggerConsole(recordIds, userListToLogIntoLoggerConsole, messageType);

        // Create Cases/Tasks only for live-metering-reminder issues
        if ((objectType == 'Meter__c' && messageTypeForLiveMeter == 'live_metering_missing_reminder') ||
                (objectType == 'Meter__c' && messageTypeForLiveMeter == 'live_metering_exceeds_capacity_reminder') ||
                (objectType == 'Meter__c' && messageTypeForLiveMeter == 'live_metering_constant_values_reminder')
                ) {

            casesForLifeMeteringIssues = createLiveMetringCases(messagesInPortal, userIdToMeterIdList,
                    contractualContactsForEachMeter, messageTypeForLiveMeter);
            if (!casesForLifeMeteringIssues.isEmpty()) {
                insert casesForLifeMeteringIssues;
                taskForLifeMeteringIssueCaseList = createLiveMetringTasks(casesForLifeMeteringIssues, userIdToMeterIdList);
                if (!taskForLifeMeteringIssueCaseList.isEmpty()) {
                    insert taskForLifeMeteringIssueCaseList;
                }
            }
        } // END: Create Cases/Tasks for Life-Metering-Issues

        /**
        *  3. The Notifications are being send out, according to their channel
        */
        if (messagesInPortal.size() > 0) {
            sendInPortalMessages(messagesInPortal, debugMode);
        }
        System.debug('emails: ' + messagesEmail);
        if (messagesEmail.size() > 0) {
            sendEmailMessages(messagesEmail, debugMode);
        }
        if (messagesSMS.size() > 0) {
            msSMSControllerBatch batch = new msSMSControllerBatch(JSON.serialize(messagesSMS));
            Database.executeBatch(batch);
        }
        return messagesInPortal.size();
    }
    /**
     *  @return Map ContractId to their respective List of Portal Notification Subscriptions
     *
     *  @param messageType message Type of the Subscriptions to retrieve
     *  @param contactIds Set if Contact Ids for which retrieve the Settings
     *
     * @describe    This method loads the Notification Settings for all relevant Users
     */
    public static ListMapContainer getNotificationSettings(String messageType, Set<Id> contactIds) {
        ListMapContainer result = new ListMapContainer(msUserNotificationSetting__c.SObjectType);

        List<msUserNotificationSetting__c> userNotificationSettings = [
                SELECT msContact__c, msIsEmail__c, msNotificationType__c, msIsSMS__c, msFileFormat__c
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = :messageType
                AND msContact__c IN :contactIds
        ];
        for (msUserNotificationSetting__c tmpSetting : userNotificationSettings) {
            result.addToMap(tmpSetting.msContact__c, tmpSetting);
        }
        return result;
    }


    public static List<Case> createLiveMetringCases(
            List<notificationWrapper> messagesInPortal,
            List<meterIdToUserIdForTasksWrapper> userIdToMeterIdList,
            List<contractualContactsWrapper> contractualContactsForEachMeter,
            String messageTypeForLiveMeter) {
        List<Case> casesForLifeMeteringIssues = new List<Case>();

        // UPDATE meterIdToUserIdForTasksWrapper: Add Email(body+Subject)
        for (notificationWrapper notification : messagesInPortal) {
            for (meterIdToUserIdForTasksWrapper userIdToMeterId : userIdToMeterIdList) {
                if (userIdToMeterId.userId == notification.userId) {
                    userIdToMeterId.emailText = notification.body;
                    userIdToMeterId.emailSubject = notification.subject;
                }
            }
        }

        // Create Case for each Meter.
        for (contractualContactsWrapper meterContractInfos : contractualContactsForEachMeter) {
            Case casePerMeter = new Case();
            casePerMeter.RecordTypeId = CASE_STANDARD_RECORD_TYPE; // = Standard
            casePerMeter.RecordTypeId = CASE_STANDARD_RECORD_TYPE;
            casePerMeter.Contract__c = meterContractInfos.contractId;
            casePerMeter.OwnerId = CASE_OWNER_ID; // = QUEUE - "Sales Coordinators EEG"
            casePerMeter.Case_Creator__c = CASE_CREATOR; // = System
            casePerMeter.ContactId = meterContractInfos.contractualContactId;
            casePerMeter.Origin = 'Internal';
            casePerMeter.Reason = 'Live Metering Data Issue';
            casePerMeter.Subject = 'Follow Up - Live Metering Data Issue';
            casePerMeter.Description = messageTypeForLiveMeter;
            casePerMeter.Type = 'Problem';
            casePerMeter.Meter__c = meterContractInfos.meterId;
            casesForLifeMeteringIssues.add(casePerMeter);

            meterContractInfos.caseId = casePerMeter.Id;
        }
        return casesForLifeMeteringIssues;
    }

    public static List<Task> createLiveMetringTasks(List<Case> casesForLifeMeteringIssues, List<meterIdToUserIdForTasksWrapper> userIdToMeterIdList) {
        List<Task> taskForLifeMeteringIssueCaseList = new List<Task>();
        // Create Tasks for each Case.
        for (Case currentCase : casesForLifeMeteringIssues) { // Iterate over Cases
            for (meterIdToUserIdForTasksWrapper userIdToMeterId : userIdToMeterIdList) { // Iterate over Tasks, and add caseId to Task.
                if (userIdToMeterId.meterId == currentCase.Meter__c) {
                    userIdToMeterId.caseId = currentCase.Id;

                    // Each Case can have several Tasks with its translated text.
                    Task taskForLifeMeteringIssue = new Task(
                            Subject = userIdToMeterId.emailSubject,
                            OwnerId = TASK_OWNER_ID,        // System
                            TaskSubtype = 'Email',
                            ActivityDate = Date.today(),
                            Description = userIdToMeterId.emailText,
                            Type = 'Email',
                            WhatId = currentCase.Id          // Case.Id
                    );
                    taskForLifeMeteringIssueCaseList.add(taskForLifeMeteringIssue);
                }
            }
        }
        return taskForLifeMeteringIssueCaseList;
    }

    /**
     * @return Map Id to User of the eligible recipients for the message context
     *
     * @param objectType SobjectType of the Context
     * @param recordIds records of the Context, need to be all of SObjectType objectType
     * @param messageType message Type of the Context
     *
     * @description -   Helper method that grabs the recipients (Users) that are eligible for a notification independent
     *                  of market or subscription restrictions
     */
    public static Map<Id, User> receiveRecipients(String objectType, List<String> recordIds, String messageType) {
        Map<Id, User> userMap;
        switch on objectType {
            when null {
                List<Id> contactIdList = new List<Id>();
                for (msUserNotificationSetting__c subscriptionItem : [SELECT msContact__c FROM msUserNotificationSetting__c WHERE msNotificationType__c = :messageType]) {
                    contactIdList.add(subscriptionItem.msContact__c);
                }
                return receiveRecipients('Contact', contactIdList, null);
            }
            when 'Meter__c' {
                userMap = new Map<Id, User>([
                        SELECT Id, LanguageLocaleKey, FirstName, LastName, ContactId, Contact.Salutation, Contact.MobilePhone, Contact.Email
                        FROM User
                        WHERE ContactId IN (
                                SELECT Contact__c
                                FROM Site_Role__c
                                WHERE Meter__c IN :recordIds
                                AND Role__c INCLUDES ('Customer Portal')
                                AND Start_Date__c <= :Date.today()
                                AND (End_Date__c >= :Date.today()
                                OR End_Date__c = NULL)
                        )
                ]);
            }
            when 'Contract__c' {
                userMap = new Map<Id, User>([
                        SELECT Id, LanguageLocaleKey, FirstName, LastName,ContactId, Contact.Salutation, MobilePhone
                        FROM User
                        WHERE ContactId IN (
                                SELECT Contact__c
                                FROM Contract_Role__c
                                WHERE Contract__c IN :recordIds
                                AND Role__c INCLUDES ('Customer Portal')
                                AND Start_Date__c <= :Date.today()
                                AND (End_Date__c >= :Date.today()
                                OR End_Date__c = NULL)
                        )
                ]);
            }
            when 'User' {
                userMap = new Map<Id, User>([
                        SELECT Id, LanguageLocaleKey, FirstName, LastName,ContactId, Contact.Salutation, MobilePhone
                        FROM User
                        WHERE Id IN :recordIds
                ]);
            }
            when 'Contact' {
                userMap = new Map<Id, User>([
                        SELECT Id, LanguageLocaleKey, FirstName, LastName,ContactId, Contact.Salutation, MobilePhone
                        FROM User
                        WHERE ContactId IN :recordIds
                ]);
            }
        }
        return userMap;
    }

    /**
     * @return wrapped Notifications that resemble the email template based tests
     *
     * @param tmpUser Target User (Customer) to personalize the message to
     * @param translations All Translations of the relevant text templates
     * @param messageType message Type of the Context
     * @param glossary Context based text translations from placeholder to Customer based Context
     *
     * @description -   Helper method that pre formats a notification to an Email for the respective user(language)
     */
    public static notificationWrapper formatEmail(User tmpUser, translationIndexingWrapper translations, String messageType, Map<String, String> glossary) {
        notificationWrapper newObject = new notificationWrapper();
        String userLanguage = tmpUser.LanguageLocaleKey.left(2);
        if (translations.languages.containsKey('en') && !translations.languages.containsKey(userLanguage)) {
            userLanguage = 'en';
        } else if (!translations.languages.containsKey(userLanguage)) {
            return null;
        }
        translationWrapper localizedMessageDetails = translations.languages.get(userLanguage);
        newObject = msChatterUtility.messageSetupHelper(tmpUser, messageType, 'en', localizedMessageDetails);
        newObject.subject = localizedMessageDetails.subjectEmail;
        newObject.body += localizedMessageDetails.bodyEmail;
        for (String placeholder : glossary.keySet()) {
            newObject.subject = newObject.subject.replaceAll(placeholder, glossary.get(placeholder));
            if (newObject.subject.length() > 90) {
                newObject.subject = newObject.subject.left(90) + '...';
            }
            newObject.body = newObject.body.replaceAll(placeholder, glossary.get(placeholder));
        }
        return newObject;
    }

    /**
     * @return wrapped Notifications that resemble the sms template based tests
     *
     * @param tmpUser Target User (Customer) to personalize the message to
     * @param translations All Translations of the relevant text templates
     * @param messageType message Type of the Context
     * @param glossary Context based text translations from placeholder to Customer based Context
     * @description -   Helper method that pre formats a notification to a SMS for the respective user(language)
     */
    public static notificationWrapper formatSMS(User tmpUser, translationIndexingWrapper translations, String messageType, Map<String, String> glossary) {
        notificationWrapper newObject = new notificationWrapper();
        String userLanguage = tmpUser.LanguageLocaleKey.left(2);
        if (translations.languages.containsKey('en') && !translations.languages.containsKey(userLanguage)) {
            userLanguage = 'en';
        } else if (!translations.languages.containsKey(userLanguage)) {
            return null;
        }
        translationWrapper localizedMessageDetails = translations.languages.get(userLanguage);
        newObject = msChatterUtility.messageSetupHelper(tmpUser, messageType, userLanguage, localizedMessageDetails);
        newObject.body = localizedMessageDetails.bodySMS;
        if (newObject.body != null) {
            for (String placeholder : glossary.keySet()) {
                newObject.body = newObject.body.replaceAll(placeholder, glossary.get(placeholder));
            }
        } else {
            return null;
        }

        return newObject;
    }

    /**
     * @return wrapped Notifications that resemble the Chatter template based tests
     *
     * @param tmpUser Target User (Customer) to personalize the message to
     * @param translations All Translations of the relevant text templates
     * @param messageType message Type of the Context
     * @param glossary Context based text translations from placeholder to Customer based Context
     * @description -   Helper method that pre formats a notification to a portal message for the respective user(language)
     */
    public static notificationWrapper formatPortalMessage(User tmpUser, translationIndexingWrapper translations, String messageType, Map<String, String> glossary) {
        notificationWrapper newObject = new notificationWrapper();
        String userLanguage = tmpUser.LanguageLocaleKey.left(2);
        if (translations.languages.containsKey('en') && !translations.languages.containsKey(tmpUser.LanguageLocaleKey.left(2))) {
            userLanguage = 'en';
        } else if (!translations.languages.containsKey(userLanguage)) {
            return null;
        }
        translationWrapper localizedMessageDetails = translations.languages.get(userLanguage);
        newObject = msChatterUtility.messageSetupHelper(tmpUser, messageType, userLanguage, localizedMessageDetails);
        if (localizedMessageDetails.subjectChatter != null && localizedMessageDetails.bodyChatter != null) {
            newObject.subject = localizedMessageDetails.subjectChatter;
            newObject.body += localizedMessageDetails.bodyChatter;
            for (String placeholder : glossary.keySet()) {
                newObject.subject = newObject.subject.replaceAll(placeholder, glossary.get(placeholder));
                if (newObject.subject.length() > 90) {
                    newObject.subject = newObject.subject.left(90) + '...';
                }
                newObject.body = newObject.body.replaceAll(placeholder, glossary.get(placeholder));
            }
        } else {
            newObject = null;
        }
        return newObject;
    }

    /**
     * @description -   Media Channel that sends Notifications via in Portal Message - always fires if the user is
     *                  eligible to the message even if the notification is not subscribed to otherwise(!)
     */
    public static void sendInPortalMessages(List<notificationWrapper> objectList, debugModeWrapper debugMode) {
        Id networkId = [SELECT Id FROM Network WHERE Name = 'Customer Portal' LIMIT 1].Id;
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

        for (notificationWrapper tmp : objectList) {
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.subjectId = tmp.userId;
            ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
            body.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = EncodingUtil.urlEncode(JSON.serialize(tmp), 'UTF-8');
            body.messageSegments.add(textSegment);

            input.body = body;

            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
            if (tmp.messageType != debugMode.messageType) {
                batchInputs.add(batchInput);
            }
        }
        try {
            if (batchInputs.size() > 0) {
                if(batchInputs.size() > 500){ // List<ConnectApi.BatchInput>: The list can contain up to 500 ConnectApi.BatchInput objects!
                    List<List<ConnectApi.BatchInput>> batchInputsChunkList = divideListForBatching(batchInputs);

                    for(Integer i=0; i < batchInputsChunkList.size(); i++){ // Send Chatter messages in 250-chunks
                        ConnectApi.ChatterFeeds.postFeedElementBatch(networkId, batchInputsChunkList[i]);
                    }
                }
                else { // We have less then 500 messages to sent.
                    ConnectApi.ChatterFeeds.postFeedElementBatch(networkId, batchInputs);
                }
            }
        } catch (Exception e) {
            Logger.error('Warning, could not send messages to Chatter Feeds. Error:'  + e.getMessage());
            Logger.saveLog('Notification Framework: Chatter-Error');
        }
    }
    /**
     * @description -   Media Channel that sends Notifications via Email
     */
    public static void sendEmailMessages(List<notificationWrapper> objectList, debugModeWrapper debugMode) {
        OrgWideEmailAddress owa = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply-salesforce@statkraft.com'];
        List<Messaging.SingleEmailMessage> resultMailsSenderOrgWide = new List<Messaging.SingleEmailMessage>();
        EmailTemplate template = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = 'Community_Notifications' LIMIT 1];
        Messaging.SingleEmailMessage emailTemplate = Messaging.renderStoredEmailTemplate(template.Id, null, null);

        if (objectList.size() > 0) {
            if (objectList[0].messageType == 'monthly_production_data') {
                Database.executeBatch(new msBatchProductionMails(objectList, debugMode), 1);
            } else {
                for (notificationWrapper messageWrapper : objectList) {
                    if (messageWrapper.messageType == debugMode.messageType) {
                        messageWrapper.userId = debugMode.userTargetId;
                    }
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    String body = emailTemplate.getHtmlBody();

                    body = body.replaceAll('##BODY##', messageWrapper.body);
                    email.setHtmlBody(body);
                    OrgWideEmailAddress senderAddress = owa;
                    email.setSubject(messageWrapper.subject);
                    email.setOrgWideEmailAddressId(senderAddress.Id);
                    email.saveAsActivity = false;
                    if (messageWrapper.userId != null) {
                        email.setTargetObjectId(messageWrapper.userId);
                        resultMailsSenderOrgWide.add(email);
                    }
                }

                if (resultMailsSenderOrgWide.size() > 1000) {
                    throw new NotificationFrameworkException(Label.NotificationFrameworkEmailOverloadErrorMessage);
                } else {
                    List<Messaging.SingleEmailMessage> messageBatch = new List<Messaging.SingleEmailMessage>();
                    for (Integer i = 0; i < resultMailsSenderOrgWide.size(); i++) {
                        messageBatch.add(resultMailsSenderOrgWide[i]);
                        Integer residue = Math.mod(i + 1, 100);
                        if (residue == 0) {
                            System.Messaging.sendEmail(messageBatch);
                            messageBatch = new List<Messaging.SingleEmailMessage>();
                        } else if (i == resultMailsSenderOrgWide.size() - 1) {
                            System.Messaging.sendEmail(messageBatch);
                        }
                    }
                }
            }
        }
    }


    public static void registerEmailNotification(String messageType, Set<Id> contactsIds) {
        ListMapContainer notificationSettingsByContactIds = msNotificationLogic.getNotificationSettings(messageType, contactsIds);
        List<msUserNotificationSetting__c> settingsToUpdate = new List<msUserNotificationSetting__c>();
        for (Id contactId : contactsIds) {
            if (notificationSettingsByContactIds.get(contactId) == null) {
                settingsToUpdate.add(new msUserNotificationSetting__c(msIsEmail__c = true, msNotificationType__c = messageType, msContact__c = contactId));
            }
        }
        upsert settingsToUpdate;
    }

    public static List<Messaging.SendEmailResult> sendTemplatedEmailToAddressesForRecords(OrgWideEmailAddress orgAddress, Map<Id, SObject> recipientsByRecordIds, String templateName) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemplate = getEmailTemplateByName(templateName);
        for (String recordId : recipientsByRecordIds.keySet()) {
            messages.add(createSingleEmailMessageWithTemplateId(orgAddress, recipientsByRecordIds.get(recordId), emailTemplate.Id));
        }
        return System.Messaging.sendEmail(messages);
    }

    public static Messaging.SingleEmailMessage createSingleEmailMessageWithTemplateId(Id recipientId, Id relatedRecord, Id templateId) {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setTargetObjectId(recipientId);
        emailMessage.setWhatId(relatedRecord);
        emailMessage.setTemplateId(templateId);
        emailMessage.setTreatTargetObjectAsRecipient(true);
        emailMessage.setBccSender(false);
        emailMessage.setUseSignature(false);
        emailMessage.setSaveAsActivity(false);
        return emailMessage;
    }

    public static Messaging.SingleEmailMessage createSingleEmailMessageWithTemplateId(OrgWideEmailAddress orgAddress, SObject relatedRecord, Id templateId) {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setTargetObjectId(Id.valueOf(String.valueOf(relatedRecord.get('OwnerId'))));
        emailMessage.setWhatId(Id.valueOf(String.valueOf(relatedRecord.get('Id'))));
        if (relatedRecord.getSObject('CreatedBy') != null) {
            emailMessage.setReplyTo(String.valueOf(relatedRecord.getSObject('CreatedBy').get('Email')));
        }
        if (orgAddress != null) {
            emailMessage.setOrgWideEmailAddressId(orgAddress.Id);
        } else if (relatedRecord.getSObject('CreatedBy') != null) {
            emailMessage.setSenderDisplayName(String.valueOf(relatedRecord.getSObject('CreatedBy').get('Name')));
        }
        emailMessage.setTemplateId(templateId);
        emailMessage.setTreatTargetObjectAsRecipient(true);
        emailMessage.setBccSender(false);
        emailMessage.setUseSignature(false);
        emailMessage.setSaveAsActivity(false);
        return emailMessage;
    }

    public static EmailTemplate getEmailTemplateByName(String templateName) {
        try {
            EmailTemplate emailTemplate = [
                    SELECT Id, Name
                    FROM EmailTemplate
                    WHERE DeveloperName = :templateName
                    LIMIT 1
            ];
            return emailTemplate;
        } catch (QueryException e) {
            Logger.error('SOQL Error for EmailTemplate object:'  + e.getStackTraceString());
            Logger.saveLog('Notification Framework: EmailTemplate-Error');
        }
        return null;
    }

    /**
     * @return  List of Contractual Contact based on the Meter Context
     *
     * @param meterIds List of Meter Ids that shall be searched for Contractual Contacts
     *
     * @description -   Helper method that grabs the Contractual Contact´s.
     *                  Necessary for the Task.ContactName.
     */
    public static List<contractualContactsWrapper> receiveContractualContacts(List<Id> meterIds) {

        List<contractualContactsWrapper> contractualContactsList = new List<contractualContactsWrapper>();

        // 1. Get all contractsId´s and meterID´s
        List<MeterRegistration__c> allContractsGivenMeter = new List<MeterRegistration__c>();
        allContractsGivenMeter = [
                SELECT Contract__c, Meter__c
                FROM MeterRegistration__c
                WHERE Meter__c IN :meterIds
                AND Active__c = TRUE
        ];

        // 1.1 Fill wrapper-class with meterID/contractID info
        for (MeterRegistration__c meterRegistration : allContractsGivenMeter) {
            contractualContactsWrapper contractualContacts = new contractualContactsWrapper();
            contractualContacts.meterId = meterRegistration.Meter__c;
            contractualContacts.contractId = meterRegistration.Contract__c;
            contractualContactsList.add(contractualContacts);
        }

        Set<Id> relevantContractIds = new Set<Id>();
        for (contractualContactsWrapper relevantContract : contractualContactsList) {
            relevantContractIds.add(relevantContract.contractId);
        }

        // 2. Get all ContractualContacts
        List<Contract_Role__c> allRelevantContractualContacts = new List<Contract_Role__c>();
        allRelevantContractualContacts = [
                SELECT Contact__r.Id, Role__c, Contract__r.Id
                FROM Contract_Role__c
                WHERE Contract__c IN :relevantContractIds
                AND Contract__r.Status__c = 'Active'
                AND Role__c = 'Contractual contact'
        ];

        // 2.1 Add contractualContact to our wrapper(contractualContactsWrapper)
        // At this point our wrapper has all infos, e.g.:
        //      "meterId" : "a135E000000ez98QAA",
        //      "contractualContactId" : "0031v00002rQSGtAAO",
        //      "contractId" : "a0K1v00000OyAGbEAN"
        for (Contract_Role__c contractualContact : allRelevantContractualContacts) {
            for (contractualContactsWrapper meterRegistration : contractualContactsList) {
                if (contractualContact.Contract__r.Id == meterRegistration.contractId) {
                    meterRegistration.contractualContactId = contractualContact.Contact__r.Id;
                }
            }
        }
        return contractualContactsList;
    }

    /**
     * @description -   In order to check if a user(contact) has received an email from Statkraft
     *                  we are logging all relevant users with the NebulaLogger - framework.
     *                  Look for the "Logger Console"-App in Salesforce.
     */
    public static void logAllUsersInLoggerConsole(List<Id> recordIds, List<User> userList, String messageType) {
        Logger.info('Preparing to send notifications of type: ' + messageType);
        Logger.info('Sent emails to these contracts: ' + JSON.serializePretty(recordIds));

        String userWhichGotAnEmail;
        for(User u : userList){
            userWhichGotAnEmail += u.FirstName + ', ' + u.LastName + ', Contact Id: ' + u.ContactId + ', User Id: ' + u.Id + ' --- ';
        }
        Logger.info('Sent email to this user: ' + userWhichGotAnEmail);
        Logger.saveLog('Notification Framework: ' + messageType);
    }

    /**
     * @description -   Due to a limit of max 5 elements which can be passed to the chatter-API
     *                  we need to split the list into chunks of 250.
     *                  Check limits for: ConnectApi.ChatterFeeds.postFeedElementBatch
     * @return      -   A list of lists(max 5 objects each list)
     */
    public static List<List<ConnectApi.BatchInput>> divideListForBatching(List<ConnectApi.BatchInput> batchInputs) {
        List<List<ConnectApi.BatchInput>> listContainer = new List<List<ConnectApi.BatchInput>>();
        Integer batchSize = 250;
        Integer listCounter = 0;
        listContainer.add(new List<ConnectApi.BatchInput>());

        for (Integer x = 0; x < batchInputs.size(); x++) {
            if (x != 0 && Math.mod(x, batchSize) == 0) {
                listCounter++;
                listContainer.add(new List<ConnectApi.BatchInput>());
            }
            listContainer[listCounter].add(batchInputs[x]);
        }

        return listContainer;
    }

    /**
     * @description -   Wrapper class that contains all message details for the completely constructed
     *                  message as it is handed over to the different media channels
     */
    global class notificationWrapper {
        public Id userId { get; set; }
        public String subject { get; set; }
        public String body { get; set; }
        public String messageType { get; set; }
        public User user { get; set; }
        public Contact contact { get; set; }
        public Id meterId { get; set; }

        //constructor
        public notificationWrapper() {
            //default all values
            this.userId = null;
            this.subject = '';
            this.body = '';
            this.messageType = '';
            this.meterId = null;
        }
    }
    /**
     * @description -   Wrapper class contains all details for one message type in one language as stored in the
     *                  custom meta data
     */
    global class translationWrapper {
        public String subjectEmail { get; set; }
        public String bodyEmail { get; set; }
        public String subjectChatter { get; set; }
        public String bodyChatter { get; set; }
        public String bodySMS { get; set; }
        public String salutationDefault { get; set; }
        public String salutationMr { get; set; }
        public String salutationMrs { get; set; }
        public String salutationMs { get; set; }
        public String salutationDr { get; set; }
        public String salutationProf { get; set; }
        public translationWrapper() {
            subjectEmail = '';
            bodyEmail = '';
            subjectChatter = '';
            bodyChatter = '';
            bodySMS = '';
            salutationDefault = '';
            salutationDr = '';
            salutationMr = '';
            salutationMrs = '';
            salutationMs = '';
            salutationProf = '';
        }
    }
    /**
     * @description -   Wrapper class that matches the entire details for a message types and maps them by language
     */
    public class translationIndexingWrapper {
        public Map<String, translationWrapper> languages { get; set; }
        public translationIndexingWrapper() {
            languages = new Map<String, translationWrapper>();
        }
    }
    /**
     * @description -   Wrapper class that matches the message types to their respective collection of translations
     */
    public class messageTypesTranslations {
        public Map<String, translationIndexingWrapper> messageTypes { get; set; }
        public messageTypesTranslations() {
            messageTypes = new Map<String, translationIndexingWrapper>();
        }
    }
    /**
     * @description  - Wrapper for an active debug mode
     */
    global class debugModeWrapper {
        public String messageType { get; set; }
        public Id userTargetId { get; set; }
        public debugModeWrapper() {
            messageType = '';
            userTargetId = null;
        }
    }

    /**
     * @description -   Wrapper class that holds all cases, tasks etc. which needs to be created
     *                  if a reminder-notification(live-metering-issues) was sent to a customer.
     */
    global class meterIdToUserIdForTasksWrapper {
        public Id meterId { get; set; }
        public Id userId { get; set; }
        public Id contractId { get; set; }
        public Id contractualContactId { get; set; }
        public String emailText { get; set; }
        public String emailSubject { get; set; }
        public Id caseId { get; set; }

        public meterIdToUserIdForTasksWrapper() {
            meterId = null;
            userId = null;
            contractId = null;
            contractualContactId = null;
            emailText = null;
            emailSubject = null;
            caseId = null;
        }
    }

    /**
     * @description -   Wrapper class that maps meterId´s to contractualContacts.
     *                  Used by meterCasesWrapper-class.
     */
    global class contractualContactsWrapper {
        public Id meterId { get; set; }
        public Id contractId { get; set; }
        public Id contractualContactId { get; set; }
        public Id caseId { get; set; }

        public contractualContactsWrapper() {
            meterId = null;
            contractId = null;
            contractualContactId = null;
            caseId = null;
        }
    }

    public class NotificationFrameworkException extends Exception {
    }
}