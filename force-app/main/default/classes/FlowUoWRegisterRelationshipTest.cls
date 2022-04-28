@IsTest
public with sharing class FlowUoWRegisterRelationshipTest {
    public static final String INSTANCE_NAME = 'TestClass';
    public static final String ACC_NAME = 'TestAcc';
    public static final String OPP_NAME = 'TestOpp';
    public static final Id DOWNSTREAM_OPP = Application.RecordTypes.byDeveloperName(
            'Opportunity',
            'Downstream_Opportunity'
        )
        .Id;

    @IsTest
    public static void testFlowUoWRegisterRelationshipTest() {
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
        List<FlowUoWRegisterNew.Input> inputParameterListOpp = new List<FlowUoWRegisterNew.Input>{ inputParameterOpp };
        FlowUoWRegisterNew.registerNew(inputParameterListOpp);

        FlowUoWRegisterRelationship.Input inputParameterRelation = new FlowUoWRegisterRelationship.Input();
        inputParameterRelation.record = (SObject) opp;
        inputParameterRelation.relationshipPath = 'Opportunity.AccountId';
        inputParameterRelation.related = (SObject) acc;
        inputParameterRelation.instanceName = INSTANCE_NAME;
        List<FlowUoWRegisterRelationship.Input> inputParameterListRelation = new List<FlowUoWRegisterRelationship.Input>{
            inputParameterRelation
        };
        FlowUoWRegisterRelationship.registerRelationship(inputParameterListRelation);

        FlowUoWCommit.Input inputParameterCommit = new FlowUoWCommit.Input();
        inputParameterCommit.instanceName = INSTANCE_NAME;
        List<FlowUoWCommit.Input> inputParameterListCommit = new List<FlowUoWCommit.Input>{ inputParameterCommit };

        Test.startTest();
        FlowUoWCommit.commitWork(inputParameterListCommit);
        Test.stopTest();

        Account accInserted = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppInserted = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        System.assertEquals(
            accInserted.Id,
            oppInserted.AccountId,
            'The Opportunity wasn\'t successfully linked to the Account.'
        );
    }
}