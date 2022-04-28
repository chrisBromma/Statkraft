/****************************************************************************************************
* Class AmendmentHelper
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

public without sharing class AmendmentHelper {
    //Class specific variables and Constructor
    private List<Ammendment__c> triggerOld;
    private List<Ammendment__c> triggerNew;
    private Map<Id, Ammendment__c> oldMap;
    private Map<Id, Ammendment__c> newMap;

    //Constructors
    public AmendmentHelper(
            List<Ammendment__c> oldList,
            List<Ammendment__c> newList,
            Map<Id, Ammendment__c> mapOld,
            Map<Id, Ammendment__c> mapNew) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //Global / System / Static / Final
    private static final String DATE_FORMAT_STRING = 'dd.MM.yyyy';
    //Please keep the SOQL and DML Listings sorted alphanumerically sorted by SObjectType (_< 1 < a)

    //SOQL Maps -- Only one Map per SObjectType allowed
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Offer__c> offerMap = new Map<Id, Offer__c>();

    //DML Lists/Maps -- Only use Maps for Update -- Only one item per DML Type and SObjectType
    public Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();

    //Conga Context Setting relevant variables
    private Set<Id> ccs_relevantAmendmentIds = new Set<Id>();
    private ListMapContainer ccs_amendmentIdToContracts = new ListMapContainer(Contract__c.SObjectType);

    //Naming Pattern variables
    private Set<Id> anp_baseContractIds = new Set<Id>();

    //SOQL Methods
    public void load_Contracts() {
        if (!ccs_relevantAmendmentIds.isEmpty()
                || !anp_baseContractIds.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Id, Start_Date__c, End_Date__c, Name,
                            Start_for_Conga_Context__c, End_for_Conga_Context__c, Last_Amentment__c,
                            Last_Amentment__r.Amendment_Start__c, Last_Amentment__r.Amendment_End__c
                    FROM Contract__c
                    WHERE Last_Amentment__c IN :ccs_relevantAmendmentIds
                    OR Id IN :anp_baseContractIds
            ]);
        }
    }

    //Conga Context Setting methods
    public void ccs_identifyAmendments_Insert() {
        for (Ammendment__c newAmendment : triggerNew) {
            if (ccs_isRelevantForCongaUpdate(newAmendment)) {
                ccs_relevantAmendmentIds.add(newAmendment.Id);
            }
        }
    }

    public void ccs_identifyAmendments_Delete() {
        for (Ammendment__c oldAmendment : triggerOld) {
            if (ccs_isRelevantForCongaUpdate(oldAmendment)) {
                ccs_relevantAmendmentIds.add(oldAmendment.Id);
            }
        }
    }

    public void ccs_identifyAmendments_Update() {
        for (Ammendment__c newAmendment : triggerNew) {
            if (ccs_isRelevantForCongaUpdate(newAmendment)
                    && ccs_isRelevantChangeForCongaUpdate(oldMap.get(newAmendment.Id), newAmendment)) {
                ccs_relevantAmendmentIds.add(newAmendment.Id);
            }
        }
    }

    private static Boolean ccs_isRelevantForCongaUpdate(Ammendment__c newAmendment) {
        return newAmendment.Amendment_Start__c != null
                || newAmendment.Amendment_End__c != null;
    }

    private static Boolean ccs_isRelevantChangeForCongaUpdate(Ammendment__c oldAmendment, Ammendment__c newAmendment) {
        return newAmendment.Amendment_Start__c != oldAmendment.Amendment_Start__c
                || newAmendment.Amendment_End__c != oldAmendment.Amendment_End__c;
    }

    public void ccs_buildDataModelForCongaUpdate() {
        for (Contract__c contractItem : contractMap.values()) {
            if (contractItem.Last_Amentment__c != null
                    && ccs_relevantAmendmentIds.contains(contractItem.Last_Amentment__c)) {
                ccs_amendmentIdToContracts.addToMap(contractItem.Last_Amentment__c, contractItem);
            }
        }
    }

    public void ccs_updateContractsCongaFieldsIfNecessary_Insert(Ammendment__c newAmendment) {
        if (ccs_isRelevantForCongaUpdate(newAmendment)) {
            List<Contract__c> contractsToUpdate = ccs_amendmentIdToContracts.get(newAmendment.Id);
            for (Contract__c contractItem : contractsToUpdate) {
                ccs_calculateContractUpdate(contractItem);
            }
        }
    }

    public void ccs_updateContractsCongaFieldsIfNecessary_Update(Ammendment__c oldAmendment, Ammendment__c newAmendment) {
        if (ccs_isRelevantForCongaUpdate(newAmendment) && ccs_isRelevantChangeForCongaUpdate(oldAmendment, newAmendment)) {
            List<Contract__c> contractsToUpdate = ccs_amendmentIdToContracts.get(newAmendment.Id);
            for (Contract__c contractItem : contractsToUpdate) {
                ccs_calculateContractUpdate(contractItem);
            }
        }
    }

    private void ccs_calculateContractUpdate(Contract__c contractToUpdate) {
        Contract__c result = BatchResetContractCongaContext.determineCongaContext(contractToUpdate);
        if (result != null) {
            contractUpdateMap.put(contractToUpdate.Id, contractToUpdate);
        }
    }

    public void ccs_updateContractsCongaFieldsIfNecessary_Delete(Ammendment__c newAmendment) {
        if (ccs_isRelevantForCongaUpdate(newAmendment)) {
            List<Contract__c> contractsToUpdate = ccs_amendmentIdToContracts.get(newAmendment.Id);
            for (Contract__c contractItem : contractsToUpdate) {
                contractItem.Last_Amentment__r = null;
                contractItem.Last_Amentment__c = null;
                ccs_calculateContractUpdate(contractItem);
            }
        }
    }

    //Naming Pattern methods
    public void anp_identifyRecordsToLoad() {
        for (Ammendment__c newAmendment : triggerNew) {
            anp_baseContractIds.add(newAmendment.Base_Contract__c);
        }
    }

    public void anp_identifyRecordsToLoad_update() {
        for (Ammendment__c newAmendment : triggerNew) {
            if (anp_isRelevantlyChanged(oldMap.get(newAmendment.Id), newAmendment)) {
                anp_baseContractIds.add(newAmendment.Base_Contract__c);
            }
        }
    }

    private Boolean anp_isRelevantlyChanged(Ammendment__c oldAmendment, Ammendment__c newAmendment) {
        return newAmendment.Name == 'Reinitialize'
                || oldAmendment.Amendment_Start__c != newAmendment.Amendment_Start__c
                || oldAmendment.Amendment_End__c != newAmendment.Amendment_End__c
                || oldAmendment.Base_Contract__c != newAmendment.Base_Contract__c
                || oldAmendment.Amendment_Type__c != newAmendment.Amendment_Type__c;
    }

    public void anp_nameAmendment(Ammendment__c newAmendment) {
        String workflowType = newAmendment.Amendment_Type__c;
        String contractName = contractMap.get(newAmendment.Base_Contract__c).Name;
        String startDate = msLepton.format(newAmendment.Amendment_Start__c, DATE_FORMAT_STRING);
        String endDate = msLepton.format(newAmendment.Amendment_End__c, DATE_FORMAT_STRING);
        newAmendment.Name = workflowType + ' - ' + contractName + ' - ' + startDate + ' - ' + endDate;
    }

    public void anp_checkIfNeedToRenameAmendment(Ammendment__c oldAmendment, Ammendment__c newAmendment) {
        if (anp_isRelevantlyChanged(oldAmendment, newAmendment)) {
            anp_nameAmendment(newAmendment);
        }
    }
}