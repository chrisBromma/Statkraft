/****************************************************************************************************
* Class MeterDetailsHandler
*
*   Create By	:   ChristianGottlieb (mindsquare AG)
*   Create Date	:   2021-05-11
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-05-11       	Init version.
*****************************************************************************************************/

public without sharing class MeterDetailsHandler extends TriggerHandlerExtension {
    MeterDetailsHelper Helper;

    // Constructor
    public MeterDetailsHandler() {
        super();
        Helper = new MeterDetailsHelper(
                (List<Meter_Details__c>) Trigger.old,
                (List<Meter_Details__c>) Trigger.new,
                (Map<Id, Meter_Details__c>) Trigger.oldMap,
                (Map<Id, Meter_Details__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(Trigger.new, false);
        }
    }

    public override void bulkAfter() {
        if (Trigger.isInsert || Trigger.isUndelete) {
            Helper.mdt_identifyMeterIds(true);
        } else if (Trigger.isUpdate) {
            Helper.mdt_identifyMeterIds(false);
        }
        Helper.load_MeterDetails();
        Helper.mdt_buildMeterDetailsTimelineDataModel();
        Helper.load_Meters();
    }


    public override void beforeInsert(SObject obj) {
        Meter_Details__c newDetails = (Meter_Details__c) obj;
        Helper.mdt_NameRecord(newDetails);
    }

    public override void beforeUpdate(SObject oldObj, SObject newObj) {
        Meter_Details__c newDetails = (Meter_Details__c) newObj;
        Helper.mdt_NameRecord(newDetails);
    }

    //public override void beforeDelete(SObject obj) { }


    public override void afterInsert(SObject obj) {
        Meter_Details__c newDetails = (Meter_Details__c) obj;
        Helper.mdt_checkTimeLineValidity(newDetails);
        Helper.mdt_updateMeterIfNecessary(newDetails);

    }

    public override void afterUpdate(SObject oldObj, SObject newObj) {
        Meter_Details__c oldDetails = (Meter_Details__c) oldObj;
        Meter_Details__c newDetails = (Meter_Details__c) newObj;
        Helper.mdt_checkTimeLineValidityIfNecessary(oldDetails, newDetails);
        Helper.mdt_updateMeterIfNecessary(newDetails);
    }

    public override void afterUndelete(SObject obj) {
        Meter_Details__c newDetails = (Meter_Details__c) obj;
        Helper.mdt_checkTimeLineValidity(newDetails);
        Helper.mdt_updateMeterIfNecessary(newDetails);
    }

    public override void andFinally() {
        if(!Helper.meterUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.meterUpdateMap.values());
        }
        if(!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}