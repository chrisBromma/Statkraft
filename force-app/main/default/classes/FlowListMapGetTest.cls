@IsTest
public with sharing class FlowListMapGetTest {
    @IsTest
    static void testGettingListOfRecords() {
        List<FlowListMapGet.Input> inputs = new List<FlowListMapGet.Input>();
        FlowListMapGet.Input input = new FlowListMapGet.Input();
        input.flowMap = FlowTestFactory.getMappedAccountList();
        input.key = 'Test';
        inputs.add(input);

        FlowListMapGet.Output[] output = FlowListMapGet.getValue(inputs);
        System.assertEquals(2, output[0].outputValue.size(), 'Returned List of Accounts should be 2');
    }

    @IsTest
    static void bulkGettingListOfRecordsTest() {
        List<FlowListMapGet.Input> inputs = new List<FlowListMapGet.Input>();
        Integer bulkTestSize = 200;
        for (Integer i = 0; i < bulkTestSize; i++) {
            FlowListMapGet.Input input = new FlowListMapGet.Input();
            input.flowMap = FlowTestFactory.getMappedAccountList();
            input.key = 'Test';
            inputs.add(input);
        }

        FlowListMapGet.Input input = new FlowListMapGet.Input();
        input.flowMap = null;
        input.key = null;
        inputs.add(input);

        Test.startTest();
        FlowListMapGet.Output[] output = FlowListMapGet.getValue(inputs);
        Test.stopTest();

        System.assertEquals(bulkTestSize + 1,output.size(), 'Output Length needs to be identical to input length');
        for(Integer i = 0; i < bulkTestSize; i++) {
            System.assertEquals(2, output[i].outputValue.size(), 'Returned List of Accounts should be 2');
        }
    }
}