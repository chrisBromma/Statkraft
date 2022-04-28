/****************************************************************************************************
* Class msScheduledDataActivities
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-09-01
*   Description	:	Pattern Scheduler for all Core Related Data Schedules. Settings can be found in
 *                  Custom Metadata Scheduled_Jobs_Settings__mdt
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-09-01       	Init version.
*****************************************************************************************************/

global class msScheduledDataActivities implements Schedulable {

    public static final String JOB_NAME = Test.isRunningTest() ? 'Test Scheduled Data Activities' : 'Scheduled Data Activities';
    public static final String CRON_EXPRESSION = '0 0 4 * * ? *';
    private Scheduled_Jobs_Settings__mdt settings;

    public static Id schedule() {
        return System.schedule(JOB_NAME, CRON_EXPRESSION, new msScheduledDataActivities());
    }

    public void execute(SchedulableContext ctx) {
        settings = getScheduledJobsSettings();
        if (Test.isRunningTest() || settings.Close_Cancellation_Amendment_Offers__c) {
            executeOfferTerminationBatch();
        }
        if (Test.isRunningTest() || settings.Delete_Files_Cache_from_File_Uploader__c) {
            executeDeleteUnconnectedFilesBatch();
        }
        if (Test.isRunningTest() || settings.Expire_Contracts_and_associated_Meters__c) {
            executeContractExpirationBatch();
        } else if (settings.Activate_Meters_and_Gen_Units_Batches__c) {
            executeMeterActivationBatch();
            executeGenerationUnitActivationBatch();
        }
        if(Test.isRunningTest() || settings.Rollup_Performance_Indicators__c) {
            executePerformanceIndicatorRollupBatch();
        }
        if (Test.isRunningTest() || settings.Send_Deadline_Reminder__c) {
            msKAMDeadlineReminder.sendDeadlineReminder();
        }
    }

    public msScheduledDataActivities() {
        settings = getScheduledJobsSettings();
    }

    public static Scheduled_Jobs_Settings__mdt getScheduledJobsSettings() {

        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String metaDataName = 'Production';
        if (runningInASandbox) {
            metaDataName = 'PreProd';
        }
        return Scheduled_Jobs_Settings__mdt.getInstance(metaDataName);
    }

    public void executeOfferTerminationBatch() {
        Database.executeBatch(new msBatchTerminateOffers(), (Integer) settings.Close_Cancel_Amend_Offers_Batch_Size__c);
    }

    public void executeDeleteUnconnectedFilesBatch() {
        Database.executeBatch(new msBatchDeleteUnconnectedFiles(), (Integer) settings.Delete_Unconnected_Files_Batch_Size__c);
    }

    public void executeContractExpirationBatch() {
        Database.executeBatch(new msBatchExpireContracts(), (Integer) settings.Expire_Contracts_Batch_Size__c);
    }

    public void executeMeterActivationBatch() {
        Database.executeBatch(new msBatchActivateMeters(), (Integer) settings.Activate_Meters_Batch_Size__c);
    }

    public void executeGenerationUnitActivationBatch() {
        Database.executeBatch(new msBatchActivateGenUnits(), (Integer) settings.Activate_Generation_Units_Batch_Size__c);
    }

    public void executePerformanceIndicatorRollupBatch() {
        Database.executeBatch(new msPerformanceIndicatorRollupBatch(), (Integer) settings.Rollup_Performance_Indicators_Batch_Size__c);
    }

}