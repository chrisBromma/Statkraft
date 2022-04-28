@isTest
private class MeterRegistrationSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        MeterRegistrationSelector meterRegistrationSelector = (MeterRegistrationSelector) Application.Selector.newInstance(MeterRegistration__c.SObjectType);
        System.assertEquals('MeterRegistration__c', String.valueOf(meterRegistrationSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        MeterRegistrationSelector meterRegistrationSelector = (MeterRegistrationSelector) Application.Selector.newInstance(MeterRegistration__c.SObjectType);
        System.assertEquals(10, meterRegistrationSelector.getSObjectFieldList().size());
    }
}