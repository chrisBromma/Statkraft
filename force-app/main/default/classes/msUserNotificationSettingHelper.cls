/****************************************************************************************************
* Class msUserNotificationSettingHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-06-18
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-06-18       	Init version.
*****************************************************************************************************/

public without sharing class msUserNotificationSettingHelper {

    //Trigger Maps/Lists
    private List<msUserNotificationSetting__c> triggerOld;
    private List<msUserNotificationSetting__c> triggerNew;
    private Map<Id, msUserNotificationSetting__c> oldMap;
    private Map<Id, msUserNotificationSetting__c> newMap;

    //SOQL Maps
    private Map<Id, msUserNotificationSetting__c> userNotificationSettingsMap =
            new Map<Id, msUserNotificationSetting__c>();

    //Duplication Check Variables
    private Set<String> dc_setOfNotificationTypes = new Set<String>();
    private Set<String> dc_setOfContactIds = new Set<String>();
    private ListMapContainer dc_contactIdToExistingNotificationTypesMap = new ListMapContainer(msUserNotificationSetting__c.SObjectType);

    public msUserNotificationSettingHelper(
            List<msUserNotificationSetting__c> oldList,
            List<msUserNotificationSetting__c> newList,
            Map<Id, msUserNotificationSetting__c> mapOld,
            Map<Id, msUserNotificationSetting__c> mapNew) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    public void identifyUserNotificationSettingIds() {
        for (msUserNotificationSetting__c settingItem : triggerNew) {
            dc_setOfNotificationTypes.add(settingItem.msNotificationType__c);
            dc_setOfContactIds.add(settingItem.msContact__c);
        }
    }

    public void loadUserNotificationSettings() {
        if (!dc_setOfContactIds.isEmpty() && !dc_setOfNotificationTypes.isEmpty()) {
            userNotificationSettingsMap = new Map<Id, msUserNotificationSetting__c>([
                    SELECT Id, Name, msContact__c, msNotificationType__c
                    FROM msUserNotificationSetting__c
                    WHERE msContact__c IN :dc_setOfContactIds
                    AND msNotificationType__c IN :dc_setOfNotificationTypes
            ]);
        }
    }

    public void buildDuplicationCheckDataModel() {
        for (msUserNotificationSetting__c settingItem : userNotificationSettingsMap.values()) {
            if (dc_setOfContactIds.contains(settingItem.msContact__c)
                    && dc_setOfNotificationTypes.contains(settingItem.msNotificationType__c)) {
                dc_contactIdToExistingNotificationTypesMap.addToMap(settingItem.msContact__c, settingItem);
            }
        }
    }

    public void addErrorIfDuplicateInDatabase(msUserNotificationSetting__c newSetting) {
        if (dc_contactIdToExistingNotificationTypesMap.containsKey(newSetting.msContact__c)) {
            List<msUserNotificationSetting__c> potentialDuplicatesList =
                    (List<msUserNotificationSetting__c>) dc_contactIdToExistingNotificationTypesMap.get(newSetting.msContact__c);
            for(msUserNotificationSetting__c settingToCheckForDuplicate : potentialDuplicatesList) {
                if (settingToCheckForDuplicate.Id != newSetting.Id
                        && settingToCheckForDuplicate.msNotificationType__c == newSetting.msNotificationType__c) {
                    newSetting.addError(Label.validationErrorDuplicateNotificationSubscription);
                }
            }
        }
    }
}