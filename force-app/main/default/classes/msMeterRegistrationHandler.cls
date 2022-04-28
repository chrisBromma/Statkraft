/****************************************************************************************************
* Class msMeterRegistrationHandler
*
*   Create By	:   Fabian Kramer (mindsquare GmbH)
*   Create Date	:
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Kramer (mindsquare GmbH)		                  	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      30.07.2019          Update to Active Logic
*****************************************************************************************************/

public without sharing class msMeterRegistrationHandler extends TriggerHandlerExtension {

    msMeterRegistrationHelper Helper;

    // Constructor
    public msMeterRegistrationHandler() {
        super();

        Helper = new msMeterRegistrationHelper(
                (List<MeterRegistration__c>) Trigger.old,
                (List<MeterRegistration__c>) Trigger.new,
                (Map<Id, MeterRegistration__c>) Trigger.oldMap,
                (Map<Id, MeterRegistration__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(Trigger.new, false);
            Helper.fbc_determineIfBalancingCirclesNeedToBeLoadedOnInsert();
            Helper.bcl_determineIfBalancingCirclesNeedToBeLoadedOnInsert();
        } else if (Trigger.isUpdate) {
            Helper.fbc_determineIfBalancingCirclesNeedToBeLoadedOnUpdate();
            Helper.bcl_determineIfBalancingCirclesNeedToBeLoadedOnUpdate();
        }
        Helper.load_BalancingCircles();
        Helper.fbc_setFranceBalancingCircle();
        Helper.bcl_buildBalancingCircleMappingToNames();
    }


    public override void bulkAfter() {
        if (Trigger.isInsert || Trigger.isUndelete) {
            Helper.mrs_identifyContractsForStatusUpdate_Insert();
            Helper.rrc_identifyContractIds_Insert();
            Helper.cap_identifyContractsForCalculation_Insert();
        } else if (Trigger.isUpdate) {
            Helper.mrs_identifyContractsForStatusUpdate_Update();
            Helper.rrc_identifyContractIds_Update();
            Helper.cap_identifyContractsForCalculation_Update();
        } else if (Trigger.isDelete) {
            Helper.mrs_identifyContractsForStatusUpdate_Delete();
            Helper.rrc_identifyContractIds_Delete();
            Helper.cap_identifyContractsForCalculation_Delete();
        }
        Helper.load_Contracts();
        Helper.mrs_buildMeterRegStatusUpdateDataModel();
        Helper.rrc_createRemitRelevancyDataModel();
        Helper.cap_buildDataModel();
    }

    public override void beforeInsert(SObject obj) {
        MeterRegistration__c newMeterRegistration = (MeterRegistration__c) obj;
        Helper.fbc_ifFranceSetBalancingCircle(newMeterRegistration);
        Helper.bcl_matchPicklistWithLookupForBalancingCircleOnInsert(newMeterRegistration);
    }

    public override void beforeUpdate(SObject oldObj, SObject obj) {
        MeterRegistration__c newMeterRegistration = (MeterRegistration__c) obj;
        MeterRegistration__c oldMeterRegistration = (MeterRegistration__c) oldObj;
        Helper.fbc_ifFranceSetBalancingCircle(newMeterRegistration);
        Helper.bcl_matchPicklistWithLookupForBalancingCircleOnUpdate(oldMeterRegistration, newMeterRegistration);
    }


    public override void afterInsert(SObject obj) {
        MeterRegistration__c newMeterRegistration = (MeterRegistration__c) obj;
        Helper.rrc_setAndUpdateContractRemitRelevancy(newMeterRegistration);
        Helper.cap_checkForContractUpdate(newMeterRegistration);
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        MeterRegistration__c newMeterRegistration = (MeterRegistration__c) obj;
        MeterRegistration__c oldMeterRegistration = (MeterRegistration__c) oldObj;
        Helper.rrc_checkSetAndUpdateContractRemitRelevancy(oldMeterRegistration, newMeterRegistration);
        Helper.mrs_updateContractRegStatusIfRelevantChange(oldMeterRegistration, newMeterRegistration);
        Helper.cap_checkForContractUpdate(oldMeterRegistration, newMeterRegistration);
    }

    public override void afterDelete(SObject obj) {
        MeterRegistration__c deletedReg = (MeterRegistration__c) obj;
        Helper.rrc_setAndUpdateContractRemitRelevancy(deletedReg);
        Helper.mrs_updateContractRegStatus(deletedReg);
        Helper.cap_checkForContractUpdate(deletedReg);
    }

    public override void afterUndelete(SObject obj) {
        MeterRegistration__c undeletedReg = (MeterRegistration__c) obj;
        Helper.rrc_setAndUpdateContractRemitRelevancy(undeletedReg);
        Helper.mrs_updateContractRegStatus(undeletedReg);
        Helper.cap_checkForContractUpdate(undeletedReg);
    }

    public override void andFinally() {
        if (!Helper.contractUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.contractUpdateMap.values());
        }
        if (!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}