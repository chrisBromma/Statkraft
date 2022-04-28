@isTest
public with sharing class FlowMapGetValuesTest {
    @isTest static void testGetValues(){
        List<FlowMapGetValues.Input> inputs = new List<FlowMapGetValues.Input>();
        FlowMapGetValues.Input input = new FlowMapGetValues.Input();
        input.flowMap = FlowTestFactory.getMappedAccounts();
        inputs.add(input);

        List<FlowMapGetValues.Output> output = FlowMapGetValues.getValues(inputs);
        System.assertEquals(2, output[0].records.size(), 'The size of the Values returned should be 2');
        System.assertEquals('Account', output[0].records[0].getSObjectType().getDescribe().getName(), 'The values of the Map should be of Type Account');

    }
}