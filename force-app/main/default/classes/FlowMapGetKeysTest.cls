@isTest
public with sharing class FlowMapGetKeysTest {
    @isTest static void testGetKeys(){
        List<FlowMapGetKeys.Input> inputs = new List<FlowMapGetKeys.Input>();
        FlowMapGetKeys.Input input = new FlowMapGetKeys.Input();
        input.flowMap = FlowTestFactory.getMappedAccounts();
        inputs.add(input);

        FlowMapGetKeys.Output[] output = FlowMapGetKeys.getkeys(inputs);
        System.assertEquals(2, output[0].keySet.size(), 'List of keys should be 2');
        System.assertEquals('Test', output[0].keySet[0], 'First key should be Test');

    }
}