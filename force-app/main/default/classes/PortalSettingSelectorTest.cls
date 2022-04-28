@isTest
private class PortalSettingSelectorTest {
    @testSetup static void setup() {
        insert msGranularTestDataFactory.createTestPortalSettings(1, 'test setting', true);
    }

    @isTest
    private static void testGetSobjectType() {
        PortalSettingSelector PortalSettingSelector = (PortalSettingSelector) Application.Selector.newInstance(PortalSettings__c.SObjectType);
        System.assertEquals('PortalSettings__c', String.valueOf(PortalSettingSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        PortalSettingSelector PortalSettingSelector = (PortalSettingSelector) Application.Selector.newInstance(PortalSettings__c.SObjectType);
        System.assertEquals(4, PortalSettingSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testSelectByName() {
        PortalSettingSelector PortalSettingSelector = new PortalSettingSelector();
        System.assertEquals('test setting', PortalSettingSelector.selectByName('test setting', true)[0].Name);
    }
}