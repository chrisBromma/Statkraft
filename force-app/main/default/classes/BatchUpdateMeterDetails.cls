/****************************************************************************************************
* Class BatchUpdateMeterDetails
*
*   Create By	:   ChristianGottlieb (mindsquare AG)
*   Create Date	:   2021-05-11
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare AG)	            2021-05-11       	Init version.
*****************************************************************************************************/

global without sharing class BatchUpdateMeterDetails
        extends BatchJobBase
        implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    global BatchUpdateMeterDetails() {
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        super.startLogging(batchableContext?.getJobId());
        return Database.getQueryLocator('SELECT Id, Name FROM Meter__c WHERE Id IN (SELECT Meter__c FROM Meter_Details__c WHERE Active__c = TRUE)');
    }

    global void execute(Database.BatchableContext batchableContext, List<Meter__c> scope) {
        Set<Id> meterIds = new Set<Id>();
        for (Meter__c meterItem : scope) {
            meterIds.add(meterItem.Id);
        }

        List<Meter_Details__c> allRelevantDetails = MeterDetailsHelper.query_MeterDetails(meterIds);

        List<Meter_Details__c> updatingDetails = new List<Meter_Details__c>();

        Set<Id> meterIdsForUpdate = new Set<Id>();
        for (Meter_Details__c detailsItem : allRelevantDetails) {
            if (meterIds.contains(detailsItem.Meter__c)
                    && detailsItem.Active__c
                    && MeterDetailsHelper.mdt_meterNeedsUpdate(detailsItem)) {
                meterIdsForUpdate.add(detailsItem.Meter__c);
                updatingDetails.add(detailsItem);
            }
        }
        Map<Id, Meter__c> metersToUpdateMap = new Map<Id, Meter__c>(MeterDetailsHelper.query_Meters(meterIdsForUpdate));
        for (Meter_Details__c detailsItem : updatingDetails) {
            MeterDetailsHelper.mdt_determineMeterUpdate(metersToUpdateMap.get(detailsItem.Meter__c), detailsItem);
        }
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        if (!metersToUpdateMap.isEmpty()) {
            results = Database.update(metersToUpdateMap.values(), false);
        }
        String comment = msLepton.generateCommentFromSaveResults(results);
        Boolean isSuccess = false;
        if (comment == Label.batchLoggingSuccessMessage) {
            isSuccess = true;
        }
        super.logEndOfBatch(scope, batchableContext.getJobId(), isSuccess, comment);
    }

    global void finish(Database.BatchableContext batchableContext) {
        super.finishBatch(batchableContext.getJobId());
    }
}