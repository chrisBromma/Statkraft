@IsTest
private class msUpdateMeterGPSLocationSchedulerTest {

    private static final String CRON_EXP = '0 0 * * * ?';

    @IsTest
    private static void testScheduleUpdateMeterGPSLocation() {

        Test.startTest();
            System.schedule('msUpdateMeterGPSLocationSchedulerTest', CRON_EXP, new msUpdateMeterGPSLocationBatchScheduler());
        Test.stopTest();

        System.assertNotEquals(0, [SELECT count() FROM CronTrigger], 'A job should be scheduled');
    }
}