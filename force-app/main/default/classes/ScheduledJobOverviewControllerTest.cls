@isTest
public with sharing class ScheduledJobOverviewControllerTest {
    
    @isTest static void checkIfSchedulesAreFound(){
        //We can't create Scheduled Flows in a test context, but the other two.
        createScheduledMassAction();
        createScheduledBatchJobInFramework();

        ScheduledJobOverviewController ctrl = new ScheduledJobOverviewController();
        System.assert(!ctrl.scheduledApexJobs.isEmpty());
        System.assert(!ctrl.scheduledMassActions.isEmpty());
    }

    private static void createScheduledMassAction(){
        //Taken straight from MA_MassActionConfigTriggerHandlerTest
        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c activeConfig = new Mass_Action_Configuration__c(
            Name = 'Test Config 1',
            DeveloperName__c = 'Test_Config1',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Custom',
            Schedule_Cron__c = '0 0 1 * * ?'
        );

        insert activeConfig;



    }

    private static void createScheduledBatchJobInFramework(){
        Batch_Job_Schedule__c sch1 = new Batch_Job_Schedule__c();
        sch1.RecordTypeId = GlobalConstants.SCHEDULER_RECORD_TYPE_HOURLY_JOB;
        sch1.Name = 'Test Hourly Name 001';
        sch1.Every_Number_of_Hours__c = 1;
        sch1.Preferred_Start_Minute__c = '0'; 

        insert sch1;

        sch1 = [SELECT Id, Name,Cron_Expression__c FROM Batch_Job_Schedule__c LIMIT 1];
        Id cronTriggerId = System.schedule(sch1.Name, sch1.Cron_Expression__c,  new BatchJobScheduler());

        sch1.Cron_Trigger_Id__c = cronTriggerId;
        update sch1;
    }


}