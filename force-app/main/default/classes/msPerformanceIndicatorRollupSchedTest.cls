@IsTest
public class msPerformanceIndicatorRollupSchedTest {

    @IsTest
    static void shouldScheduleJob() {
        Test.startTest();

        Id scheduleId = msPerformanceIndicatorRollupScheduler.schedule();

        Test.stopTest();

        System.assertNotEquals(null, scheduleId);
    }

    @IsTest
    static void shouldScheduleBatch() {
        msPerformanceIndicatorRollupScheduler performanceIndicatorRollupScheduler = new msPerformanceIndicatorRollupScheduler();

        Test.startTest();

        performanceIndicatorRollupScheduler.execute(null);

        Test.stopTest();

        System.assert(![SELECT Id FROM AsyncApexJob WHERE JobType = 'BatchApex'].isEmpty());
    }
}