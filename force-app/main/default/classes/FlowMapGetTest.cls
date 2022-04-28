@isTest
public with sharing class FlowMapGetTest {

    @isTest static void testGetValueByKey(){
        List<FlowMapGet.Input> inputs = new List<FlowMapGet.Input>();
        FlowMapGet.Input input = new FlowMapGet.Input();
        input.flowMap = FlowTestFactory.getMappedAccounts();
        input.key = 'Test';
        inputs.add(input);

        List<FlowMapGet.Output> output = FlowMapGet.getValue(inputs);
        System.assertEquals('Test', (String) output[0].outputValue.get('Name'), 'The Account retreieved should have the Name Test');
    }
}