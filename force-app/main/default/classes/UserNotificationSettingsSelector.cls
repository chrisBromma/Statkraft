public inherited sharing class UserNotificationSettingsSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return msUserNotificationSetting__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            msUserNotificationSetting__c.Id,
            msUserNotificationSetting__c.Name,
            msUserNotificationSetting__c.msNotificationType__c,
            msUserNotificationSetting__c.msContact__c,
            msUserNotificationSetting__c.msIsEmail__c
        };
    }
}