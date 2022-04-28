/****************************************************************************************************
* Class Contract_ChangeEventHandler
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-01
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-01       	Init version.
*****************************************************************************************************/

public without sharing class Contract_ChangeEventHandler extends TriggerHandlerExtension {

    List<Contract__ChangeEvent> triggerNew = (List<Contract__ChangeEvent>) Trigger.new;

    private Contract_ChangeEventHelper Helper;

    // Constructor
    public Contract_ChangeEventHandler() {
        super();
        Helper = new Contract_ChangeEventHelper(triggerNew);
    }

    public override void bulkAfter() {
        for (Contract__ChangeEvent change : triggerNew) {
            String eventContext = change.ChangeEventHeader.getChangeType();
            if (eventContext == 'CREATE' || eventContext == 'UNDELETE') {
                Helper.exp_identifyExpiredContractsToCheckForRelevancy();
            } else if (eventContext == 'UPDATE') {
                Helper.exp_identifyExpiredContractsToCheckForRelevancy();
                Helper.cpr_identifyContracts_Update();
            }
        }
        Helper.load_Contracts();
        Helper.load_GenUnitAssignments();
        Helper.exp_identifyRelevantExpiredContracts();
        Helper.load_MeterRegistrations();
        Helper.exp_identifyMetersForExpirationCheck();
        Helper.exp_load_SuccessorRegistrations();
        Helper.exp_buildDataModelMeterRegs();
        Helper.exp_identifyMetersWithoutSuccessor();
        Helper.load_M2Gs();
        Helper.exp_identifyGenUnitsThatMightDropOutOfPortfolio();
        Helper.exp_load_SuccessorM2Gs();
        Helper.exp_buildDataModelM2G();
        Helper.exp_identifyGenUnitsWithoutSuccessor();
        Helper.load_GenUnitOwnerships();
        Helper.exp_buildDataModelGenUnitOwnership();
        Helper.cpr_buildDataModel();
    }

    public override void afterInsert(SObject obj) {
        Contract__ChangeEvent change = (Contract__ChangeEvent) obj;
        String eventContext = change.ChangeEventHeader.getChangeType();
        if (eventContext == 'CREATE' || eventContext == 'UNDELETE') {
            Helper.exp_ifExpirationHandleContracts(change);
        } else if(eventContext == 'UPDATE') {
            Helper.exp_ifExpirationHandleContracts(change);
            Helper.cpr_calculateContractUpdate(change);
        }
    }

    public override void andFinally() {
        if (!Helper.meterRegUpdates.isEmpty()) {
            lstUpdate.addAll(Helper.meterRegUpdates.values());
        }
        if (!Helper.contractUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.contractUpdateMap.values());
        }
        if (!Helper.genUnitOwnershipUpdates.isEmpty()) {
            lstUpdate.addAll(Helper.genUnitOwnershipUpdates.values());
        }
        if (!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}