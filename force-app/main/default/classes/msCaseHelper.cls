/****************************************************************************************************
* Class msCaseHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-30
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-30       	Init version.
*****************************************************************************************************/

public with sharing class msCaseHelper {
    //Trigger Maps/Lists
    private List<Case> triggerOld;
    private List<Case> triggerNew;
    private Map<Id, Case> oldMap;
    private Map<Id, Case> newMap;

    public msCaseHelper(
            List<Case> oldList,
            List<Case> newList,
            Map<Id, Case> mapOld,
            Map<Id, Case> mapNew) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //SOQL Maps from bulk. Important: Only ever use one Map per SObject Type!
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Case> caseMap = new Map<Id, Case>();

    //DML Lists and Maps. Important only ever use one Map/List per SObject Type and DML operation!
    public Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();

    //General Statics
    public static final String PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;
    public static final String GUARANTEE_AMENDMENT_REQUEST =
            Application.RecordTypes.byDeveloperName('Case', 'Guarantee_Amendment_Request').Id;

    //Case Status Update automation variables
    private Map<Id, ListMapContainer> csu_contractIdToCasesListForStatusUpdate = new Map<Id, ListMapContainer>();
    private Map<Id, Contract__c> csu_allRelevantContractsToUpdate = new Map<Id, Contract__c>();
    private Set<Id> csu_contractIdsToCheckMeterRegCases = new Set<Id>();
    private ListMapContainer csu_contractIdToMeterRegCases = new ListMapContainer(Case.SObjectType);


    //SOQL Methods
    public void load_Contracts() {
        if (!csu_contractIdsToCheckMeterRegCases.isEmpty()
                || !csu_contractIdToCasesListForStatusUpdate.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Id, Country__c, Workflow_Type__c, RecordTypeId
                    FROM Contract__c
                    WHERE (Id IN :csu_contractIdToCasesListForStatusUpdate.keySet()
                    OR Id IN :csu_contractIdsToCheckMeterRegCases)
                    AND Country__c = 'Germany'
                    AND (Workflow_Type__c = 'New'
                    OR Workflow_Type__c = 'Reactivation')
                    AND RecordTypeId = :PPA_CONTRACT_RECORD_TYPE
            ]);
        }
    }

    public void load_Cases() {
        if (!csu_contractIdsToCheckMeterRegCases.isEmpty()) {
            caseMap = new Map<Id, Case>([
                    SELECT Id, Reason, Status, Contract__c, Contract__r.Country__c, Contract__r.Workflow_Type__c, Contract__r.RecordTypeId
                    FROM Case
                    WHERE Contract__c IN :csu_contractIdsToCheckMeterRegCases
                    AND Contract__r.Country__c = 'Germany'
                    AND (Contract__r.Workflow_Type__c = 'New'
                    OR Contract__r.Workflow_Type__c = 'Reactivation')
                    AND Contract__r.RecordTypeId = :PPA_CONTRACT_RECORD_TYPE
                    AND Reason LIKE '%Meter Registration%'
                    AND (Status = 'New'
                    OR Status = 'In Progress'
                    OR Status = 'Closed (Passed)')
            ]);
        }
    }


    //Contract Status Update automation Methods
    public void csu_identifyCasesForUpdates_Insert() {
        for (Case newCase : triggerNew) {
            if (csu_caseIsRelevant(newCase)) {
                csu_sortCase(newCase);
            }
        }
    }

    public void csu_identifyCasesForUpdates_Update() {
        for (Case newCase : triggerNew) {
            if (csu_caseIsRelevant(newCase)
                    && csu_caseHasRelevantChange(oldMap.get(newCase.Id), newCase)) {
                csu_sortCase(newCase);
            }
        }
    }

    public void csu_buildDataModelGeneralCases() {
        if(!csu_contractIdsToCheckMeterRegCases.isEmpty()
                || !csu_contractIdToCasesListForStatusUpdate.isEmpty()) {
            for (Contract__c contractToSort : contractMap.values()) {
                if ((csu_contractIdsToCheckMeterRegCases.contains(contractToSort.Id)
                        || csu_contractIdToCasesListForStatusUpdate.containsKey(contractToSort.Id))
                        && contractToSort.Country__c == 'Germany'
                        && (contractToSort.Workflow_Type__c == 'New'
                        || contractToSort.Workflow_Type__c == 'Reactivation')
                        && contractToSort.RecordTypeId == PPA_CONTRACT_RECORD_TYPE) {
                    csu_allRelevantContractsToUpdate.put(contractToSort.Id, contractToSort);
                }
            }
        }
    }

    public void csu_buildDataModelMeterRegCases() {
        if (!csu_contractIdsToCheckMeterRegCases.isEmpty()) {
            for (Case caseToSort : caseMap.values()) {
                if (csu_isRelevantMeterRegCase(caseToSort)) {
                    csu_addCaseToMap(caseToSort, 'Meter Registration');
                }
            }
        }
    }

    public void csu_updateContractIfMeterRegCase_Insert(Case newCase) {
        if (csu_caseIsRelevant(newCase)
                && csu_caseIsMeterStatusUpdateRelevant(newCase)) {
            csu_calculateMeterRegStatusUpdateOnContract(newCase);
        }
    }

    public void csu_updateContractIfMeterRegCase_Update(Case oldCase, Case newCase) {
        if (csu_caseIsRelevant(newCase)
                && csu_caseHasRelevantChange(oldCase, newCase)
                && csu_caseIsMeterStatusUpdateRelevant(newCase)) {
            csu_calculateMeterRegStatusUpdateOnContract(newCase);
        }
    }


    public void csu_updateContractIfCaseRelevant_Insert(Case newCase) {
        if (csu_caseIsRelevant(newCase)
                && csu_contractIdToCasesListForStatusUpdate.containsKey(newCase.Contract__c)
                && csu_allRelevantContractsToUpdate.containsKey(newCase.Contract__c)) {
            csu_calculateGeneralStatusUpdateOnContract(newCase);
        }
    }

    public void csu_updateContractIfCaseRelevant_Update(Case oldCase, Case newCase) {
        if (csu_caseIsRelevant(newCase)
                && csu_caseHasRelevantChange(oldCase, newCase)
                && csu_contractIdToCasesListForStatusUpdate.containsKey(newCase.Contract__c)
                && csu_allRelevantContractsToUpdate.containsKey(newCase.Contract__c)) {
            csu_calculateGeneralStatusUpdateOnContract(newCase);
        }
    }

    private void csu_calculateGeneralStatusUpdateOnContract(Case newCase) {
        Contract__c contractToUpdate = csu_allRelevantContractsToUpdate.get(newCase.Contract__c);
        Boolean matched = false;
        if (newCase.Reason.contains('CIS Handling')) {
            contractToUpdate.CIS_File_Status__c =
                    Datetime.now().format('dd.MM.yyyy', '') + ' - ' + newCase.Status;
            matched = true;
        } else if (newCase.Reason.contains('Security Handling')) {
            contractToUpdate.Security_Issuance_Status__c =
                    Datetime.now().format('dd.MM.yyyy', '') + ' - ' + newCase.Status;
            matched = true;
        } else if (newCase.Reason.contains('Remote Control Handling')) {
            contractToUpdate.Remote_Control_Status__c =
                    Datetime.now().format('dd.MM.yyyy', '') + ' - ' + newCase.Status;
            matched = true;
        } else if (newCase.Reason.contains('SAP Setup')) {
            contractToUpdate.SAP_Masterdata_Status__c =
                    Datetime.now().format('dd.MM.yyyy', '') + ' - ' + newCase.Status;
            matched = true;
        } else if (newCase.Reason.contains('Portal user registration')) {
            contractToUpdate.Customer_Portal_User_Setup_Status__c =
                    Datetime.now().format('dd.MM.yyyy', '') + ' - ' + newCase.Status;
            matched = true;
        }
        if (matched) {
            contractUpdateMap.put(contractToUpdate.Id, contractToUpdate);
        }
    }

    private void csu_calculateMeterRegStatusUpdateOnContract(Case newCase) {
        String lowestStatus = 'N/A'; //Closed (Failed) are being ignored here
        List<Case> connectedMeterRegCasesToCompare = csu_contractIdToCasesListForStatusUpdate.get(newCase.Contract__c).get('Meter Registration');
        for (Case meterRegCase : connectedMeterRegCasesToCompare) {
            switch on meterRegCase.Status {
                when 'New' {
                    lowestStatus = 'New';
                }
                when 'In Progress' {
                    if (lowestStatus != 'New') {
                        lowestStatus = 'In Progress';
                    }
                }
                when 'Closed (Passed)' {
                    if (lowestStatus != 'New' && lowestStatus != 'In Progress') {
                        lowestStatus = 'Closed (Passed)';
                    }
                }
                when 'Closed (Not Relevant)' {
                    if (lowestStatus != 'New' && lowestStatus != 'In Progress' && lowestStatus != 'Closed (Passed)') {
                        lowestStatus = 'Closed (Not Relevant)';
                    }
                }
            }
        }
        Contract__c contractToUpdate = csu_allRelevantContractsToUpdate.get(newCase.Contract__c);
        contractToUpdate.Meter_Registration_Requested__c =
                Datetime.now().format('dd.MM.yyyy', '') + ' - ' + lowestStatus;
        contractUpdateMap.put(contractToUpdate.Id, contractToUpdate);
    }

    private Boolean csu_caseIsMeterStatusUpdateRelevant(Case newCase) {
        return newCase.Contract__c != null
                && csu_allRelevantContractsToUpdate.containsKey(newCase.Contract__c)
                && csu_contractIdToCasesListForStatusUpdate.get(newCase.Contract__c) != null
                && csu_contractIdToCasesListForStatusUpdate.get(newCase.Contract__c).get('Meter Registration') != null
                && !csu_contractIdToCasesListForStatusUpdate.get(newCase.Contract__c).get('Meter Registration').isEmpty();
    }

    private Boolean csu_caseIsRelevant(Case caseToCheck) {
        return caseToCheck.Contract__c != null && caseToCheck.Reason != null;
    }

    private Boolean csu_caseHasRelevantChange(Case oldCase, Case newCase) {
        return newCase.Status != oldCase.Status;
    }

    private void csu_sortCase(Case caseToSort) {
        if (caseToSort.Reason.contains('CIS Handling')) {
            csu_addCaseToMap(caseToSort, 'CIS Handling');
        } else if (caseToSort.Reason.contains('Security Handling')) {
            csu_addCaseToMap(caseToSort, 'Security Handling');
        } else if (caseToSort.Reason.contains('Remote Control Handling')) {
            csu_addCaseToMap(caseToSort, 'Remote Control Handling');
        } else if (caseToSort.Reason.contains('SAP Setup')) {
            csu_addCaseToMap(caseToSort, 'SAP Setup');
        } else if (caseToSort.Reason.contains('Portal user registration')) {
            csu_addCaseToMap(caseToSort, 'Portal user registration');
        } else if (caseToSort.Reason.contains('Meter Registration')) {
            csu_contractIdsToCheckMeterRegCases.add(caseToSort.Contract__c);
        }
    }

    private void csu_addCaseToMap(Case newCase, String keyword) {
        msLepton.addToMap(newCase.Contract__c, keyword, newCase, csu_contractIdToCasesListForStatusUpdate);
    }

    private Boolean csu_isRelevantMeterRegCase(Case caseToSort) {
        return csu_contractIdsToCheckMeterRegCases.contains(caseToSort.Contract__c)
                && caseToSort.Contract__r.Country__c == 'Germany'
                && (caseToSort.Contract__r.Workflow_Type__c == 'New'
                || caseToSort.Contract__r.Workflow_Type__c == 'Reactivation')
                && caseToSort.Contract__r.RecordTypeId == PPA_CONTRACT_RECORD_TYPE
                && caseToSort.Reason.contains('Meter Registration')
                && (caseToSort.Status == 'New'
                || caseToSort.Status == 'In Progress'
                || caseToSort.Status == 'Closed (Passed)');
    }
}