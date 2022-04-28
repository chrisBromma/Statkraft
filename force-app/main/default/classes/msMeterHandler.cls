/****************************************************************************************************
* Class msMeterHandler
*
*   Create By	:   Florian Pusse (mindsquare GmbH)
*   Create Date	:   Florian Pusse
*   Description	:	cap_ - Capacity and Production calculations: Updates Contracts and Parent Meters Cap. and Prod.
 *                  crr_ - Contract Role Renaming: If a Meter Name changes, the Contract Role Naming is reinitialized (handled by respective trigger)
 *                  rrc_ - Remit Relevancy Check: If the Status of a Meter changes, the Remit Relevancy might need to be recalculated.
 *                  fil_ - France Id logic: MeterId and Controllable Unit Id need to be always populated
 *                  epl_ - EMSYS population logic: EMSYS Ids need to be populated and never changed again
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Florian Pusse (mindsquare GmbH)		25.03.2019       	Init version.
*****************************************************************************************************/

public without sharing class msMeterHandler extends TriggerHandlerExtension {
    msMeterHelper Helper;

    // Constructor
    public msMeterHandler() {
        super();
        Helper = new msMeterHelper(
                (List<Meter__c>) Trigger.old,
                (List<Meter__c>) Trigger.new,
                (Map<Id, Meter__c>) Trigger.oldMap,
                (Map<Id, Meter__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(Trigger.new, false);
            Helper.fil_checkIfRelevant();
        } else if (Trigger.isUpdate) {
            Helper.fil_checkIfRelevant();
        }
        Helper.load_Meters();
        Helper.fil_buildDataModel();
    }

    public override void bulkAfter() {
        if (Trigger.isInsert) {
            Helper.cap_identifyRelevantParents_Insert();
        } else if (Trigger.isUpdate) {
            Helper.cap_identifyMeters();
            Helper.cap_identifyRelevantParents_Update();
            Helper.crr_identifyMeters();
            Helper.rrc_identifyMeters();
        } else if (Trigger.isDelete) {
            Helper.cap_identifyRelevantParents_Delete();
        } else if (Trigger.isUndelete) {
            Helper.cap_identifyRelevantParents_Insert();
        }
        Helper.load_MeterRegs();
        Helper.rrc_identifyContracts();
        Helper.load_Meters();
        Helper.cap_identifyContracts();
        Helper.crr_identifyContracts();
        Helper.load_Contracts();
        Helper.load_ContractRoles();
        Helper.cap_buildDataModel();
        Helper.crr_buildDataModel();
    }

    public override void beforeInsert(SObject obj) {
        Meter__c meter = (Meter__c) obj;
        Helper.epl_ensureEMSYS_Insert(meter);
        Helper.fil_populateIds(meter);
    }

    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Meter__c newMeter = (Meter__c) obj;
        Meter__c oldMeter = (Meter__c) oldObj;
        Helper.epl_ensureEMSYS_Update(oldMeter, newMeter);
        Helper.fil_populateIds(newMeter);
    }

    public override void afterInsert(SObject obj) {
        Meter__c meter = (Meter__c) obj;
        Helper.cap_updateParent(meter);
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        Meter__c newMeter = (Meter__c) obj;
        Meter__c oldMeter = (Meter__c) oldObj;
        Helper.cap_prepareContractUpdates(oldMeter, newMeter);
        Helper.cap_updateParents(oldMeter, newMeter);
        Helper.crr_renameContractRolesIfNecessary(oldMeter, newMeter);
        Helper.rrc_checkMeterContractForRemitUpdate(oldMeter, newMeter);
    }

    public override void afterDelete(SObject obj) {
        Meter__c meter = (Meter__c) obj;
        Helper.cap_updateParent(meter);
    }

    public override void afterUndelete(SObject obj) {
        Meter__c meter = (Meter__c) obj;
        Helper.cap_updateParent(meter);
    }

    public override void andFinally() {
        if (!Helper.contractUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.contractUpdateMap.values());
        }
        if (!Helper.contractRoleUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.contractRoleUpdateMap.values());
        }
        if (!Helper.meterUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.meterUpdateMap.values());
        }
        if (!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}