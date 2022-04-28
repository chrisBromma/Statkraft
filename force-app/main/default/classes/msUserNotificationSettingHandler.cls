/****************************************************************************************************
* Class msUserNotificationSettingHandler
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

public without sharing class msUserNotificationSettingHandler extends TriggerHandlerExtension {
    //Helper contains all the logic
    msUserNotificationSettingHelper Helper;

    public msUserNotificationSettingHandler() {
        super();
        Helper = new msUserNotificationSettingHelper(
                (List<msUserNotificationSetting__c>) Trigger.old,
                (List<msUserNotificationSetting__c>) Trigger.new,
                (Map<Id, msUserNotificationSetting__c>) Trigger.oldMap,
                (Map<Id, msUserNotificationSetting__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(Trigger.new, false);
        }
    }

    public override void bulkAfter() {
        if (Trigger.isInsert || Trigger.isUpdate|| Trigger.isUndelete) {
            Helper.identifyUserNotificationSettingIds();
        }
        Helper.loadUserNotificationSettings();
        Helper.buildDuplicationCheckDataModel();
    }

    public override void afterInsert(SObject newSObj) {
        msUserNotificationSetting__c newSetting = (msUserNotificationSetting__c) newSObj;
        Helper.addErrorIfDuplicateInDatabase(newSetting);
    }

    public override void afterUpdate(SObject oldSObj, SObject newSObj) {
        msUserNotificationSetting__c newSetting = (msUserNotificationSetting__c) newSObj;
        Helper.addErrorIfDuplicateInDatabase(newSetting);
    }

    public override void afterUndelete(SObject newSObj) {
        msUserNotificationSetting__c newSetting = (msUserNotificationSetting__c) newSObj;
        Helper.addErrorIfDuplicateInDatabase(newSetting);
    }
}