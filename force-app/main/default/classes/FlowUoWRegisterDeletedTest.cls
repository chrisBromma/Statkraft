@isTest
public with sharing class FlowUoWRegisterDeletedTest {
    public static final String INSTANCE_NAME = 'TestClass';
    public static final String ACC_NAME = 'TestAcc';

    @isTest
    public static void testFlowUoWRegisterDeleted() {
        Account accToDelete = new Account(Name = ACC_NAME);
        insert accToDelete;

        FlowUoWRegisterDeleted.Input inputParameter = new FlowUoWRegisterDeleted.Input();
        inputParameter.instanceName = INSTANCE_NAME;
        inputParameter.record = (SObject) accToDelete;
        List<FlowUoWRegisterDeleted.Input> inputParameterList = new List<FlowUoWRegisterDeleted.Input>{
            inputParameter
        };
        FlowUoWRegisterDeleted.registerDelete(inputParameterList);

        FlowUoWCommit.Input inputParameterCommit = new FlowUoWCommit.Input();
        inputParameterCommit.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterListCommit = new List<FlowUoWCommit.Input>{ inputParameterCommit };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterListCommit);
        Test.stopTest();

        List<Account> existingAccounts = [SELECT Id FROM Account];
        System.assert(existingAccounts.isEmpty(), 'There should not be any existing Accounts.');
    }
}