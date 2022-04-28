global class msPerformanceIndicatorRollupScheduler implements Schedulable {

    public static final String JOB_NAME = Test.isRunningTest()
            ? 'Test Performance Indicator Rollup'
            : 'Performance Indicator Rollup';
    public static final String CRON_EXPRESSION = '0 0 0 * * ?';

    public static Id schedule() {
        return System.schedule(
                JOB_NAME,
                CRON_EXPRESSION,
                new msPerformanceIndicatorRollupScheduler()
        );
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new msPerformanceIndicatorRollupBatch(), 100);
    }
}