@IsTest
public with sharing class FlowUoWRegisterDirtyTest {
    public static final String INSTANCE_NAME = 'TestClass';
    public static final String ACC_NAME = 'TestAcc';
    public static final String ACC_NAME_CHANGED = 'TestAccChanged';
    public static final String OPP_NAME = 'TestOpp';
    public static final Id DOWNSTREAM_OPP = Application.RecordTypes.byDeveloperName(
            'Opportunity',
            'Downstream_Opportunity'
        )
        .Id;

    @IsTest
    public static void testFlowUoWRegisterDirtyTest() {
        Account acc = new Account(Name = ACC_NAME);
        insert acc;
        acc.Name = ACC_NAME_CHANGED;

        FlowUoWRegisterDirty.Input inputParameter = new FlowUoWRegisterDirty.Input();
        inputParameter.record = (SObject) acc;
        inputParameter.instanceName = INSTANCE_NAME;
        List<FlowUoWRegisterDirty.Input> inputParameterList = new List<FlowUoWRegisterDirty.Input>{ inputParameter };
        FlowUoWRegisterDirty.registerDirty(inputParameterList);

        FlowUoWCommit.Input inputParameterCommit = new FlowUoWCommit.Input();
        inputParameterCommit.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterListCommit = new List<FlowUoWCommit.Input>{ inputParameterCommit };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterListCommit);
        Test.stopTest();

        Account accChanged = [SELECT Id, Name FROM Account LIMIT 1];
        System.assertEquals(
            ACC_NAME_CHANGED,
            accChanged.Name,
            'The Name of the Account should have been changed to ' + ACC_NAME_CHANGED
        );
    }
    @IsTest
    public static void testFlowUoWRegisterDirtyWithRelationTest() {
        Account acc = new Account(Name = ACC_NAME);

        Opportunity opp = new Opportunity(
            RecordTypeId = DOWNSTREAM_OPP,
            Name = OPP_NAME,
            StageName = 'Analysis',
            CloseDate = Date.today()
        );
        insert opp;

        FlowUoWRegisterNew.Input inputParameter = new FlowUoWRegisterNew.Input();
        inputParameter.record = (SObject) acc;
        inputParameter.instanceName = INSTANCE_NAME;
        List<FlowUoWRegisterNew.Input> inputParameterList = new List<FlowUoWRegisterNew.Input>{ inputParameter };
        FlowUoWRegisterNew.registerNew(inputParameterList);

        FlowUoWRegisterDirty.Input inputParameterOpp = new FlowUoWRegisterDirty.Input();
        inputParameterOpp.record = (SObject) opp;
        inputParameterOpp.instanceName = INSTANCE_NAME;
        inputParameterOpp.parent = (SObject) acc;
        inputParameterOpp.relationshipPath = 'Opportunity.AccountId';
        List<FlowUoWRegisterDirty.Input> inputParameterListOpp = new List<FlowUoWRegisterDirty.Input>{
            inputParameterOpp
        };
        FlowUoWRegisterDirty.registerDirty(inputParameterListOpp);

        FlowUoWCommit.Input inputParameterCommit = new FlowUoWCommit.Input();
        inputParameterCommit.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterListCommit = new List<FlowUoWCommit.Input>{ inputParameterCommit };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterListCommit);
        Test.stopTest();

        Account accInserted = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppUpdated = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        System.assertEquals(
            accInserted.Id,
            oppUpdated.AccountId,
            'The Relation between the Opp and the Account wasn\'t established.'
        );
    }
}