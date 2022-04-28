public with sharing class msUpdateMeterGPSLocationBatchScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {
        updateMeterGPSLocationBatch();
        updateParentMeterGeolocationBatch();
    }

    public static void updateMeterGPSLocationBatch() {
        Database.executeBatch(new msUpdateMeterGPSLocationBatch());
    }

    public static void updateParentMeterGeolocationBatch() {
        Database.executeBatch(new msUpdateParentMeterGeolocationBatch());
    }
}