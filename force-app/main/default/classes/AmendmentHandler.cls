/****************************************************************************************************
* Class AmendmentHandler
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-08-03
*   Description	:	ccs_ - Conga Context Setting: Sets the Conga Context on the resulting Contract so that the Annex23
 *                  Document is correctly processed (or any other Conga file for that Matter)
 *                  anp_ - Amendment Naming Patter: should always tbe Workflow Type - Contract Name | Start - End
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-08-03       	Init version.
*****************************************************************************************************/

public without sharing class AmendmentHandler extends TriggerHandlerExtension {

    AmendmentHelper Helper;

    public AmendmentHandler() {
        super();
        Helper = new AmendmentHelper(
                (List<Ammendment__c>) Trigger.old,
                (List<Ammendment__c>) Trigger.new,
                (Map<Id, Ammendment__c>) Trigger.oldMap,
                (Map<Id, Ammendment__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(Trigger.new, false);
            Helper.anp_identifyRecordsToLoad();
        } else if(Trigger.isUpdate) {
            Helper.anp_identifyRecordsToLoad_update();
        } else if (Trigger.isDelete) {
            Helper.ccs_identifyAmendments_Delete();
        }
        Helper.load_Contracts();
        Helper.ccs_buildDataModelForCongaUpdate();
    }

    public override void bulkAfter() {
        if (Trigger.isUndelete) {
            Helper.ccs_identifyAmendments_Insert();
        } else if (Trigger.isUpdate) {
            Helper.ccs_identifyAmendments_Update();
        }
        Helper.load_Contracts();
        Helper.ccs_buildDataModelForCongaUpdate();
    }

    public override void beforeInsert(SObject obj) {
        Ammendment__c newAmendment = (Ammendment__c) obj;
        Helper.anp_nameAmendment(newAmendment);
    }

    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Ammendment__c oldAmendment = (Ammendment__c) oldObj;
        Ammendment__c newAmendment = (Ammendment__c) obj;
        Helper.anp_checkIfNeedToRenameAmendment(oldAmendment, newAmendment);
    }

    public override void beforeDelete(SObject obj) {
        Ammendment__c newAmendment = (Ammendment__c) obj;
        Helper.ccs_updateContractsCongaFieldsIfNecessary_Delete(newAmendment);
    }

    public override void afterInsert(SObject obj) {
        Ammendment__c newAmendment = (Ammendment__c) obj;
        Helper.ccs_updateContractsCongaFieldsIfNecessary_Insert(newAmendment);
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        Ammendment__c oldAmendment = (Ammendment__c) oldObj;
        Ammendment__c newAmendment = (Ammendment__c) obj;
        Helper.ccs_updateContractsCongaFieldsIfNecessary_Update(oldAmendment, newAmendment);
    }

    public override void afterUndelete(SObject obj) {
        Ammendment__c newAmendment = (Ammendment__c) obj;
        Helper.ccs_updateContractsCongaFieldsIfNecessary_Insert(newAmendment);
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