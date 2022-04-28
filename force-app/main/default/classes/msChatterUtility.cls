/****************************************************************************************************
* Class msChatterUtility
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   26.09.2018
*   Description	:	This class provides translations for all notification texts and text elements and serves as a
*                   helper class for all formatting and language specific issues regarding notification messages
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)        26.09.2018      	Init version.
*   * Christian Gottlieb (mindsquare GmbH)      04.07.2019          Class now stores translation logic for notifications
*****************************************************************************************************/

public with sharing class msChatterUtility {

    /**
     * @description - This method handles the translations for messages as they are generated in msNotificationLogic
     */
    public static msNotificationLogic.messageTypesTranslations getMessageTranslations(String messageType, String languageKey, String subject, String body) {

        msNotificationLogic.translationWrapper translationWrapper = new msNotificationLogic.translationWrapper();
        msNotificationLogic.translationIndexingWrapper translationLanguages = new msNotificationLogic.translationIndexingWrapper();
        msNotificationLogic.messageTypesTranslations messages = new msNotificationLogic.messageTypesTranslations();
        List<msNotificationDetails__mdt> allNotificationDetails = getNotificationDetails();
        switch on messageType {
            when 'new_invoice_by_trigger' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.New_Invoice_Trigger_Subject_Chatter__c;
                    translationWrapper.bodyChatter = detailsItem.New_Invoice_Trigger_Body_Chatter__c;
                    translationWrapper.subjectEmail = detailsItem.New_Invoice_Trigger_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.New_Invoice_Trigger_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.New_Invoice_Trigger_Body_SMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('new_invoice',translationLanguages);
            }
            //currently not in use
            when 'updated_invoice_by_trigger' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.Updated_Invoice_Trigger_Subject_Chatter__c;
                    translationWrapper.bodyChatter = detailsItem.Updated_Invoice_Trigger_Body_Chatter__c;
                    translationWrapper.subjectEmail = detailsItem.Updated_Invoice_Trigger_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.Updated_Invoice_Trigger_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.Updated_Invoice_Trigger_Body_SMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('new_invoice',translationLanguages);
            }
            when 'downreg_notification' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.DownregNotification_Subject_Chatter__c;
                    translationWrapper.bodyChatter = detailsItem.DownregNotification_Body_Chatter__c;
                    translationWrapper.subjectEmail = detailsItem.DownregNotification_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.DownregNotification_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = null;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('downreg_notification',translationLanguages);
            }
            when 'monthly_submeter_enabled' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.MonthlySubmeterEnabled_Subject_Chatter__c;
                    translationWrapper.bodyChatter = detailsItem.MonthlySubmeterEnabled_Body_Chatter__c;
                    translationWrapper.subjectEmail = detailsItem.MonthlySubmeterEnabled_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.MonthlySubmeterEnabled_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.MonthlySubmeterEnabled_Body_SMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('submeter_enabled',translationLanguages);
            }
            when 'annual_submeter_enabled' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.YearlySubmeterEnabled_Subject_Chatter__c;
                    translationWrapper.bodyChatter = detailsItem.YearlySubmeterEnabled_Subject_Email__c;
                    translationWrapper.subjectEmail = detailsItem.YearlySubmeterEnabled_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.YearlySubmeterEnabled_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.YearlySubmeterEnabled_Body_SMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('submeter_enabled',translationLanguages);
            }
            when 'monthly_submeter_reminder' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.MonthlySubmeterReminder_Subject_Chatter__c;
                    translationWrapper.bodyChatter = detailsItem.MonthlySubmeterReminder_Body_Chatter__c;
                    translationWrapper.subjectEmail = detailsItem.MonthlySubmeterReminder_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.MonthlySubmeterReminder_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.MonthlySubmeterReminder_Body_SMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('submeter_enabled',translationLanguages);
            }

            when 'annual_submeter_reminder' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.YearlySubmeterReminder_Subject_Chatter__c;
                    translationWrapper.bodyChatter = detailsItem.YearlySubmeterReminder_Subject_Email__c;
                    translationWrapper.subjectEmail = detailsItem.YearlySubmeterReminder_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.YearlySubmeterReminder_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.YearlySubmeterReminder_Body_SMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('submeter_enabled',translationLanguages);
            }
            when 'monthly_production_data' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = null;
                    translationWrapper.bodyChatter = null;
                    translationWrapper.subjectEmail = detailsItem.Monthly_Production_Data_Subject_Email__c;
                    translationWrapper.bodyEmail = detailsItem.Monthly_Production_Data_Body_Email__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = null;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('monthly_production_data',translationLanguages);
            }

            /* Live-Metering notification granular types:
            *     Description                   Type-Name(for REST calls)
            *     ______________________________________________________________________
            *   - Missing                       live_metering_missing
            *   - Missing Reminder              live_metering_missing_reminder
            *   - Exceeds Capacity              live_metering_exceeds_capacity
            *   - Exceeds Capacity Reminder     live_metering_exceeds_capacity_reminder
            *   - Constant Values               live_metering_constant_values
            *   - Constant Values Reminder      live_metering_constant_values_reminder
            *
            *   The broader category for the above types is called: live_metering_notification
            * */
            when 'live_metering_missing' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.LiveMeterMissingSubjectChatter__c;
                    translationWrapper.bodyChatter = detailsItem.LiveMeterMissingBodyChatter__c;
                    translationWrapper.subjectEmail = detailsItem.LiveMeterMissingSubjectEmail__c;
                    translationWrapper.bodyEmail = detailsItem.LiveMeterMissingBodyEmail__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.LiveMeterMissingBodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('live_metering_notification',translationLanguages);
            }
            when 'live_metering_missing_reminder' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.LiveMeterMissingRemindSubjectChatter__c;
                    translationWrapper.bodyChatter = detailsItem.LiveMeterMissingRemindBodyChatter__c;
                    translationWrapper.subjectEmail = detailsItem.LiveMeterMissingRemindSubjectEmail__c;
                    translationWrapper.bodyEmail = detailsItem.LiveMeterMissingRemindBodyEmail__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.LiveMeterMissingRemindBodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('live_metering_notification',translationLanguages);
            }
            when 'live_metering_exceeds_capacity' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.LiveMeterExceedsCapacitySubjectChatter__c;
                    translationWrapper.bodyChatter = detailsItem.LiveMeterExceedsCapacityBodyChatter__c;
                    translationWrapper.subjectEmail = detailsItem.LiveMeterExceedsCapacitySubjectEmail__c;
                    translationWrapper.bodyEmail = detailsItem.LiveMeterExceedsCapacityBodyEmail__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.LiveMeterExceedsCapacityBodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('live_metering_notification',translationLanguages);
            }
            when 'live_metering_exceeds_capacity_reminder' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.LiveMeterExceedsCapacityRemindSubjChatt__c;
                    translationWrapper.bodyChatter = detailsItem.LiveMeterExceedsCapacityReminderBodyChat__c;
                    translationWrapper.subjectEmail = detailsItem.LiveMeterExceedsCapacityRemindSubjEmail__c;
                    translationWrapper.bodyEmail = detailsItem.LiveMeterExceedsCapacityReminderBodyEmai__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.LiveMeterExceedsCapacityReminderBodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('live_metering_notification',translationLanguages);
            }
            when 'live_metering_constant_values' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.LiveMeterConstValuesSubjectChatter__c;
                    translationWrapper.bodyChatter = detailsItem.LiveMeterConstValuesBodyChatter__c;
                    translationWrapper.subjectEmail = detailsItem.LiveMeterConstValuesSubjectEmail__c;
                    translationWrapper.bodyEmail = detailsItem.LiveMeterConstValuesBodyEmail__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.LiveMeterConstValuesBodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('live_metering_notification',translationLanguages);
            }
            when 'live_metering_constant_values_reminder' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.LiveMeterConstValuesReminderSubChatter__c;
                    translationWrapper.bodyChatter = detailsItem.LiveMeterConstValuesReminderBodyChatter__c;
                    translationWrapper.subjectEmail = detailsItem.LiveMeterConstValuesRemindSubjectEmail__c;
                    translationWrapper.bodyEmail = detailsItem.LiveMeterConstValuesReminderBodyEmail__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.LiveMeterConstValuesReminderBodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('live_metering_notification',translationLanguages);
            }

            when 'masterdata_confirmation' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.MasterdataConfirmation_SubjChatter__c;
                    translationWrapper.bodyChatter = detailsItem.MasterdataConfirmation_BodyChatter__c;
                    translationWrapper.subjectEmail = detailsItem.MasterdataConfirmation_SubjEmail__c;
                    translationWrapper.bodyEmail = detailsItem.MasterdataConfirmation_BodyEmail__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.MasterdataConfirmation_BodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('masterdata_confirmation',translationLanguages);
            }

            when 'masterdata_confirmation_reminder' {
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    translationWrapper = new msNotificationLogic.translationWrapper();
                    translationWrapper = mapSalutations(translationWrapper,detailsItem);
                    translationWrapper.subjectChatter = detailsItem.MasterdataConfirmationRemind_SubjChatter__c;
                    translationWrapper.bodyChatter = detailsItem.MasterdataConfirmationRemind_BodyChatter__c;
                    translationWrapper.subjectEmail = detailsItem.MasterdataConfirmationRemind_SubjEmail__c;
                    translationWrapper.bodyEmail = detailsItem.MasterdataConfirmationRemind_BodyEmail__c + detailsItem.AutogenerationNoticeHTML__c;
                    translationWrapper.bodySMS = detailsItem.MasterdataConfirmationRemind_BodySMS__c;
                    translationLanguages.languages.put(detailsItem.DeveloperName,translationWrapper);
                }
                messages.messageTypes.put('masterdata_confirmation_reminder',translationLanguages);
            }

            //If the message is not of a special internal logic, default to a direct message
            when else {
                Map<String,msNotificationDetails__mdt> detailsMap = new Map<String, msNotificationDetails__mdt>();
                for(msNotificationDetails__mdt detailsItem : allNotificationDetails) {
                    detailsMap.put(detailsItem.DeveloperName, detailsItem);
                }
                msNotificationDetails__mdt appropriateTranslation = null;
                if(detailsMap.containsKey(languageKey.left(2))) {
                    appropriateTranslation = detailsMap.get(languageKey.left(2));
                } else {
                    appropriateTranslation = detailsMap.get('en');
                }
                translationWrapper = mapSalutations(translationWrapper, appropriateTranslation);
                translationWrapper.subjectChatter = subject;
                translationWrapper.bodyChatter = body;
                translationWrapper.subjectEmail = subject;
                translationWrapper.bodyEmail = body + appropriateTranslation.AutogenerationNoticeHTML__c;
                translationWrapper.bodySMS = subject;
                translationLanguages.languages.put(languageKey.left(2), translationWrapper);
                messages.messageTypes.put(messageType, translationLanguages);
            }
        }
        return messages;
    }
    /**
     * @description - This method handles the translations for Attachment Types, since the Meta Data API is inaccessible
     */
    public static Map<String,Map<String,String>> getAttachmentTypeTranslations() {

        Map<String,Map<String,String>> translatedAttachmentTypes = new Map<String, Map<String, String>>();
        translatedAttachmentTypes.put('de', new Map<String,String>());
        translatedAttachmentTypes.put('fr', new Map<String,String>());
        List<Attachmenttypes__c> translations = [
                SELECT  msPicklist_Value_API_Name__c,
                        msFrenchPortalNotificationLabel__c,
                        msGermanPortalNotificationLabel__c
                FROM Attachmenttypes__c
                WHERE msIsSendNotifications__c = TRUE
                AND msIsShowInPortal__c = TRUE
                AND Related_Object__c = 'Contract__c'
        ];
        for(Attachmenttypes__c typeItem: translations) {
            translatedAttachmentTypes.get('de').put(typeItem.msPicklist_Value_API_Name__c, typeItem.msGermanPortalNotificationLabel__c);
            translatedAttachmentTypes.get('fr').put(typeItem.msPicklist_Value_API_Name__c, typeItem.msFrenchPortalNotificationLabel__c);
        }
        return translatedAttachmentTypes;
    }
    /**
     * @description - Helper Method that Translates a Set of Attachment Types into their corresponding translated List
     */
    public static List<String> translateAttachmentTypes(Set<String> originalAttachmentTypes, Map<String,String> valuePairs) {
        List<String> translatedAttachmentTypes = new List<String>();
        for(String typeItem : originalAttachmentTypes) {
            if(valuePairs.containsKey(typeItem)) {
                String translation = valuePairs.get(typeItem);
                if(translation == null) {
                    translatedAttachmentTypes.add(typeItem);
                } else {
                    translatedAttachmentTypes.add(valuePairs.get(typeItem));
                }
            } else {
                translatedAttachmentTypes.add(typeItem);
            }
        }
        return translatedAttachmentTypes;
    }
    /**
    * @description - Helper method to assign salutations to a translation wrapper
    */
    private static msNotificationLogic.translationWrapper mapSalutations(
            msNotificationLogic.translationWrapper wrapperToFill,
            msNotificationDetails__mdt sourceTranslation) {
        wrapperToFill.salutationDefault = sourceTranslation.Salutation_Default__c;
        wrapperToFill.salutationDr = sourceTranslation.Salutation_Dr__c;
        wrapperToFill.salutationMr = sourceTranslation.Salutation_Mr__c;
        wrapperToFill.salutationMrs = sourceTranslation.Salutation_Mrs__c;
        wrapperToFill.salutationMs = sourceTranslation.Salutation_Ms__c;
        wrapperToFill.salutationProf = sourceTranslation.Salutation_Prof__c;
        return wrapperToFill;
    }
    /**
     * @description -   This method initiates a notification wrapper and handles the styling of salutations for the
     *                  body of a message
     */
    public static msNotificationLogic.notificationWrapper messageSetupHelper(User tmpUser, String messageType,
            String languageKey, msNotificationLogic.translationWrapper localized) {
        msNotificationLogic.notificationWrapper newObject = new msNotificationLogic.notificationWrapper();
        String salutation = '';

        newObject.userId = tmpUser.Id;
        newObject.messageType = messageType;
        newObject.user = tmpUser;
        newObject.contact = tmpUser.Contact;
        switch on tmpUser.Contact.Salutation {
            when 'Mr.' {
                salutation = localized.salutationMr;
            }
            when 'Mrs.' {
                salutation = localized.salutationMrs;
            }
            when 'Ms.' {
                salutation = localized.salutationMs;
            }
            when 'Dr.' {
                salutation = localized.salutationDr;
            }
            when 'Prof.' {
                salutation = localized.salutationProf;
            }
            when else {
                salutation = localized.salutationDefault;
            }
        }
        if (languageKey == 'fr') {
            salutation += ', <br/> <br/>';
        } else {
            salutation += ' ' + tmpUser.LastName + ', <br/> <br/>';
        }
        newObject.body = salutation;
        return newObject;
    }

    /**
     * @description loads the applicable debug mode settings for this notification type
     */
    public static msNotificationLogic.debugModeWrapper getDebugMode(String messageType) {
        msPortalSystemSetting__mdt currentPortalSystemSettings =msUtility.getPortalSettings();

        msNotificationLogic.debugModeWrapper debugMode = new msNotificationLogic.debugModeWrapper();
        switch on messageType {
            when 'submeter_enabled' {
                if(currentPortalSystemSettings.debug_submeter_enabled__c) {
                    debugMode.messageType = messageType;
                    debugMode.userTargetId = currentPortalSystemSettings.submeter_enabled_user__c;
                }
            }
            when 'new_invoice' {
                if(currentPortalSystemSettings.debug_new_invoice__c) {
                    debugMode.messageType = messageType;
                    debugMode.userTargetId = currentPortalSystemSettings.new_invoice_user__c;
                }
            }
            when 'downreg_notification' {
                if(currentPortalSystemSettings.debug_downreg_notification__c) {
                    debugMode.messageType = messageType;
                    debugMode.userTargetId = currentPortalSystemSettings.downreg_notification_user__c;
                }
            }
            when 'monthly_production_data' {
                if(currentPortalSystemSettings.debug_monthly_production_data__c) {
                    debugMode.messageType = messageType;
                    debugMode.userTargetId = currentPortalSystemSettings.monthly_production_data_user__c;
                }
            }
            when else {
                System.debug('Warning, unknown Message type for debug status check: ' + messageType);
            }
        }
        if(debugMode.userTargetId != null) {
            try {
                User testUser = [SELECT Id FROM User WHERE Id =: debugMode.userTargetId AND IsActive = TRUE];
            } catch (QueryException e) { //User could not be found
                debugMode.userTargetId = null;
            } catch (Exception e) { //Something bad happened
                debugMode.userTargetId = null;
                System.debug('Warning, unexpected Exception: ' + e.getMessage());
            }
        }
        return debugMode;
    }
    public static List<msNotificationDetails__mdt> getNotificationDetails() {
        Map<String, Schema.SObjectField> fieldMap = msNotificationDetails__mdt.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNames = new List<String>(fieldMap.keySet());
        return Database.query('SELECT ' + String.join(fieldNames, ',') + ' FROM msNotificationDetails__mdt');
    }
}