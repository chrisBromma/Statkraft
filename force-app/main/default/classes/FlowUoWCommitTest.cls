@IsTest
public with sharing class FlowUoWCommitTest {
    public static final String INSTANCE_NAME = 'TestClass';
    public static final String ACC_NAME = 'TestAcc';

    @IsTest
    public static void testFlowUoWCommitTest() {
        fflib_SObjectUnitOfWork instance = UnitOfWorkSingleton.getInstance(INSTANCE_NAME);
        Account acc = new Account(Name = ACC_NAME);
        instance.registerNew(acc);

        FlowUoWCommit.Input inputParameter = new FlowUoWCommit.Input();
        inputParameter.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterList = new List<FlowUoWCommit.Input>{ inputParameter };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterList);
        Test.stopTest();

        Account accInserted = [SELECT Id, Name FROM Account LIMIT 1];
        System.assertEquals(
            ACC_NAME,
            accInserted.Name,
            'There should have been an Account created with the Name ' + ACC_NAME
        );
    }
}