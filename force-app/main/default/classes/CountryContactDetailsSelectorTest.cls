@isTest
private class CountryContactDetailsSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        CountryContactDetailsSelector ccdSelector = (CountryContactDetailsSelector) Application.Selector.newInstance(CountryContactDetails__c.SObjectType);
        System.assertEquals('CountryContactDetails__c', String.valueOf(ccdSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        CountryContactDetailsSelector ccdSelector = (CountryContactDetailsSelector) Application.Selector.newInstance(CountryContactDetails__c.SObjectType);
        System.assertEquals(2, ccdSelector.getSObjectFieldList().size());
    }
}