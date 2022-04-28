@IsTest
public with sharing class FlowUoWRegisterNewTest {
    public static final String INSTANCE_NAME = 'TestClass';
    public static final String ACC_NAME = 'TestAcc';
    public static final String OPP_NAME = 'TestOpp';
    public static final Id DOWNSTREAM_OPP = Application.RecordTypes.byDeveloperName(
            'Opportunity',
            'Downstream_Opportunity'
        )
        .Id;

    @IsTest
    public static void testFlowUoWRegisterNew() {
        Account acc = new Account(Name = ACC_NAME);

        FlowUoWRegisterNew.Input inputParameter = new FlowUoWRegisterNew.Input();
        inputParameter.record = (SObject) acc;
        inputParameter.instanceName = INSTANCE_NAME;
        List<FlowUoWRegisterNew.Input> inputParameterList = new List<FlowUoWRegisterNew.Input>{ inputParameter };
        FlowUoWRegisterNew.registerNew(inputParameterList);

        FlowUoWCommit.Input inputParameterCommit = new FlowUoWCommit.Input();
        inputParameterCommit.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterListCommit = new List<FlowUoWCommit.Input>{ inputParameterCommit };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterListCommit);
        Test.stopTest();

        Account createdAccount = [SELECT Id FROM Account LIMIT 1];
        System.assert(createdAccount != null, 'There was no Account created.');
    }
    @IsTest
    public static void testFlowUoWRegisterNewWithRelation() {
        Account acc = new Account(Name = ACC_NAME);
        Opportunity opp = new Opportunity(
            RecordTypeId = DOWNSTREAM_OPP,
            Name = OPP_NAME,
            StageName = 'Analysis',
            CloseDate = Date.today()
        );
        FlowUoWRegisterNew.Input inputParameter = new FlowUoWRegisterNew.Input();
        inputParameter.record = (SObject) acc;
        inputParameter.instanceName = INSTANCE_NAME;
        List<FlowUoWRegisterNew.Input> inputParameterList = new List<FlowUoWRegisterNew.Input>{ inputParameter };
        FlowUoWRegisterNew.registerNew(inputParameterList);

        FlowUoWRegisterNew.Input inputParameterOpp = new FlowUoWRegisterNew.Input();
        inputParameterOpp.record = (SObject) opp;
        inputParameterOpp.instanceName = INSTANCE_NAME;
        inputParameterOpp.parent = (SObject) acc;
        inputParameterOpp.relationshipPath = 'Opportunity.AccountId';
        List<FlowUoWRegisterNew.Input> inputParameterListOpp = new List<FlowUoWRegisterNew.Input>{ inputParameterOpp };
        FlowUoWRegisterNew.registerNew(inputParameterListOpp);

        FlowUoWCommit.Input inputParameterCommit = new FlowUoWCommit.Input();
        inputParameterCommit.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterListCommit = new List<FlowUoWCommit.Input>{ inputParameterCommit };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterListCommit);
        Test.stopTest();

        Account createdAccount = [SELECT Id FROM Account LIMIT 1];
        System.assert(createdAccount != null, 'There was no Account created.');
        Opportunity createdOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        System.assertEquals(createdAccount.Id, createdOpp.AccountId, 'The Account wasn\'t set as parent of the Opp');
    }
}