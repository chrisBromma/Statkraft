/****************************************************************************************************
* Class msScheduledDataActivitiesTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-09-01
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-09-01       	Init version.
*****************************************************************************************************/

@IsTest
private class msScheduledDataActivitiesTest {
    private static String CRON_EXP = '0 0 0 15 3 ? 2118';
    @IsTest
    private static void test() {
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new msScheduledDataActivities());
        Test.stopTest();
        System.assert(jobId != null, 'Job not successfully scheduled');
    }

    @IsTest
    private static void getSettingsTest() {
        Test.startTest();
        Scheduled_Jobs_Settings__mdt settings = msScheduledDataActivities.getScheduledJobsSettings();
        Test.stopTest();
        System.assert(settings != null, 'No proper settings record found');
    }
}