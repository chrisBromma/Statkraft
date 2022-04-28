@isTest
private class UserNotificationSettingsSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        UserNotificationSettingsSelector UserNotificationSettingsSelector = (UserNotificationSettingsSelector) Application.Selector.newInstance(msUserNotificationSetting__c.SObjectType);
        System.assertEquals('msUserNotificationSetting__c', String.valueOf(UserNotificationSettingsSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        UserNotificationSettingsSelector UserNotificationSettingsSelector = (UserNotificationSettingsSelector) Application.Selector.newInstance(msUserNotificationSetting__c.SObjectType);
        System.assertEquals(5, UserNotificationSettingsSelector.getSObjectFieldList().size());
    }
}