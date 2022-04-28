/****************************************************************************************************
 * Class msCaseHandler
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2020-07-21
 *   Description	:	This handler covers the following automations on Case:
 *                   1. Updates on relevant Cases induce an update on the Contract Status fields on the Contract. See the
 *                   Code for further definitions
 *                   2. If a Case is updated to point towards a different Opportunity:
 *                   All Historical Data Content versions will be connected to all files along the path:
 * 				    Case --> Opportunity --> Offer --> (Resulting) Contract
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * -----------------------------------------------------------------------------------------------
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare AG)	            2020-07-21       	Init version.
 *   * Christian Gottlieb (mindsquare AG)	            2021-03-24       	Added logic for Historical Data forwarding
 *   * Dennis Grzyb (mindsquare AG)	                    2021-03-24       	Added Sandbox Seeding
 *****************************************************************************************************/

public without sharing class msCaseHandler extends TriggerHandlerExtension {
    msCaseHelper helper;

    // Constructor
    public msCaseHandler() {
        super();
        helper = new msCaseHelper(
            (List<Case>) Trigger.old,
            (List<Case>) Trigger.new,
            (Map<Id, Case>) Trigger.oldMap,
            (Map<Id, Case>) Trigger.newMap
        );
    }

    public override void bulkAfter() {
        if (Trigger.isInsert) {
            helper.csu_identifyCasesForUpdates_Insert();
        }
        if (Trigger.isUpdate) {
            helper.csu_identifyCasesForUpdates_Update();
        }
        helper.load_Contracts();
        helper.csu_buildDataModelGeneralCases();
        helper.load_Cases();
        helper.csu_buildDataModelMeterRegCases();
    }

    public override void afterInsert(SObject obj) {
        Case newCase = (Case) obj;
        helper.csu_updateContractIfMeterRegCase_Insert(newCase);
        helper.csu_updateContractIfCaseRelevant_Insert(newCase);
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        Case newCase = (Case) obj;
        Case oldCase = (Case) oldObj;
        helper.csu_updateContractIfMeterRegCase_Update(oldCase, newCase);
        helper.csu_updateContractIfCaseRelevant_Update(oldCase, newCase);
    }

    public override void andFinally() {
        if (!helper.contractUpdateMap.isEmpty()) {
            lstUpdate.addAll(helper.contractUpdateMap.values());
        }
        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }
        if (!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}