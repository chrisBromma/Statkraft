/**
 * Created by Steffen Naundorf on 07.09.2021.
 */

public without sharing class GenerationUnitDetailsHandler extends TriggerHandlerExtension {
    GenerationUnitDetailsHelper Helper;

    // Constructor
    public GenerationUnitDetailsHandler() {
        super();
        Helper = new GenerationUnitDetailsHelper(
                (List<Generation_Unit_Details__c>) Trigger.old,
                (List<Generation_Unit_Details__c>) Trigger.new,
                (Map<Id, Generation_Unit_Details__c>) Trigger.oldMap,
                (Map<Id, Generation_Unit_Details__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(Trigger.new, false);
        }
    }

    public override void bulkAfter() {
        if (Trigger.isInsert || Trigger.isUndelete) {
            Helper.mdt_identifyGenerationUnitIds(true);
        } else if (Trigger.isUpdate) {
            Helper.mdt_identifyGenerationUnitIds(false);
        }
        Helper.load_GenerationUnitDetails();
        Helper.mdt_buildGenerationUnitDetailsTimelineDataModel();
        Helper.load_GenerationUnits();
    }


    public override void beforeInsert(SObject obj) {
        Generation_Unit_Details__c newDetails = (Generation_Unit_Details__c) obj;
        Helper.mdt_NameRecord(newDetails);
    }

    public override void beforeUpdate(SObject oldObj, SObject newObj) {
        Generation_Unit_Details__c newDetails = (Generation_Unit_Details__c) newObj;
        Helper.mdt_NameRecord(newDetails);
    }

    //public override void beforeDelete(SObject obj) { }


    public override void afterInsert(SObject obj) {
        Generation_Unit_Details__c newDetails = (Generation_Unit_Details__c) obj;
        Helper.mdt_checkTimeLineValidity(newDetails);
        Helper.mdt_updateGenerationUnitIfNecessary(newDetails);

    }

    public override void afterUpdate(SObject oldObj, SObject newObj) {
        Generation_Unit_Details__c oldDetails = (Generation_Unit_Details__c) oldObj;
        Generation_Unit_Details__c newDetails = (Generation_Unit_Details__c) newObj;
        Helper.mdt_checkTimeLineValidityIfNecessary(oldDetails, newDetails);
        Helper.mdt_updateGenerationUnitIfNecessary(newDetails);
    }

    public override void afterUndelete(SObject obj) {
        Generation_Unit_Details__c newDetails = (Generation_Unit_Details__c) obj;
        Helper.mdt_checkTimeLineValidity(newDetails);
        Helper.mdt_updateGenerationUnitIfNecessary(newDetails);
    }

    public override void andFinally() {
        if(!Helper.generationUnitUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.generationUnitUpdateMap.values());
        }
        if(!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}