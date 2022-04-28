@isTest
public with sharing class FlowListEmptyCheckTest {
    @isTest static void testListEmptyCheck(){
        List<Account> emptyAccountList = new List<Account>();
        List<Account> filledAccountList = new List<Account>{new Account(Name = 'Test')};

        List<FlowListEmptyCheck.Input> inputs = new List<FlowListEmptyCheck.Input>();
        FlowListEmptyCheck.Input input1 = new FlowListEmptyCheck.Input();
        input1.listToCheck = emptyAccountList;
        inputs.add(input1);
        FlowListEmptyCheck.Input input2 = new FlowListEmptyCheck.Input();
        input2.listToCheck = filledAccountList;
        inputs.add(input2);

        List<Boolean> result = FlowListEmptyCheck.checkIfListIsEmpty(inputs);
        System.assert(result[0]);
        System.assert(!result[1]);
    }
}