/**
 * Created by Fabian on 25.03.2021.
 */
@IsTest
public with sharing class msKAMDeadlineReminderTest {
    @TestSetup
    public static void testSetup() {
        KAM_Request_Dashboard_Settings__c setting = new KAM_Request_Dashboard_Settings__c(
            Deadline__c = Date.today() - 1
        );
        insert setting;
    }
    @IsTest
    public static void testDeadlineReminder() {
        Test.startTest();
        new msKAMDeadlineReminder().sendDeadlineReminder(null);
        Test.stopTest();

        List<Task> createdTasks = [SELECT Id, OwnerId FROM Task];
        System.assert(!createdTasks.isEmpty());
        User kamAMCUser = [SELECT Profile.Name FROM User WHERE Id = :createdTasks[0].OwnerId];
        System.assertEquals('KAM AMC', kamAMCUser.Profile.Name);
    }
    @IsTest
    public static void testNoExecutionScenarioOnDeadline() {
        KAM_Request_Dashboard_Settings__c setting = KAM_Request_Dashboard_Settings__c.getOrgDefaults();
        setting.Deadline__c = Date.today();
        update setting;

        Test.startTest();
        new msKAMDeadlineReminder().sendDeadlineReminder(null);
        Test.stopTest();

        List<Task> createdTasks = [SELECT Id FROM Task];
        System.assert(createdTasks.isEmpty());
        System.debug(KAM_Request_Dashboard_Settings__c.getOrgDefaults().Deadline__c);
    }
    @IsTest
    public static void testNoExecutionScenarioTwoDaysAfterDeadline() {
        KAM_Request_Dashboard_Settings__c setting = KAM_Request_Dashboard_Settings__c.getOrgDefaults();
        setting.Deadline__c = Date.today() - 2;
        update setting;

        Test.startTest();
        new msKAMDeadlineReminder().sendDeadlineReminder(null);
        Test.stopTest();

        List<Task> createdTasks = [SELECT Id FROM Task];
        System.assert(createdTasks.isEmpty());
        System.debug(KAM_Request_Dashboard_Settings__c.getOrgDefaults().Deadline__c);
    }
}