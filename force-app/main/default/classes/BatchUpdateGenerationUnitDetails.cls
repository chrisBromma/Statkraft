/****************************************************************************************************
 * Class BatchUpdateGenerationUnitDetails
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

global without sharing class BatchUpdateGenerationUnitDetails extends BatchJobBase implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {
    global BatchUpdateGenerationUnitDetails() {
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        super.startLogging(bc?.getJobId());
        return Database.getQueryLocator(
            'SELECT Id, (SELECT Id FROM Generation_Unit_Details__r WHERE Active__c = TRUE) FROM Generation_Unit__c'
        );
    }

    global void execute(Database.BatchableContext bc, List<Generation_Unit__c> scope) {
        Map<Id, Generation_Unit__c> allGenerationUnits = new Map<Id, Generation_Unit__c>();
        for (Generation_Unit__c generationUnitToCheckForSignificance : scope) {
            allGenerationUnits.put(generationUnitToCheckForSignificance.Id, generationUnitToCheckForSignificance);
        }

        Set<Id> firstFilterOfGenerationUnitIds = new Set<Id>();
        Set<Id> secondFilterOfGenerationUnitIds = new Set<Id>();
        List<Generation_Unit__c> generationUnitsOfSignificance = new List<Generation_Unit__c>();
        for (Generation_Unit__c generationUnitToCheckForSignificance : allGenerationUnits.values()) {
            if (!generationUnitToCheckForSignificance.Generation_Unit_Details__r.isEmpty()) {
                firstFilterOfGenerationUnitIds.add(generationUnitToCheckForSignificance.Id);
            }
        }
        for (
            Generation_Unit_Details__c detailToCheck : GenerationUnitDetailsHelper.query_GenerationUnitDetails(
                firstFilterOfGenerationUnitIds
            )
        ) {
            if (GenerationUnitDetailsHelper.mdt_generationUnitNeedsUpdate(detailToCheck)) {
                secondFilterOfGenerationUnitIds.add(detailToCheck.Generation_Unit__c);
            }
        }
        for (Id generationUnitId : secondFilterOfGenerationUnitIds) {
            generationUnitsOfSignificance.add(allGenerationUnits.get(generationUnitId));
        }

        Set<Id> generationUnitIds = new Set<Id>();
        for (Generation_Unit__c generationUnitItem : generationUnitsOfSignificance) {
            generationUnitIds.add(generationUnitItem.Id);
        }

        List<Generation_Unit_Details__c> allRelevantDetails = GenerationUnitDetailsHelper.query_GenerationUnitDetails(
            generationUnitIds
        );

        List<Generation_Unit_Details__c> updatingDetails = new List<Generation_Unit_Details__c>();

        Set<Id> generationUnitIdsForUpdate = new Set<Id>();
        for (Generation_Unit_Details__c detailsItem : allRelevantDetails) {
            if (
                generationUnitIds.contains(detailsItem.Generation_Unit__c) &&
                detailsItem.Active__c &&
                GenerationUnitDetailsHelper.mdt_generationUnitNeedsUpdate(detailsItem)
            ) {
                generationUnitIdsForUpdate.add(detailsItem.Generation_Unit__c);
                updatingDetails.add(detailsItem);
            }
        }
        Map<Id, Generation_Unit__c> generationUnitsToUpdateMap = new Map<Id, Generation_Unit__c>(
            GenerationUnitDetailsHelper.query_GenerationUnits(generationUnitIdsForUpdate)
        );
        for (Generation_Unit_Details__c detailsItem : updatingDetails) {
            GenerationUnitDetailsHelper.mdt_determineGenerationUnitUpdate(
                generationUnitsToUpdateMap.get(detailsItem.Generation_Unit__c),
                detailsItem
            );
        }

        if (!generationUnitsToUpdateMap.isEmpty()) {
            update generationUnitsToUpdateMap.values();
        }
        super.logEndOfBatch(scope, bc?.getJobId(), true, 'Processed ' + scope.size() + ' records');
    }

    global void finish(Database.BatchableContext bc) {
        super.finishBatch(bc.getJobId());
    }
}