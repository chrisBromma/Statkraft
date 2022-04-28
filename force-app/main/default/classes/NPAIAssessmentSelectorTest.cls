@isTest
private class NPAIAssessmentSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        NPAIAssessmentSelector NPAIAssessmentSelector = (NPAIAssessmentSelector) Application.Selector.newInstance(NPC_Assessment__c.SObjectType);
        System.assertEquals('NPC_Assessment__c', String.valueOf(NPAIAssessmentSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        NPAIAssessmentSelector NPAIAssessmentSelector = (NPAIAssessmentSelector) Application.Selector.newInstance(NPC_Assessment__c.SObjectType);
        System.assertEquals(2, NPAIAssessmentSelector.getSObjectFieldList().size());
    }
}