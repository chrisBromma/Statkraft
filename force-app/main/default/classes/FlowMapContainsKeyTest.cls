@isTest
public with sharing class FlowMapContainsKeyTest {
    @isTest static void testPositive(){
        List<FlowMapContainsKey.Input> inputs = new List<FlowMapContainsKey.Input>();
        FlowMapContainsKey.Input input = new FlowMapContainsKey.Input();
        input.flowMap = FlowTestFactory.getMappedAccounts();
        input.key = 'Test';
        inputs.add(input);

        System.assert(FlowMapContainsKey.containsKey(inputs)[0], 'The result should be positive');
    }

    @isTest static void testNegative(){
        List<FlowMapContainsKey.Input> inputs = new List<FlowMapContainsKey.Input>();
        FlowMapContainsKey.Input input = new FlowMapContainsKey.Input();
        input.flowMap = FlowTestFactory.getMappedAccounts();
        input.key = 'Blah';
        inputs.add(input);

        System.assert(!FlowMapContainsKey.containsKey(inputs)[0], 'The result should be negative');
    }
}