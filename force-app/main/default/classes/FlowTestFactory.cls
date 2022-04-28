@isTest 
public with sharing class FlowTestFactory {
   
    public static List<FlowMapElement> getMappedAccounts(){
        List<Account> accsToMap = new List<Account>();
        accsToMap.add(new Account(Name = 'Test'));
        accsToMap.add(new Account(Name = 'Test2'));

        List<FlowMapCreate.Input> inputList = new List<FlowMapCreate.Input>();
        FlowMapCreate.Input input = new FlowMapCreate.Input();
        input.records = accsToMap;
        input.mappingField = 'Name';
        inputList.add(input);
        
        List<FlowMapCreate.Output> output = FlowMapCreate.createMap(inputList);
        System.debug(output);
        return output[0].flowMap;
    }

    public static List<FlowMapElement> getMappedAccountList(){
        List<Account> accsToMap = new List<Account>();
        accsToMap.add(new Account(Name = 'Test'));
        accsToMap.add(new Account(Name = 'Test'));

        List<FlowListMapCreate.Input> inputList = new List<FlowListMapCreate.Input>();
        FlowListMapCreate.Input input = new FlowListMapCreate.Input();
        input.records = accsToMap;
        input.groupByField = 'Name';
        inputList.add(input);
        
        List<FlowListMapCreate.Output> output = FlowListMapCreate.createMap(inputList);
        System.debug(output);
        return output[0].flowMap;
    }

}