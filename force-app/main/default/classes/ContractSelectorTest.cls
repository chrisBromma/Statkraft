@isTest
private class ContractSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        ContractSelector contractSelector = (ContractSelector) Application.Selector.newInstance(Contract__c.SObjectType);
        System.assertEquals('Contract__c', String.valueOf(contractSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        ContractSelector contractSelector = (ContractSelector) Application.Selector.newInstance(Contract__c.SObjectType);
        System.assertEquals(16, contractSelector.getSObjectFieldList().size());
    }
}