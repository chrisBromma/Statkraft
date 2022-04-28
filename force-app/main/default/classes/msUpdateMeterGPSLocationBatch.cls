/****************************************************************************************************
 * Class msUpdateMeterGPSLocationBatch
 *
 *   Create By	:   Maciej Dudek
 *   Create Date	:   26.06.2019
 *   Description	:	Updated GPS Location field on Meter based on one of its Generation Units
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Maciej Dudek                  	               26.06.2019       	Init version.
 *****************************************************************************************************/
public class msUpdateMeterGPSLocationBatch extends BatchJobBase implements Database.Batchable<Meter2GenerationUnitRelationship__c>, Database.RaisesPlatformEvents {
    public msUpdateMeterGPSLocationBatch() {
    }

    public List<Meter2GenerationUnitRelationship__c> start(Database.BatchableContext ctx) {
        super.startLogging(ctx?.getJobId());
        return [
            SELECT
                Id,
                Meter__c,
                Generator_Unit__r.GPS_Location__Longitude__s,
                Generator_Unit__r.GPS_Location__Latitude__s
            FROM Meter2GenerationUnitRelationship__c
            WHERE
                (Meter__r.GPS_Location__Latitude__s = NULL
                OR Meter__r.GPS_Location__Longitude__s = NULL)
                AND Generator_Unit__r.GPS_Location__Longitude__s != NULL
                AND Generator_Unit__r.GPS_Location__Latitude__s != NULL
        ];
    }

    public void execute(Database.BatchableContext ctx, List<Meter2GenerationUnitRelationship__c> scope) {
        super.logInformation(scope, ctx?.getJobId(), 'Working on ' + scope.size() + ' records.');
        BackendMonitoring__e logEvent = msUtility.getEvent('Update Meter GPS Location Batch');
        Boolean success = true;
        String status = 'Processed ' + scope.size() + ' records.';
        try {
            Map<Id, Meter__c> metersByIds = new Map<Id, Meter__c>();
            for (Meter2GenerationUnitRelationship__c relationship : scope) {
                if (!metersByIds.containsKey(relationship.Meter__c)) {
                    Meter__c meter = new Meter__c();
                    meter.Id = relationship.Meter__c;
                    meter.GPS_Location__Latitude__s = relationship.Generator_Unit__r.GPS_Location__Latitude__s;
                    meter.GPS_Location__Longitude__s = relationship.Generator_Unit__r.GPS_Location__Longitude__s;
                    metersByIds.put(meter.Id, meter);
                }
            }
            List<Meter__c> metersForUpdate = metersByIds.values();
            update metersForUpdate;

            msUtility.ifTestThrowFakeException();
        } catch (Exception e) {
            success = false;
            status = e.getMessage() + '\n' + e.getStackTraceString();
            logEvent = msUtility.handleException(logEvent, e);
            super.logInformation(scope, ctx?.getJobId(), 'Error: ' + e.getMessage());
        } finally {
            msUtility.publishEvent(logEvent);
        }
        super.logEndOfBatch(scope, ctx?.getJobId(), success, status);
    }

    public void finish(Database.BatchableContext ctx) {
        super.finishBatch(ctx.getJobId());
    }
}