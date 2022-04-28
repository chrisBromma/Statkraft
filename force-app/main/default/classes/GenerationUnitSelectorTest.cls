@isTest
private class GenerationUnitSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        GenerationUnitSelector generationUnitSelector = (GenerationUnitSelector) Application.Selector.newInstance(Generation_Unit__c.SObjectType);
        System.assertEquals('Generation_Unit__c', String.valueOf(generationUnitSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        GenerationUnitSelector generationUnitSelector = (GenerationUnitSelector) Application.Selector.newInstance(Generation_Unit__c.SObjectType);
        System.assertEquals(5, generationUnitSelector.getSObjectFieldList().size());
    }
}