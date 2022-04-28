/****************************************************************************************************
* Class msBatchActivateGenUnits
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-07-15
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-07-15       	Init version.
*   * Christian Gottlieb (mindsquare GmbH)              2019-07-16          Now also undo ValidFrom < Commissioning Date
*****************************************************************************************************/

global without sharing class msBatchActivateGenUnits
        extends BatchJobBase
        implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    global msBatchActivateGenUnits() {
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        super.startLogging(batchableContext?.getJobId());
        return Database.getQueryLocator(
                'SELECT ' +
                        'Id,' +
                        'Commissioning_Date__c,' +
                        'Current_Meter__c, (' +
                        'SELECT ' +
                        'Id,' +
                        'Active__c,' +
                        'Valid_from__c,' +
                        'Valid_to__c,' +
                        'Meter__c ' +
                        'FROM Meter_Generator_Relationships__r ' +
                        'ORDER BY Valid_from__c ASC ' +
                        ') ' +
                        'FROM Generation_Unit__c');
    }
    global void execute(Database.BatchableContext batchableContext, List<Generation_Unit__c> scope) {
        updateActiveFlagsOnGenerators(scope);
        super.logEndOfBatch(scope, batchableContext.getJobId(), true, Label.batchLoggingSuccessMessage);
    }
    global void finish(Database.BatchableContext batchableContext) {
        super.finishBatch(batchableContext.getJobId());
    }

    public static void updateActiveFlagForGenerators(Set<Id> genUnitIds) {
        List<Generation_Unit__c> scope = [
                SELECT
                        Id,
                        Commissioning_Date__c,
                        Current_Meter__c, (
                        SELECT
                                Id,
                                Active__c,
                                Valid_from__c,
                                Valid_to__c,
                                Meter__c
                        FROM Meter_Generator_Relationships__r
                        ORDER BY Valid_from__c ASC
                )
                FROM Generation_Unit__c
                WHERE Id IN :genUnitIds
        ];

        updateActiveFlagsOnGenerators(scope);
    }

    private static void updateActiveFlagsOnGenerators(List<Generation_Unit__c> generatorsToUpdate) {
        List<Meter2GenerationUnitRelationship__c> relationships = new List<Meter2GenerationUnitRelationship__c>();
        List<Generation_Unit__c> genUnitUpdates = new List<Generation_Unit__c>();
        for (Generation_Unit__c unitItem : generatorsToUpdate) {
            updateContainer result = setActiveFlagsForRelationshipsOnGenerator(unitItem);
            if (!result.updatedM2GURelationships.isEmpty()) {
                relationships.addAll(result.updatedM2GURelationships);
            }
            if (result.updatedGenerator != null) {
                genUnitUpdates.add(result.updatedGenerator);
            }
        }

        if (!relationships.isEmpty()) {
            update relationships;
        }
        if (!genUnitUpdates.isEmpty()) {
            update genUnitUpdates;
        }
    }


    private static updateContainer setActiveFlagsForRelationshipsOnGenerator(Generation_Unit__c generatorToCheck) {
        Id currentMeter = null;
        Meter2GenerationUnitRelationship__c activeRelationship = null;
        updateContainer result = new updateContainer();

        Map<Id, Boolean> beforeUpdateActiveState = new Map<Id, Boolean>();
        for (Meter2GenerationUnitRelationship__c relationship : generatorToCheck.Meter_Generator_Relationships__r) {
            beforeUpdateActiveState.put(relationship.Id, relationship.Active__c);

            if (relationship.Valid_from__c == null) {
                relationship.Active__c = false;
            } else {
                if (generatorToCheck.Commissioning_Date__c != null) {
                    if (relationship.Valid_from__c < generatorToCheck.Commissioning_Date__c) {
                        relationship.Valid_from__c = generatorToCheck.Commissioning_Date__c;
                    }
                }
                if (relationship.Valid_from__c <= Date.today()) {
                    if (relationship.Valid_to__c == null || relationship.Valid_to__c >= Date.today()) {
                        relationship.Active__c = true;
                        currentMeter = relationship.Meter__c;
                        if (activeRelationship != null) {
                            activeRelationship.Active__c = false;
                        }
                        activeRelationship = relationship;
                    } else {
                        relationship.Active__c = false;
                    }
                } else {
                    relationship.Active__c = false;
                }
            }
        }
        for (Meter2GenerationUnitRelationship__c relationship : generatorToCheck.Meter_Generator_Relationships__r) {
            if (relationship.Active__c != beforeUpdateActiveState.get(relationship.Id)) {
                result.updatedM2GURelationships.add(new Meter2GenerationUnitRelationship__c(
                        Id = relationship.Id,
                        Active__c = relationship.Active__c
                ));
            }
        }
        if (currentMeter != generatorToCheck.Current_Meter__c) {
            generatorToCheck.Current_Meter__c = currentMeter;
            result.updatedGenerator = new Generation_Unit__c(Id = generatorToCheck.Id, Current_Meter__c = currentMeter);
        }
        return result;
    }

    private class updateContainer {

        private List<Meter2GenerationUnitRelationship__c> updatedM2GURelationships { get; set; }
        private Generation_Unit__c updatedGenerator { get; set; }

        private updateContainer() {
            updatedM2GURelationships = new List<Meter2GenerationUnitRelationship__c>();
            updatedGenerator = null;
        }
    }
}