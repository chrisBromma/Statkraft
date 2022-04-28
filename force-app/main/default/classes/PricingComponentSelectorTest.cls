@isTest
private class PricingComponentSelectorTest {

    private static final Id contractRecId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE;
    private static final Id pricingComponentId = msTestDataFactory.FLOATING_ENERGY_PRICING_COMPONENT_REC_TYPE_ID;

    @TestSetup static void setup() {
        List<Contract__c> contracts = msGranularTestDataFactory.createTestContracts(1, contractRecId, 'United Kingdom', 'Flex', 'Merchant PPA', 'Flex Optimization GB', 'UKTestContract1', 'RPI');
        insert contracts;

        List<Pricing_Component__c> pricingComponents = msGranularTestDataFactory.createTestPricingComponents(1,'Test Component', pricingComponentId,'Sub-Meter Monthly');
        insert msGranularTestDataFactory.linkPricingComponentsToContract(contracts[0].Id,pricingComponents);
    }

    @isTest
    private static void testGetSobjectType() {
        PricingComponentSelector PricingComponentSelector = (PricingComponentSelector) Application.Selector.newInstance(Pricing_Component__c.SObjectType);
        System.assertEquals('Pricing_Component__c', String.valueOf(PricingComponentSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        PricingComponentSelector PricingComponentSelector = (PricingComponentSelector) Application.Selector.newInstance(Pricing_Component__c.SObjectType);
        System.assertEquals(24, PricingComponentSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testSelectByContractId() {
        Contract__c testContract = [SELECT Id, Name FROM Contract__c];
        PricingComponentSelector PricingComponentSelector = (PricingComponentSelector) Application.Selector.newInstance(Pricing_Component__c.SObjectType);
        System.assertEquals('Test Component', PricingComponentSelector.selectByContractId(testContract.Id)[0].Name);
    }
}