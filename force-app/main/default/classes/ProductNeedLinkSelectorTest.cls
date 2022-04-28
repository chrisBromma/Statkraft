@isTest
private class ProductNeedLinkSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        ProductNeedLinkSelector ProductNeedLinkSelector = (ProductNeedLinkSelector) Application.Selector.newInstance(Product_Need_Link__c.SObjectType);
        System.assertEquals('Product_Need_Link__c', String.valueOf(ProductNeedLinkSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        ProductNeedLinkSelector ProductNeedLinkSelector = (ProductNeedLinkSelector) Application.Selector.newInstance(Product_Need_Link__c.SObjectType);
        System.assertEquals(6, ProductNeedLinkSelector.getSObjectFieldList().size());
    }
}