@isTest
private class ContentDocumentLinkSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        ContentDocumentLinkSelector cdlSelector = (ContentDocumentLinkSelector) Application.Selector.newInstance(ContentDocumentLink.SObjectType);
        System.assertEquals('ContentDocumentLink', String.valueOf(cdlSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        ContentDocumentLinkSelector cdlSelector = (ContentDocumentLinkSelector) Application.Selector.newInstance(ContentDocumentLink.SObjectType);
        System.assertEquals(4, cdlSelector.getSObjectFieldList().size());
    }
}