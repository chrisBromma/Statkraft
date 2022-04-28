@IsTest
public with sharing class FlowUoWResetTest {
    public static final String INSTANCE_NAME = 'TestClass';
    public static final String ACC_NAME = 'TestAcc';

    @isTest
    public static void testFlowUoWResetTest() {
        Account acc = new Account(Name = ACC_NAME);

        FlowUoWRegisterNew.Input inputParameter = new FlowUoWRegisterNew.Input();
        inputParameter.record = (SObject) acc;
        inputParameter.instanceName = INSTANCE_NAME;
        List<FlowUoWRegisterNew.Input> inputParameterList = new List<FlowUoWRegisterNew.Input>{ inputParameter };
        FlowUoWRegisterNew.registerNew(inputParameterList);

        FlowUoWReset.Input inputParameterReset = new FlowUoWReset.Input();
        inputParameterReset.instanceName = INSTANCE_NAME;
        List<FlowUoWReset.Input> inputParameterListReset = new List<FlowUoWReset.Input>{ inputParameterReset };
        FlowUoWReset.refreshUoW(inputParameterListReset);

        FlowUoWCommit.Input inputParameterCommit = new FlowUoWCommit.Input();
        inputParameterCommit.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterListCommit = new List<FlowUoWCommit.Input>{ inputParameterCommit };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterListCommit);
        Test.stopTest();

        List<Account> existingAccs = [SELECT Id FROM Account];
        System.assert(existingAccs.isEmpty(), 'There shouldn\'t have been any Accounts created.');
    }
}