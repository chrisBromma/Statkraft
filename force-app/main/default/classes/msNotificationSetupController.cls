/****************************************************************************************************
* Class msNotificationSetupController
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	Controller for the msNotificationSetup Component.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019      	Init version.
*   * Christian Gottlieb (mindsquare GmbH)		22.08.2019      	V2 with media availability activation
*****************************************************************************************************/

public without sharing class msNotificationSetupController {
    /**
     * @return A List of Picklist Entries from the Global Value Set Notification Types
     *
    * @description - This method returns the Picklist Values of the Global Value List msNotificationTypes
    */
    private static List<PicklistEntry> getNotificationOptions() {
        Schema.DescribeFieldResult F = msUserNotificationSetting__c.msNotificationType__c.getDescribe();
        Schema.SObjectField T = F.getSobjectField();
        return T.getDescribe().getPicklistValues();
    }
    /**
     * @return The Portal Notification Subscriptions that are listed for the current User
     *
    * @description - This method returns all msUserNotificationSetting Records for the active User from the database
    */
    private static List<msUserNotificationSetting__c> getNotificationSettings() {
        List<msUserNotificationSetting__c> allSettings = [
                SELECT Id, msNotificationType__c, msIsEmail__c, msIsSMS__c, msFileFormat__c
                FROM msUserNotificationSetting__c
                WHERE msContact__c IN (SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())
        ];
        return allSettings;
    }
    /**
     * @return The eligible Portal Notification Subscriptions for the current User
     *
    * @description - This method loads all known User Settings for Notifications and prepares a list with known and
    * possible Settings for the User. Essential are the Global Value List msNotificationTypes and Custom Metadata
    * msPortalMarketNotificationOption. Note that it is paramount for the Global Value List to contain all labels of the
    * Checkbox Values from the Metadata and vice versa. The method will adapt dynamically to all changes to those lists.
    */
    @AuraEnabled
    public static List<option> getOptions() {

        List<PicklistEntry> entriesList = getNotificationOptions();
        Set<String> allUserMarkets = msUtility.getUserMarkets();
        Map<String, Map<String, Boolean>> validUserOptions = getValidUserOptions(allUserMarkets);
        List<msUserNotificationSetting__c> settingList = getNotificationSettings();
        List<option> optionList = new List<option>();
        option optionItem = new option();
        for (PicklistEntry entryItem : entriesList) {
            if (validUserOptions.containsKey(entryItem.value)) {
                optionItem = new option();
                optionItem.APIName = entryItem.value;
                optionItem.localLabel = entryItem.label;
                optionItem.isEmailEnabled = validUserOptions.get(entryItem.value).get('email');
                optionItem.isSmsEnabled = validUserOptions.get(entryItem.value).get('sms');
                for (msUserNotificationSetting__c settingItem : settingList) {
                    if (settingItem.msNotificationType__c == entryItem.value) {
                        optionItem.settingId = settingItem.Id;
                        optionItem.isEmail = settingItem.msIsEmail__c;
                        optionItem.isSms = settingItem.msIsSMS__c;
                        optionItem.fileFormat = settingItem.msFileFormat__c;
                    }
                }
                optionList.add(optionItem);
            }
        }
        return optionList;
    }
    /**
     *
     * @param optionList Portal Subscriptions that should be saved in the database
     *
     * @return Always true if the operation was successful. TODO: Refactor - This can be void and handled with state SUCCESS in the Front End
     *
    * @description - This method saves the options sent from the Frontend which are checked in new or already existing
    * Records.
    */
    @AuraEnabled
    public static Boolean saveOptions(List<option> optionList) {
        List<msUserNotificationSetting__c> settingList = getNotificationSettings();
        List<msUserNotificationSetting__c> settingsToUpsertList = new List<msUserNotificationSetting__c>();
        msUserNotificationSetting__c newSetting = new msUserNotificationSetting__c();
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        for (option optionItem : optionList) {
            if (optionItem.settingId != '') {
                for (msUserNotificationSetting__c settingItem : settingList) {
                    if (settingItem.Id == optionItem.settingId) {
                        settingItem.msIsSMS__c = optionItem.isSms;
                        settingItem.msIsEmail__c = optionItem.isEmail;
                        settingItem.msFileFormat__c = optionItem.fileFormat;
                        settingsToUpsertList.add(settingItem);
                    }
                }
            } else {
                if (optionItem.isEmail || optionItem.isSms) {
                    newSetting = new msUserNotificationSetting__c();
                    newSetting.msNotificationType__c = optionItem.APIName;
                    newSetting.msContact__c = currentUser.ContactId;
                    newSetting.msIsSMS__c = optionItem.isSms;
                    newSetting.msIsEmail__c = optionItem.isEmail;
                    newSetting.msFileFormat__c = String.isBlank(optionItem.fileFormat) ? 'csv' : optionItem.fileFormat;
                    settingsToUpsertList.add(newSetting);
                }
            }
        }
        try {
            upsert(settingsToUpsertList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return true;
    }
    /**
     *
     * @return The eligible general choices for subscription, independent on market.
     *
    * @description - This method returns all Field API Names for the Custom Metadata
    * msPortalMarketNotificationOption that are Checkboxes/Boolean i.e. options that can be selected, limited to the
    * fields, that are actual notification choices, and not the media choices. Media choices are indicated by a suffix of
    * _email or _sms.
    */
    public static List<String> getBooleanFieldsForMarketOptions() {
        Schema.DescribeSObjectResult objectDescribe = msPortalMarketNotificationOption__mdt.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
        List<String> fieldList = new List<String>();
        for (String s : objectFields.keySet()) {
            Schema.DescribeFieldResult lfieldLabel = objectFields.get(s).getDescribe();
            Schema.DisplayType dType = lfieldLabel.getType();
            String fieldType = String.valueOf(dType);
            if (fieldType == 'BOOLEAN'
                    && !lfieldLabel.getLabel().endsWith('_sms')
                    && !lfieldLabel.getLabel().endsWith('_email')
                    && lfieldLabel.getName() != 'IsProtected') {
                fieldList.add(objectFields.get(s).getDescribe().getName());
            }
        }
        return fieldList;
    }
    /**
     *
     * @return All valid Notification Options for that List of Markets defined by the entries in the Custom Metadata
     *
    * @description - The method returns all valid options for that List of Markets defined by the entries in the Custom Metadata
    *                msPortalMarketNotificationOption. Note that the exact field names/labels are asserted dynamically through said
    *                Metadata and the Global Value List msNotificationTypes. Further every entry comes with an enabler for
    *                the respective Media options, these sub-options always are appended by _email and _sms respectively,
    *                such that they can be enabled/disabled for change through the portal, depending on the markets as well.
    *
    *                Example:
    *                Developername: Germany = German EEG market (only Site Roles),
    *                               Germany_Contract = German EEG market (only Contract Roles)
    *                new_invoice = notification option / user can choose to be notified about new/updated contracts for their contracts in this market in general, but only for any active media, see below
    *                new_invoice_email = media option / user can choose to be notified about this item via the respective suffix media, here: Email
    *
    *                Note: Retroactively deactivating these choice options is not invalidating the choice itself, since
    *                the choice itself is saved in respective msUserNotificationOption records.
    */
    public static Map<String, Map<String, Boolean>> getValidUserOptions(Set<String> userMarkets) {

        List<String> booleanFieldNames = getBooleanFieldsForMarketOptions();
        List<String> booleanFieldNameMedia = new List<String>();
        for (String fieldName : booleanFieldNames) {
            booleanFieldNameMedia.add(fieldName.remove('__c') + '_email__c');
            booleanFieldNameMedia.add(fieldName.remove('__c') + '_sms__c');
        }
        booleanFieldNameMedia.addAll(booleanFieldNames);
        String queryString = 'SELECT Id, DeveloperName,' + String.join(booleanFieldNameMedia, ',') + ' FROM msPortalMarketNotificationOption__mdt';
        List<msPortalMarketNotificationOption__mdt> notificationOptions = (List<msPortalMarketNotificationOption__mdt>) Database.query(queryString);
        Map<String, msPortalMarketNotificationOption__mdt> notificationOptionsMap = new Map<String, msPortalMarketNotificationOption__mdt>();
        for (msPortalMarketNotificationOption__mdt marketOptionsItem : notificationOptions) {
            notificationOptionsMap.put(marketOptionsItem.DeveloperName, marketOptionsItem);
        }
        msPortalMarketNotificationOption__mdt result = null;
        for (String marketItem : userMarkets) {
            if (marketItem != null) {
                msPortalMarketNotificationOption__mdt newOption = notificationOptionsMap.get(marketItem);
                if (result == null) {
                    result = newOption;
                } else {
                    for (String fieldItem : booleanFieldNameMedia) {
                        result.put(fieldItem, (Boolean) result.get(fieldItem) || (Boolean) newOption.get(fieldItem));
                    }
                }
            }
        }
        Schema.DescribeSObjectResult objectDescribe = msPortalMarketNotificationOption__mdt.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
        Map<String, Map<String, Boolean>> userOptionsMap = new Map<String, Map<String, Boolean>>();
        for (String fieldItem : booleanFieldNames) {
            if ((Boolean) result.get(fieldItem)) {
                userOptionsMap.put(objectFields.get(fieldItem).getDescribe().getLabel(), new Map<String, Boolean>());
                userOptionsMap.get(objectFields.get(fieldItem).getDescribe().getLabel()).put('email', (Boolean) result.get(fieldItem.remove('__c') + '_email__c'));
                userOptionsMap.get(objectFields.get(fieldItem).getDescribe().getLabel()).put('sms', (Boolean) result.get(fieldItem.remove('__c') + '_sms__c'));
            }
        }
        return userOptionsMap;
    }
    /**
     *
    * @description - Wrapper Class to present the Notification Options in the Frontend.
    */
    public class option {
        @AuraEnabled
        public String APIName { get; set; }
        @AuraEnabled
        public String localLabel { get; set; }
        @AuraEnabled
        public Boolean isEmail { get; set; }
        @AuraEnabled
        public Boolean isSms { get; set; }
        @AuraEnabled
        public Boolean isEmailEnabled { get; set; }
        @AuraEnabled
        public Boolean isSmsEnabled { get; set; }
        @AuraEnabled
        public String settingId { get; set; }
        @AuraEnabled
        public String fileFormat { get; set; }
        public option() {
            APIName = '';
            localLabel = '';
            isEmail = false;
            isSms = false;
            isEmailEnabled = false;
            isSmsEnabled = false;
            settingId = '';
            fileFormat = '';
        }
    }
}