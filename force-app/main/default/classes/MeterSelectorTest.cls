@isTest
private class MeterSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        MeterSelector meterSelector = (MeterSelector) Application.Selector.newInstance(Meter__c.SObjectType);
        System.assertEquals('Meter__c', String.valueOf(meterSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        MeterSelector meterSelector = (MeterSelector) Application.Selector.newInstance(Meter__c.SObjectType);
        System.assertEquals(10, meterSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testnewQueryFactory2() {
        MeterSelector meterSelector = (MeterSelector) Application.Selector.newInstance(Meter__c.SObjectType);
        fflib_QueryFactory test = meterSelector.newQueryFactory2();
        String queryString = 'SELECT Country__c, CurrencyIsoCode, Description__c, Id, Installed_Capacity__c, Name, Parent_Meter__c, Portfolio_ID__c, RecordType.Name, RecordTypeId, Site_Location_Postcode__c, Succeeding_Clone__c FROM Meter__c ORDER BY Name ASC NULLS FIRST ';
        System.assertEquals(queryString, test.toSOQL());
    }

    @isTest
    private static void testnewQueryFactoryWithSubmeters() {
        MeterSelector meterSelector = (MeterSelector) Application.Selector.newInstance(Meter__c.SObjectType);
        fflib_QueryFactory test = meterSelector.newQueryFactoryWithSubmeters();
        String queryString = 'SELECT Country__c, CurrencyIsoCode, Description__c, Id, Installed_Capacity__c, Name, Parent_Meter__c, Portfolio_ID__c, RecordType.Name, RecordTypeId, Site_Location_Postcode__c, Succeeding_Clone__c, (SELECT Country__c, CurrencyIsoCode, Description__c, Id, Installed_Capacity__c, Name, Parent_Meter__c, Portfolio_ID__c, RecordTypeId, Site_Location_Postcode__c, Succeeding_Clone__c FROM Meters__r ORDER BY Name ASC NULLS FIRST )  FROM Meter__c ORDER BY Name ASC NULLS FIRST ';
        System.assertEquals(queryString, test.toSOQL());
    }
}