/****************************************************************************************************
 * Class msMeter2GenerationUnitHandler
 *
 *   Create By	:   Fabian Kramer (mindsquare GmbH)
 *   Create Date	:   15.03.2019
 *   Description	:	Trigger Handler for the Meter2GenerationUnit SObject. This class implements the ITrigger
 * 					interface to help ensure the trigger code is bulkified and all in one place.
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Kramer (mindsquare GmbH)		15.03.2019       	Init version.
 *   * Maximilian Benning (mindsquare GmbH) 18.03.2019          Code Review -> comments
 *   * Christian Gottlieb (mindsquare GmbH) 30.07.2019          Update on Active Logic
 *****************************************************************************************************/
public without sharing class msMeter2GenerationUnitHandler extends TriggerHandlerExtension {

    // Variables
    private Map<Id, Generation_Unit__c> idToGeneratorMap = new Map<Id, Generation_Unit__c>();
    private Set<Id> srId_genUnitIdsToUpdate = new Set<Id>();
    private Map<Id, Generation_Unit__c> generationUnitUpdateMap = new Map<Id, Generation_Unit__c>();


    msMeter2GenerationUnitHelper Helper;

    // Constructor
    public msMeter2GenerationUnitHandler() {
        super();
        Helper = new msMeter2GenerationUnitHelper(
                (List<Meter2GenerationUnitRelationship__c>) Trigger.old,
                (List<Meter2GenerationUnitRelationship__c>) Trigger.new,
                (Map<Id, Meter2GenerationUnitRelationship__c>) Trigger.oldMap,
                (Map<Id, Meter2GenerationUnitRelationship__c>) Trigger.newMap);
    }


    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public override void bulkBefore() {
        List<Meter2GenerationUnitRelationship__c> newM2GUList = (List<Meter2GenerationUnitRelationship__c>) Trigger.new;
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(newM2GUList, false);
            Helper.cap_identifyM2GUsToValidateForCorrectValues_Insert();
        }
        if (Trigger.isUpdate) {
            Helper.cap_identifyM2GUsToValidateForCorrectValues_Update();
        }
        Helper.load_GenerationUnits();
    }

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public override void bulkAfter() {
        List<Meter2GenerationUnitRelationship__c> newM2GUList = (List<Meter2GenerationUnitRelationship__c>) Trigger.new;
        Map<Id, Meter2GenerationUnitRelationship__c> oldMap = (Map<Id, Meter2GenerationUnitRelationship__c>) Trigger.oldMap;
        if (Trigger.isInsert) {
            for (Meter2GenerationUnitRelationship__c relItem : newM2GUList) {
                if (relItem.Active__c) {
                    srId_genUnitIdsToUpdate.add(relItem.Generator_Unit__c);
                }
            }
        }

        if (Trigger.isUpdate) {
            for (Meter2GenerationUnitRelationship__c relItem : newM2GUList) {
                if (relItem.Active__c
                        && (!oldMap.get(relItem.Id).Active__c
                        || relItem.SR_ID__c != oldMap.get(relItem.Id).SR_ID__c)) {
                    srId_genUnitIdsToUpdate.add(relItem.Generator_Unit__c);
                }
            }
        }

        if (!srId_genUnitIdsToUpdate.isEmpty()) {
            idToGeneratorMap = new Map <Id, Generation_Unit__c> ([
                    SELECT Id, Name, Installed_Capacity__c, Annual_Production__c, SR_ID__c
                    FROM Generation_Unit__c
                    WHERE Id IN :srId_genUnitIdsToUpdate
            ]);
        }
    }

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public override void beforeInsert(SObject obj) {
        Meter2GenerationUnitRelationship__c rel = (Meter2GenerationUnitRelationship__c) obj;
        Helper.cap_validateOrOverwriteChanges_Insert(rel);
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Meter2GenerationUnitRelationship__c rel = (Meter2GenerationUnitRelationship__c) obj;
        Helper.cap_validateOrOverwriteChanges_Update(rel);
    }

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public override void afterInsert(SObject obj) {
        Meter2GenerationUnitRelationship__c newRelationship = (Meter2GenerationUnitRelationship__c) obj;
        if (newRelationship.Active__c && newRelationship.SR_ID__c != null) {
            Generation_Unit__c genUnitToUpdate = idToGeneratorMap.get(newRelationship.Generator_Unit__c);
            if (genUnitToUpdate.SR_ID__c != newRelationship.SR_ID__c ) {
                genUnitToUpdate.SR_ID__c = newRelationship.SR_ID__c;
                generationUnitUpdateMap.put(genUnitToUpdate.Id, genUnitToUpdate);
            }
        }
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public override void afterUpdate(SObject oldObj, SObject obj) {

        Meter2GenerationUnitRelationship__c newRelationship = (Meter2GenerationUnitRelationship__c) obj;
        Meter2GenerationUnitRelationship__c oldRelationship = (Meter2GenerationUnitRelationship__c) oldObj;
        if (newRelationship.Active__c
                && (!oldRelationship.Active__c
                || oldRelationship.SR_ID__c != newRelationship.SR_ID__c)) {
            Generation_Unit__c genUnitToUpdate = idToGeneratorMap.get(newRelationship.Generator_Unit__c);
            if (genUnitToUpdate.SR_ID__c != newRelationship.SR_ID__c ) {
                genUnitToUpdate.SR_ID__c = newRelationship.SR_ID__c;
                generationUnitUpdateMap.put(genUnitToUpdate.Id, genUnitToUpdate);
            }
        }
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public override void andFinally() {
        if( !generationUnitUpdateMap.isEmpty()) {
            lstUpdate.addAll(generationUnitUpdateMap.values());
        }

        if (!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}