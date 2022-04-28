@IsTest
private class msTaskHandlerTest {

    @TestSetup
    static void setup() {
        List<Task> tasksToInsert = new List<Task>();
        for(Account_KAM_Tasks_Configuration__mdt config : [
                SELECT Deadline_in_days__c, Description__c, Subject__c, Priority__c
                FROM Account_KAM_Tasks_Configuration__mdt
        ]) {
            tasksToInsert.add(msTaskHelper.extractTaskFromKAMConfig(config));
        }
        insert tasksToInsert;
    }

    @IsTest
    static void shouldThrowErrorOnTaskUpdate() {
        User u = [SELECT Id FROM User WHERE Profile.Name <> 'KAM AMC' LIMIT 1];
        System.runAs(u) {
            Task testTask = [SELECT Id, ActivityDate FROM Task LIMIT 1];
            try {
                testTask.ActivityDate = testTask.ActivityDate.addDays(1);
                update testTask;
            } catch (DmlException e) {
                System.assertEquals(Label.Task_Deadline_AMC_Error_Message, e.getDmlMessage(0));
            }
        }
    }
}