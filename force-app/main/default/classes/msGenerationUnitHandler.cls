/****************************************************************************************************
 * Class msGenerationUnitHandler
 *
 *   Create By	:   Florian Pusse (mindsquare AG)
 *   Create Date	:   22.03.2019
 *   Description	:	cap_ -  Changes in the Capacity or Production Values result in an update to keep Data on
 *                           the Contracts correct
 *                   ssc_ -  Subsidy Scheme Calculations: The Last Day of Subsidy is automatically populated
 *                   ccg_ - Control Circuit Generation (for Virtual Power Plant)
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	    Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Florian Pusse (mindsquare AG)		    22.03.2019       	Init version.
 *   * Christian Gottlieb (mindsquare AG)    07.05.2019          V2 for Old Model to New Model Triggers
 *****************************************************************************************************/
public without sharing class msGenerationUnitHandler extends TriggerHandlerExtension {
    msGenerationUnitHelper Helper;

    // Constructor
    public msGenerationUnitHandler() {
        super();
        Helper = new msGenerationUnitHelper(
            (List<Generation_Unit__c>) Trigger.old,
            (List<Generation_Unit__c>) Trigger.new,
            (Map<Id, Generation_Unit__c>) Trigger.oldMap,
            (Map<Id, Generation_Unit__c>) Trigger.newMap
        );
    }

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public override void bulkBefore() {
        if (Trigger.isInsert) {
            List<Generation_Unit__c> newList = (List<Generation_Unit__c>) Trigger.new;
            SandboxMigrationIdGenerator.populate(newList, false);
        }
    }

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public override void bulkAfter() {
        if (Trigger.isUpdate) {
            Helper.cap_identifyGenUnitsForUpdates();
        }
        Helper.load_M2Gs();
        Helper.cap_buildM2GDataModel();

        if (Trigger.isInsert || Trigger.isUpdate) {
            Helper.ccg_isolateControlCircuitIds();
            Helper.load_ControlCircuits();
            lstInsert.addAll(Helper.ccg_createNewControlCircuits());
        }
    }

    public override void beforeInsert(SObject obj) {
        Generation_Unit__c newGenerationUnit = (Generation_Unit__c) obj;
        Helper.ssc_setSubsidyEndDate_Insert(newGenerationUnit);
    }

    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Generation_Unit__c oldGenerationUnit = (Generation_Unit__c) oldObj;
        Generation_Unit__c newGenerationUnit = (Generation_Unit__c) obj;
        Helper.ssc_setSubsidyEndDate_Update(oldGenerationUnit, newGenerationUnit);
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public override void afterUpdate(SObject oldObj, SObject obj) {
        Generation_Unit__c oldGenerationUnit = (Generation_Unit__c) oldObj;
        Generation_Unit__c newGenerationUnit = (Generation_Unit__c) obj;
        Helper.cap_setAndUpdateM2GValues(oldGenerationUnit, newGenerationUnit);
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public override void andFinally() {
        if (!Helper.m2GUUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.m2GUUpdateMap.values());
        }
        if (!lstUpdate.isEmpty()) {
            Database.update(lstUpdate);
        }
        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }
    }
}