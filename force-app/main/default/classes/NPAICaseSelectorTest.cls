@isTest
private class NPAICaseSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        NPAICaseSelector NPAICaseSelector = (NPAICaseSelector) Application.Selector.newInstance(NPC_Cases__c.SObjectType);
        System.assertEquals('NPC_Cases__c', String.valueOf(NPAICaseSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        NPAICaseSelector NPAICaseSelector = (NPAICaseSelector) Application.Selector.newInstance(NPC_Cases__c.SObjectType);
        System.assertEquals(5, NPAICaseSelector.getSObjectFieldList().size());
    }
}