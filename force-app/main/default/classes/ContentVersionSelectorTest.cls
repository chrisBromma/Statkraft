@isTest
private class ContentVersionSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        ContentVersionSelector cvSelector =  (ContentVersionSelector) Application.Selector.newInstance(ContentVersion.SObjectType);
        System.assertEquals('ContentVersion', String.valueOf(cvSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        ContentVersionSelector cvSelector = (ContentVersionSelector) Application.Selector.newInstance(ContentVersion.SObjectType);
        System.assertEquals(7, cvSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testWithVersionData() {
        ContentVersionSelector cvSelector = (ContentVersionSelector) Application.Selector.newInstance(ContentVersion.SObjectType);
        cvSelector.WithVersionData();
        System.assertEquals(8, cvSelector.getSObjectFieldList().size());
    }
}