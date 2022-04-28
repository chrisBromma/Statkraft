@isTest
private class NPAIContainerSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        NPAIContainerSelector NPAIContainerSelector = (NPAIContainerSelector) Application.Selector.newInstance(NPAI_Container__c.SObjectType);
        System.assertEquals('NPAI_Container__c', String.valueOf(NPAIContainerSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        NPAIContainerSelector NPAIContainerSelector = (NPAIContainerSelector) Application.Selector.newInstance(NPAI_Container__c.SObjectType);
        System.assertEquals(3, NPAIContainerSelector.getSObjectFieldList().size());
    }
}