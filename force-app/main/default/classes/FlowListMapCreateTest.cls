@IsTest
public with sharing class FlowListMapCreateTest {
    @IsTest static void testGroupedMapCreation() {
        List<Account> accsToMap = new List<Account>();
        accsToMap.add(new Account(Name = 'Test'));
        accsToMap.add(new Account(Name = 'Test'));

        List<FlowListMapCreate.Input> inputList = new List<FlowListMapCreate.Input>();
        FlowListMapCreate.Input input = new FlowListMapCreate.Input();
        input.records = accsToMap;
        input.groupByField = 'Name';
        inputList.add(input);

        List<FlowListMapCreate.Output> output = FlowListMapCreate.createMap(inputList);

        System.assertEquals(1, output[0].flowMap.size(), 'Map should have a size of 1');
        System.assertEquals(2, output[0].flowMap[0].recordList.size(), 'List of records should be two for mapped Element');

    }

    @IsTest
    static void bulkGroupedMapCreationTest() {
        List<FlowListMapCreate.Input> inputList = new List<FlowListMapCreate.Input>();
        Integer bulkTestSize = 200;

        for (Integer i = 0; i < bulkTestSize; i++) {
            List<Account> accsToMap = new List<Account>();
            accsToMap.add(new Account(Name = 'Test'));
            accsToMap.add(new Account(Name = 'Test'));

            FlowListMapCreate.Input input = new FlowListMapCreate.Input();
            input.records = accsToMap;
            input.groupByField = 'Name';
            inputList.add(input);
        }
        FlowListMapCreate.Input input = new FlowListMapCreate.Input();
        input.records = null;
        input.groupByField = null;
        inputList.add(input);

        Test.startTest();
        List<FlowListMapCreate.Output> output = FlowListMapCreate.createMap(inputList);
        Test.stopTest();

        System.assertEquals(bulkTestSize + 1, output.size(), 'Output Length needs to be identical to input length');
        for(Integer i; i < bulkTestSize; i++) {
            System.assertEquals(1, output[i].flowMap.size(), 'Map should have a size of 1');
            System.assertEquals(2, output[i].flowMap[0].recordList.size(), 'List of records should be two for mapped Element');
        }
    }
}