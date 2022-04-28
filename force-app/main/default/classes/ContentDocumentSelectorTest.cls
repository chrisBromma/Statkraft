@isTest
private class ContentDocumentSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        ContentDocumentSelector cdSelector = (ContentDocumentSelector) Application.Selector.newInstance(ContentDocument.SObjectType);
        System.assertEquals('ContentDocument', String.valueOf(cdSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        ContentDocumentSelector cdSelector =  (ContentDocumentSelector) Application.Selector.newInstance(ContentDocument.SObjectType);
        System.assertEquals(2, cdSelector.getSObjectFieldList().size());
    }
}