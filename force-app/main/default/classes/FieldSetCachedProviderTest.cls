@IsTest
public with sharing class FieldSetCachedProviderTest {
    @IsTest
    static void testFieldSetCachedProvider() {
        Map<String, Schema.FieldSet> OFFER_FIELDSETS_BY_DEVELOPERNAME1 = FieldSetCachedProvider.getBySObjectType(SObjectType.Offer__c);
        Map<String, Schema.FieldSet> OFFER_FIELDSETS_BY_DEVELOPERNAME2 = FieldSetCachedProvider.getBySObjectType(SObjectType.Offer__c);


        System.assertEquals(OFFER_FIELDSETS_BY_DEVELOPERNAME1, OFFER_FIELDSETS_BY_DEVELOPERNAME2);
    }
}