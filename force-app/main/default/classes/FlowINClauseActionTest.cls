@IsTest
public with sharing class FlowINClauseActionTest {
    
    @TestSetup
    static void createData(){
        insert new Account[]{
            new Account(Name = 'A', Rating = 'A'),
            new Account(Name = 'B', Rating = 'B'),
            new Account(Name = 'C', Rating = 'C'),
            new Account(Name = 'D', Rating = 'D'),
            new Account(Name = 'E', Rating = 'E')
        };
    }

    testmethod static void testFilterWithINClause(){

        FlowINClauseActionClass.Input[] inputList = new FlowINClauseActionClass.Input[]{};
        FlowINClauseActionClass.Output[] outputList = new FlowINClauseActionClass.Output[]{};
        
        /* Testing Exception */
        FlowINClauseActionClass.Input invalidInput = new FlowINClauseActionClass.Input();
        invalidInput.objectApiName = 'Acc';
        invalidInput.fieldsToQuery = 'Id,Name,Rating';
        invalidInput.filterField = 'Rating';
        invalidInput.filteringValuesCollection = new String[]{'A','B'};
        inputList.add(invalidInput);

        try {
            outputList = FlowINClauseActionClass.filterRecords(inputList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        
        inputList.clear();

        /* Preparing Flow Action input list */
        FlowINClauseActionClass.Input input1 = new FlowINClauseActionClass.Input();
        input1.objectApiName = 'Account';
        input1.fieldsToQuery = 'Id,Name,Rating';
        input1.filterField = 'Rating';
        input1.filteringValuesCollection = new String[]{'A','B'};
        
        FlowINClauseActionClass.Input input2 = new FlowINClauseActionClass.Input();
        input2.objectApiName = 'Account';
        input2.fieldsToQuery = 'Id,Name,Rating';
        input2.filterField = 'Rating';
        input2.filteringValuesCollection = new String[]{'C'};
        
        FlowINClauseActionClass.Input input3 = new FlowINClauseActionClass.Input();
        input3.objectApiName = 'Account';
        input3.fieldsToQuery = 'Id,Name,Rating';
        input3.filterField = 'Rating';
        input3.filteringValuesCollection = new String[]{'D','E'};
        
        inputList.add(input1);
        inputList.add(input2);
        inputList.add(input3);
        
        Test.startTest();
            outputList = FlowINClauseActionClass.filterRecords(inputList);
        Test.stopTest();

        System.assert(outputList[0].records.size() == 2);
        System.assert(outputList[1].records.size() == 1);
        System.assert(outputList[2].records.size() == 2);
    }
    
}