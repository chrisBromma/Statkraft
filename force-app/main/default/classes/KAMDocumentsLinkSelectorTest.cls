@isTest
private class KAMDocumentsLinkSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        KAMDocumentsLinkSelector KAMdlSelector = (KAMDocumentsLinkSelector) Application.Selector.newInstance(KAM_Documents_Link__c.SObjectType);
        System.assertEquals('KAM_Documents_Link__c', String.valueOf(KAMdlSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        KAMDocumentsLinkSelector KAMdlSelector = (KAMDocumentsLinkSelector) Application.Selector.newInstance(KAM_Documents_Link__c.SObjectType);
        System.assertEquals(2, KAMdlSelector.getSObjectFieldList().size());
    }
}