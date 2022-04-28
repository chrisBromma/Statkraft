@IsTest
private class msScheduledDeadlineNotificationTest {

    @TestSetup
    static void setup() {
        String department = NPC_Assessment__c.Statkraft_Department__c.getDescribe().getPicklistValues()[0].getValue();

        NPC_Cases__c testCase = new NPC_Cases__c(
                Name = 'Test Case Name'
        );
        insert testCase;

        NPC_Assessment__c dueAssessment = new NPC_Assessment__c(
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = department,
                FARA__c = ai_PicklistValueController.getDependentPicklist(NPC_Assessment__c.FARA__c).get(department)[0],
                Deadline__c = Date.today().addDays(1)
        );
        insert dueAssessment;

        Implementation__c dueImplementation = new Implementation__c(
                NPC_Assessment__c = dueAssessment.Id,
                EndDate__c = Date.today().addDays(3)
        );
        insert dueImplementation;
    }

    @IsTest
    static void shouldScheduleJob() {
        Test.startTest();

        Id jobId = msScheduledDeadlineNotification.schedule();

        Test.stopTest();

        System.assert(![SELECT Id FROM CronTrigger WHERE Id = :jobId].isEmpty());
    }

    @IsTest
    static void shouldSendOutEmails() {
        System.assertEquals(0, Limits.getEmailInvocations());

        Test.startTest();

        msScheduledDeadlineNotification notification = new msScheduledDeadlineNotification();
        notification.execute(null);

        Integer numberOfEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();

        System.assertEquals(2, numberOfEmailsSent, 'Should send emails');
    }
}