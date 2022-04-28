@isTest
public with sharing class FlowINClauseWithSObjectListActionTest {
    private static final Id DE_ACC_RECORD_TYPE =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId();

    @TestSetup
    private static void setUp() {
        List <Account> listGrandParents = new List<Account>();
        List <Account> listParents = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            listGrandParents.add(new Account(
                    Name = 'Grand Parent' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
                    ));
            listParents.add(new Account(
                    Name = 'Parent' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
            ));
        }
        List <Account> allParentAccountsToInsert = new List<Account>();
        allParentAccountsToInsert.addAll(listGrandParents);
        allParentAccountsToInsert.addAll(listParents);
        insert allParentAccountsToInsert;

        Task testTask = new Task();
        testTask.Subject = 'Germany';
        testTask.Description = 'Grand Parent1';
        testTask.ActivityDate = System.today().addDays(1);
        insert testTask;
    }

    @isTest static void testCrossQuery(){
        List<Task> testTasks = [SELECT Id, Subject, Description FROM Task];

        List<FlowINClauseWithSObjectListAction.Input> inputs = new List<FlowINClauseWithSObjectListAction.Input>();
        FlowINClauseWithSObjectListAction.Output[] outputList = new FlowINClauseWithSObjectListAction.Output[]{};

        FlowINClauseWithSObjectListAction.Input input = new FlowINClauseWithSObjectListAction.Input();
        input.objectApiName = 'Account';
        input.fieldsToQuery = 'Name,BillingCountry';
        input.filterField = 'BillingCountry';
        input.idField = 'Subject';
        input.filteringValuesCollection = testTasks;
        inputs.add(input);

        FlowINClauseWithSObjectListAction.Input input2 = new FlowINClauseWithSObjectListAction.Input();
        input2.objectApiName = 'Account';
        input2.fieldsToQuery = 'Name,BillingCountry';
        input2.filterField = 'Name';
        input2.idField = 'Description';
        input2.filteringValuesCollection = testTasks;
        inputs.add(input2);

        Test.startTest();
            outputList = FlowINClauseWithSObjectListAction.filterRecords(inputs);
        Test.stopTest();

        System.assert(outputList[0].records.size() == 200);
        System.assert(outputList[1].records.size() == 1);
    }
}