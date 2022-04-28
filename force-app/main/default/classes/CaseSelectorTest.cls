@isTest
private class CaseSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        CaseSelector caseSelector = (CaseSelector) Application.Selector.newInstance(Case.SObjectType);
        System.assertEquals('Case', String.valueOf(caseSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        CaseSelector caseSelector = (CaseSelector) Application.Selector.newInstance(Case.SObjectType);
        System.assertEquals(3, caseSelector.getSObjectFieldList().size());
    }
}