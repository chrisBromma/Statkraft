@isTest
public with sharing class FlowMapCreateTest {
    @isTest static void testMapCreationWithDefinedField(){
        List<FlowMapCreate.Input> inputList = new List<FlowMapCreate.Input>();
        
        List<Account> accsToMap = new List<Account>();
        accsToMap.add(new Account(Name = 'Test'));
        accsToMap.add(new Account(Name = 'Test2'));

        FlowMapCreate.Input input = new FlowMapCreate.Input();
        input.records = accsToMap;
        input.mappingField = 'Name';
        inputList.add(input);
        
        List<FlowMapCreate.Output> output = FlowMapCreate.createMap(inputList);
        
        System.assertEquals(2, output[0].flowMap.size(), 'List of Flow Elements was supposed to be 2');
        System.assertEquals('Test', output[0].flowMap[0].key, 'Name should have been mapped to the key');
    }
}