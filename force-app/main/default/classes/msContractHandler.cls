/****************************************************************************************************
 * Class msContractHandler
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2020-11-23
 *   Description	:	rct_ - Remit Case for Termination
 *                      cel_ - Contract expiration Logic
 *                      gpm_ - Global Portal Market determination
 *                      cit_ - Conga Independent Timescale Logic, sets Conga Context for Gen Unit Assignments
 *                      anp_ Amendment Naming Pattern: If the contract renames, the Amendment must as well
 *                      ccv_ - Custom Contract Validation - Checks for a Validation that are more complex than standard SF validation rules allow
 *
 *                      can_ - Contract Auto Numbering - Custom numbering Logic
 *                      TODO: Is can_ even relevant anymore? if not, delete since it is a major time drain!!!
 *
 *
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare AG)	            2020-11-23       	Init version.
 *****************************************************************************************************/

public without sharing class msContractHandler extends TriggerHandlerExtension {
    private List<MeterRegistration__c> regsToUpdate = new List<MeterRegistration__c>();
    private List<Meter2GenerationUnitRelationship__c> m2GURelToUpdateList = new List<Meter2GenerationUnitRelationship__c>();
    private List<Generation_Unit_Ownership__c> genUnitOwnershipToUpdateList = new List<Generation_Unit_Ownership__c>();
    public Map<Id, Boolean> contractWithMeter = new Map<Id, Boolean>();

    msContractHelper Helper;

    public msContractHandler() {
        super();
        Helper = new msContractHelper(
                (List<Contract__c>) Trigger.old,
                (List<Contract__c>) Trigger.new,
                (Map<Id, Contract__c>) Trigger.oldMap,
                (Map<Id, Contract__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            Helper.cit_identifyCongaRelevancyOfAmendments_Insert();
            Helper.can_identifyCountriesForHighestNumber();
        }
        if (Trigger.isUpdate) {
            Helper.cit_identifyCongaRelevancyOfAmendments_Update();
        }
        Helper.load_Contracts();
        Helper.can_assignHighestNumbersForCountries();
        Helper.load_Amendments();
    }

    public override void bulkAfter() {
        if (Trigger.isUpdate) {
            Helper.rcc_identifyContractHolderAccounts();
            Helper.anp_identifyContractIds();
        }
        Helper.load_Accounts();
        Helper.load_Amendments();
        Helper.anp_builtDataModel();
    }

    public override void beforeInsert(SObject obj) {
        Contract__c newContract = (Contract__c) obj;
        Helper.can_assignContractIdIfNecessary(newContract);
        Helper.cit_setCongaContext_Insert(newContract);
        Helper.cel_setStatusForExpiredContracts(newContract);
        Helper.gpm_determineMarket_Insert(newContract);
    }

    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Contract__c oldContract = (Contract__c) oldObj;
        Contract__c newContract = (Contract__c) obj;
        Helper.cit_setCongaContext_Update(oldContract, newContract);
        Helper.cel_setStatusForExpiredContracts(newContract);
        Helper.gpm_determineMarket_Update(oldContract, newContract);
    }

    public override void afterInsert(SObject obj) {
        Contract__c newContract = (Contract__c) obj;
        Helper.ccv_InsertValidation(newContract);
    }

    public override void afterUndelete(SObject obj) {
        Contract__c newContract = (Contract__c) obj;
        Helper.ccv_InsertValidation(newContract);
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        Contract__c oldContract = (Contract__c) oldObj;
        Contract__c newContract = (Contract__c) obj;
        Helper.ccv_UpdateValidation(oldContract, newContract);
        Helper.rct_generateTerminationCasesIfNecessary_Update(oldContract, newContract);
        Helper.rcd_generateDelegateReportingCaseIfNecessary_Update(oldContract, newContract);
        Helper.rca_generateAgreementDateChangeCaseIfNecessary_Update(oldContract, newContract);
        Helper.rcc_generateContractHolderChangeCaseIfNecessary_Update(oldContract, newContract);
        Helper.anp_renameAmendmentsIfNecessary(oldContract, newContract);
    }

    public override void andFinally() {
        if (!Helper.amendmentsToUpdate.isEmpty()) {
            lstUpdate.addAll(Helper.amendmentsToUpdate.values());
        }
        if (!regsToUpdate.isEmpty()) {
            lstUpdate.addAll(regsToUpdate);
        }
        if (!m2GURelToUpdateList.isEmpty()) {
            lstUpdate.addAll(m2GURelToUpdateList);
        }
        if (!genUnitOwnershipToUpdateList.isEmpty()) {
            lstUpdate.addAll(genUnitOwnershipToUpdateList);
        }
        if (!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
        if (!Helper.casesToInsert.isEmpty()) {
            lstInsert.addAll(Helper.casesToInsert);
        }
        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }
    }
}