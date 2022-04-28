/****************************************************************************************************
 * Class msUpdateParentMeterGeolocationBatch
 *
 *   Create By	:   Maciej Dudek
 *   Create Date	:   19.07.2019
 *   Description	:	Updated GPS Location field on parent Meter based on one of its child Meters
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Maciej Dudek                  	               19.07.2019       	Init version.
 *****************************************************************************************************/
public with sharing class msUpdateParentMeterGeolocationBatch extends BatchJobBase implements Database.Batchable<Meter__c>, Database.RaisesPlatformEvents {
    public msUpdateParentMeterGeolocationBatch() {
    }

    public List<Meter__c> start(Database.BatchableContext ctx) {
        super.startLogging(ctx?.getJobId());
        return [
            SELECT Id, Parent_Meter__c, GPS_Location__Latitude__s, GPS_Location__Longitude__s
            FROM Meter__c
            WHERE
                Parent_Meter__c != NULL
                AND GPS_Location__Latitude__s != NULL
                AND GPS_Location__Longitude__s != NULL
                AND Parent_Meter__r.GPS_Location__Longitude__s = NULL
                AND Parent_Meter__r.GPS_Location__Latitude__s = NULL
        ];
    }

    public void execute(Database.BatchableContext ctx, List<Meter__c> scope) {
        super.logInformation(scope, ctx?.getJobId(), 'Found ' + scope.size() + ' records.');
        Boolean success = true;
        String status = 'Processed ' + scope.size() + ' records.';
        BackendMonitoring__e logEvent = msUtility.getEvent('Update Parent Meter Geolocation Batch');
        try {
            Map<Id, Meter__c> parentMeterToParentMeterId = new Map<Id, Meter__c>();
            for (Meter__c meter : scope) {
                Meter__c parentMeter = new Meter__c();
                parentMeter.Id = meter.Parent_Meter__c;
                parentMeter.GPS_Location__Latitude__s = meter.GPS_Location__Latitude__s;
                parentMeter.GPS_Location__Longitude__s = meter.GPS_Location__Longitude__s;
                parentMeterToParentMeterId.put(parentMeter.Id, parentMeter);
            }
            List<Meter__c> parentMetersToUpdate = parentMeterToParentMeterId.values();
            update parentMetersToUpdate;

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