@isTest
private class OrgWideEmailAddressSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        OrgWideEmailAddressSelector OrgWideEmailAddressSelector = (OrgWideEmailAddressSelector) Application.Selector.newInstance(OrgWideEmailAddress.SObjectType);
        System.assertEquals('OrgWideEmailAddress', String.valueOf(OrgWideEmailAddressSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        OrgWideEmailAddressSelector OrgWideEmailAddressSelector = (OrgWideEmailAddressSelector) Application.Selector.newInstance(OrgWideEmailAddress.SObjectType);
        System.assertEquals(1, OrgWideEmailAddressSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testSelectByAddress() {
        OrgWideEmailAddress[] addresses = [SELECT Address FROM OrgWideEmailAddress LIMIT 1];
        OrgWideEmailAddressSelector OrgWideEmailAddressSelector = (OrgWideEmailAddressSelector) Application.Selector.newInstance(OrgWideEmailAddress.SObjectType);
        System.assertEquals(addresses[0].Id, OrgWideEmailAddressSelector.selectByAddress(addresses[0].Address).Id);
    }
}