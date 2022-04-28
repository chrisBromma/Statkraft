@isTest
public with sharing class FlowMapPutTest {
    @isTest static void testPutIntoMap_exists(){
        List<FlowMapPut.Input> inputs = new List<FlowMapPut.Input>();
        FlowMapPut.Input input = new FlowMapPut.Input();
        input.flowMap = FlowTestFactory.getMappedAccounts();
        input.record = new Account(Name = 'Test', BillingCountry = 'Germany');
        inputs.add(input);

        List<FlowMapPut.Output> output = FlowMapPut.putInMap(inputs);
        System.assertEquals(2, output[0].flowMap.size(), 'Size should not have changed');
        System.assertEquals('Germany', output[0].flowMap[0].record.get('BillingCountry'), 'Account replaced in Map should have BillingCountry set to Germany');
    }

    @isTest static void testPutIntoMap_newKey(){
        List<FlowMapPut.Input> inputs = new List<FlowMapPut.Input>();
        FlowMapPut.Input input = new FlowMapPut.Input();
        input.flowMap = FlowTestFactory.getMappedAccounts();
        input.record = new Account(Name = 'Test3', BillingCountry = 'Germany');
        inputs.add(input);

        List<FlowMapPut.Output> output = FlowMapPut.putInMap(inputs);
        System.assertEquals(3, output[0].flowMap.size(), 'Size should have changed');
        System.assertEquals('Germany', output[0].flowMap[2].record.get('BillingCountry'), 'New Account in Map should have BillingCountry set to Germany');
    }
     
}