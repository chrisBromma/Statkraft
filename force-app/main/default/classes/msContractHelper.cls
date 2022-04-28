/****************************************************************************************************
 * Class msContractHelper
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

public without sharing class msContractHelper {
    //Set this to a different Date if the Test Context requires it

    private Date today = Date.today();
    private List<Contract__c> triggerOld;
    private List<Contract__c> triggerNew;
    private Map<Id, Contract__c> oldMap;
    private Map<Id, Contract__c> newMap;

    // Glossary for the ccv_checkValidation
    public static Map<String, String> glossary = new Map<String, String>();
    static{
        glossary.put(' ', '_');
        glossary.put('-', '_');
        glossary.put('!', '_');
        glossary.put('\'', '_');
        glossary.put('(', '_');
        glossary.put(')', '_');
        glossary.put('___', '_');
        glossary.put('__', '_');
    }


    public msContractHelper(
            List<Contract__c> oldList,
            List<Contract__c> newList,
            Map<Id, Contract__c> mapOld,
            Map<Id, Contract__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
        can_contractIdStart.put('France', 100000);
        can_contractIdIncrement.put('France', 10);
    }

    //Global and Static Variables
    public static final Id PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;
    private static final List<Custom_Validation_Passes__mdt> CURRENT_USER_VALIDATION_PASSES = msUtility.getValidationPasses();

    //SOQL Maps
    private Map<Id, Account> accountMap = new Map<Id, Account>();
    private Map<Id, Ammendment__c> amendmentMap = new Map<Id, Ammendment__c>();
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();

    //DML Lists/Maps
    public List<Case> casesToInsert = new List<Case>();
    public Map<Id, Ammendment__c> amendmentsToUpdate = new Map<Id, Ammendment__c>();

    //Conga Independent Timescale Variables
    private Set<Id> cit_amendmentIds = new Set<Id>();

    //Remit Case Contract Holder Change Variables
    private Set<Id> rcc_ContractHolderIds = new Set<Id>();

    //Amendment Naming Pattern variables
    private Set<Id> anp_contractIds = new Set<Id>();
    private ListMapContainer anp_contractIdToAmendments = new ListMapContainer(Ammendment__c.SObjectType);

    //Contract Auto Numbering variables
    private Map<String, Integer> can_contractIdStart = new Map<String, Integer>();
    private Map<String, Integer> can_contractIdIncrement = new Map<String, Integer>();
    private Set<String> can_affectedCountries = new Set<String>();

    //SOQL methods
    public void load_Accounts() {
        if (!rcc_ContractHolderIds.isEmpty()) {
            accountMap = new Map<Id, Account>([SELECT Name FROM Account WHERE Id IN :rcc_ContractHolderIds]);
        }
    }

    public void load_Amendments() {
        if (!cit_amendmentIds.isEmpty() || !anp_contractIds.isEmpty()) {
            amendmentMap = new Map<Id, Ammendment__c>([
                    SELECT Id, Amendment_Start__c, Amendment_End__c, Name, Base_Contract__c, Status__c
                    FROM Ammendment__c
                    WHERE Id IN :cit_amendmentIds OR Base_Contract__c IN :anp_contractIds
            ]);
        }
    }

    public void load_Contracts() {
        if (!can_affectedCountries.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Statkraft_Contract_ID__c, Country__c
                    FROM Contract__c
                    WHERE Statkraft_Contract_ID__c != NULL AND Country__c IN :can_affectedCountries
            ]);
        }
    }

    //Conga Relevancy Methods
    public void cit_identifyCongaRelevancyOfAmendments_Insert() {
        for (Contract__c newContract : triggerNew) {
            if (newContract.Last_Amentment__c != null) {
                cit_amendmentIds.add(newContract.Last_Amentment__c);
            }
        }
    }
    public void cit_identifyCongaRelevancyOfAmendments_Update() {
        for (Contract__c newContract : triggerNew) {
            if (newContract.Last_Amentment__c != null
                    && newContract.Last_Amentment__c != oldMap.get(newContract.Id).Last_Amentment__c) {
                cit_amendmentIds.add(newContract.Last_Amentment__c);
            }
        }
    }

    public void cit_setCongaContext_Insert(Contract__c newContract) {
        if (newContract.Last_Amentment__c != null) {
            newContract.Last_Amentment__r = amendmentMap.get(newContract.Last_Amentment__c);
        }
        BatchResetContractCongaContext.determineCongaContext(newContract);
    }

    public void cit_setCongaContext_Update(Contract__c oldContract, Contract__c newContract) {
        if (newContract.Last_Amentment__c != null) {
            newContract.Last_Amentment__r = amendmentMap.get(newContract.Last_Amentment__c);
        }
        if (oldContract.Last_Amentment__c != newContract.Last_Amentment__c
                || oldContract.Start_Date__c != newContract.Start_Date__c
                || oldContract.End_Date__c != newContract.End_Date__c) {
            BatchResetContractCongaContext.determineCongaContext(newContract);
        }
    }

    // Custom Contract Validation
    public void ccv_InsertValidation(Contract__c newContract) {
        if (newContract.Product_Type_New__c != null) {
            if (!ccv_checkValidation(newContract)) {
                newContract.addError(Label.msContractTypeAndProductTypeValidationError);
            }
        }
    }

    public void ccv_UpdateValidation(Contract__c oldContract, Contract__c newContract) {
        if (oldContract.Contract_Type_New__c != newContract.Contract_Type_New__c
                || oldContract.Product_Type_New__c != newContract.Product_Type_New__c) {
            if (!ccv_checkValidation(newContract)) {
                newContract.addError(Label.msContractTypeAndProductTypeValidationError);
            }
        }
    }

    private Boolean oldccv_checkValidation(Contract__c contractToCheck) {
        Boolean result = false;
        if (!CURRENT_USER_VALIDATION_PASSES.isEmpty()) {
            Custom_Validation_Passes__mdt passes = CURRENT_USER_VALIDATION_PASSES[0];
            if (passes.Global_Validation_Pass__c) {
                result = true;
            } else {
                List<String> validProductTypes = new List<String>();
                switch on contractToCheck.Contract_Type_New__c {
                    when 'CfD' {
                        validProductTypes = passes.CfD_Product_Types__c.split(';');
                    }
                    when 'Feed in Tariff PPA' {
                        validProductTypes = passes.Feed_in_Tariff_Product_Types__c.split(';');
                    }
                    when 'Framework Agreement' {
                        validProductTypes = passes.Framework_Agreement_Product_Types__c.split(';');
                    }
                    when 'Merchant PPA' {
                        validProductTypes = passes.Merchant_PPA_Product_Types__c.split(';');
                    }
                    when 'Sub-Contract' {
                        validProductTypes = passes.Sub_Contract_Product_Types__c.split(';');
                    }
                    when 'Supply' {
                        validProductTypes = passes.Supply_Product_Types__c.split(';');
                    }
                    when 'Certificates' {
                        validProductTypes = passes.Certificates_Product_Types__c.split(';');
                    }
                    when else {
                    }
                }
                if (validProductTypes.contains(contractToCheck.Product_Type_New__c)) {
                    result = true;
                }
            }
        }
        return result;
    }

    //Only allow special product types for selected contract type
    public static Boolean ccv_checkValidation(Contract__c contractToCheck) {
        Boolean result = false;
        if (!CURRENT_USER_VALIDATION_PASSES.isEmpty()) {
            Custom_Validation_Passes__mdt passes = CURRENT_USER_VALIDATION_PASSES[0];
            String typeAsAPIName = '';
            if (passes.Global_Validation_Pass__c) {
                result = true;
            } else {
                List<String> validProductTypes = new List<String>();
    
                //Parser: Changes the field label names to an API name. It parses over a glossar
                typeAsAPIName = contractToCheck.Contract_Type_New__c.normalizeSpace();
                for (String placeholder : glossary.keySet()) {
                    typeAsAPIName = typeAsAPIName.replace(placeholder, glossary.get(placeholder));
                }
                if(typeAsAPIName.endsWith('_')){
                    typeAsAPIName = typeAsAPIName + 'Product_Types__c';
                }else {
                    typeAsAPIName = typeAsAPIName + '_Product_Types__c';
                }
    
                //split the values by ; to get all possible product types
                String values = (String)passes.get(typeAsAPIName);
                validProductTypes = values.split(';');
    
                if (validProductTypes.contains(contractToCheck.Product_Type_New__c)) {
                    result = true;
                }
            }
        }
        return result;
    }

    //Contract Auto Numbering Variables
    public void can_identifyCountriesForHighestNumber() {
        for (Contract__c newContract : triggerNew) {
            if (can_contractNeedsId(newContract)) {
                can_affectedCountries.add(newContract.Country__c);
            }
        }
    }

    public void can_assignHighestNumbersForCountries() {
        if (!can_affectedCountries.isEmpty()) {
            for (Contract__c contractItem : contractMap.values()) {
                if (contractItem.Country__c != null
                        && can_affectedCountries.contains(contractItem.Country__c)
                        && contractItem.Statkraft_Contract_ID__c.isNumeric()) {
                    Integer maxContractIdForThisCountry = can_contractIdStart.get(contractItem.Country__c);
                    Integer thisContractsId = Integer.valueOf(contractItem.Statkraft_Contract_ID__c);
                    Integer comparedId = Math.max(maxContractIdForThisCountry, thisContractsId);
                    if (comparedId != maxContractIdForThisCountry) {
                        can_contractIdStart.put(contractItem.Country__c, comparedId);
                    }
                }
            }
        }
    }

    public void can_assignContractIdIfNecessary(Contract__c newContract) {
        if (can_contractNeedsId(newContract)) {
            String country = newContract.Country__c;
            Integer newMax = can_contractIdStart.get(country) + can_contractIdIncrement.get(country);
            can_contractIdStart.put(country, newMax);
            newContract.Statkraft_Contract_ID__c = String.valueOf(newMax);
        }
    }

    private Boolean can_contractNeedsId(Contract__c newContract) {
        return newContract.Country__c != null
                && can_contractIdStart.keySet().contains(newContract.Country__c)
                && newContract.Statkraft_Contract_ID__c == null;
    }

    //contract expiration logic
    public void cel_setStatusForExpiredContracts(Contract__c contract) {
        if (contract.End_Date__c < today && contract.Status__c == 'Active') {
            contract.Status__c = 'Expired';
        }
    }

    //Global Portal Market methods
    public void gpm_determineMarket_Insert(Contract__c contract) {
        gpm_determineMarketForContract(contract);
    }
    public void gpm_determineMarket_Update(Contract__c oldContract, Contract__c newContract) {
        if (gpm_isMarketRelevantChange(oldContract, newContract)) {
            gpm_determineMarketForContract(newContract);
        }
    }

    private void gpm_determineMarketForContract(Contract__c contract) {
        contract.Global_Portal_Market__c = msUtility.determineMarket(contract);
    }

    private Boolean gpm_isMarketRelevantChange(Contract__c oldContract, Contract__c newContract) {
        return newContract.Global_Portal_Market__c == null
                || oldContract.RecordTypeId != newContract.RecordTypeId
                || oldContract.Contract_Type__c != newContract.Contract_Type__c
                || oldContract.Country__c != newContract.Country__c
                || oldContract.Contract_Type_New__c != newContract.Contract_Type_New__c
                || oldContract.Product_Type_New__c != newContract.Product_Type_New__c;
    }

    //Remit Case for Termination methods
    public void rct_generateTerminationCasesIfNecessary_Update(Contract__c oldContract, Contract__c newContract) {
        if (rct_relevantContract(newContract) && rct_relevantUpdate(oldContract, newContract)) {
            Map<String, Object> flowParameters = new Map<String, Object>();
            flowParameters.put('Case_Type', 'REMIT_Termination_Case');
            flowParameters.put('InputContract', newContract);
            Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
            caseFactory.start();
            Case remitTerminationCase = (Case) caseFactory.getVariableValue('OutputCase');
            remitTerminationCase.Description +=
                    '\nOld Contract End Date: ' +
                            oldContract.End_Date__c +
                            '\nNew Contract End Date: ' +
                            newContract.End_Date__c;
            casesToInsert.add(remitTerminationCase);
        }
    }

    private Boolean rct_relevantContract(Contract__c newContract) {
        return newContract.Country__c == 'Germany'
                && (newContract.Contract_Type_New__c == 'Merchant PPA'
                || newContract.Contract_Type_New__c == 'Feed in Tariff PPA')
                && newContract.REMIT_Reporting_Relevant__c
                && newContract.Status__c == 'Active'
                && newContract.Contract_Date__c != null
                && (newContract.Termination_Status__c == 'Terminated by customer'
                || newContract.Termination_Status__c == 'Terminated by Statkraft');
    }

    private Boolean rct_relevantUpdate(Contract__c oldContract, Contract__c newContract) {
        return oldContract.End_Date__c > newContract.End_Date__c;
    }

    //REMIT Case for Delegated Reporting Change methods
    public void rcd_generateDelegateReportingCaseIfNecessary_Update(Contract__c oldContract, Contract__c newContract) {
        if (rcd_relevantContract(newContract) && rcd_relevantUpdate(oldContract, newContract)) {
            Map<String, Object> flowParameters = new Map<String, Object>();
            flowParameters.put('Case_Type', 'REMIT_Delegated_Reporting_Change_Case');
            flowParameters.put('InputContract', newContract);
            Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
            caseFactory.start();
            Case delegatedReportingChangeCase = (Case) caseFactory.getVariableValue('OutputCase');
            delegatedReportingChangeCase.Description +=
                    '\nOld Delegated Reporting was: ' +
                            oldContract.REMIT_delegated_reporting__c +
                            '\nNew Delegated Reporting was set to: ' +
                            newContract.REMIT_delegated_reporting__c;
            casesToInsert.add(delegatedReportingChangeCase);
        }
    }

    private Boolean rcd_relevantContract(Contract__c newContract) {
        return (newContract.Country__c == 'France'
                || newContract.Country__c == 'Germany'
                || newContract.Country__c == 'Ireland'
                || newContract.Country__c == 'United Kingdom')
                && newContract.RecordTypeId == PPA_CONTRACT_RECORD_TYPE
                && (newContract.Contract_Type_New__c == 'Merchant PPA'
                || newContract.Contract_Type_New__c == 'Feed in Tariff PPA')
                && newContract.Product_Type_New__c != 'Flex Optimization GB'
                && newContract.Product_Type_New__c != 'Flex Optimization IRE'
                && newContract.Product_Type_New__c != 'Flex Optimization NI'
                && newContract.REMIT_Reporting_Relevant__c
                && newContract.Status__c == 'Active'
                && newContract.Contract_Date__c != null;
    }

    private Boolean rcd_relevantUpdate(Contract__c oldContract, Contract__c newContract) {
        return oldContract.REMIT_delegated_reporting__c != newContract.REMIT_delegated_reporting__c;
    }

    //REMIT Case for Agreement Date Change methods
    public void rca_generateAgreementDateChangeCaseIfNecessary_Update(
            Contract__c oldContract,
            Contract__c newContract
    ) {
        if (rca_relevantContract(newContract) && rca_relevantUpdate(oldContract, newContract)) {
            Map<String, Object> flowParameters = new Map<String, Object>();
            flowParameters.put('Case_Type', 'REMIT_Manual_Amendment_Case');
            flowParameters.put('InputContract', newContract);
            Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
            caseFactory.start();
            Case remitAgreementDateChangeCase = (Case) caseFactory.getVariableValue('OutputCase');
            remitAgreementDateChangeCase.Description +=
                    '\nOld REMIT Agreement Date was: ' +
                            oldContract.REMIT_Agreement_Date__c +
                            '\nNew REMIT Agreement Date was set to: ' +
                            newContract.REMIT_Agreement_Date__c;
            casesToInsert.add(remitAgreementDateChangeCase);
        }
    }

    private Boolean rca_relevantContract(Contract__c newContract) {
        return (newContract.Country__c == 'France'
                || newContract.Country__c == 'Germany'
                || newContract.Country__c == 'Ireland')
                && newContract.RecordTypeId == PPA_CONTRACT_RECORD_TYPE
                && (newContract.Contract_Type_New__c == 'Merchant PPA'
                || newContract.Contract_Type_New__c == 'Feed in Tariff PPA')
                && newContract.REMIT_Reporting_Relevant__c
                && newContract.Status__c == 'Active'
                && newContract.Contract_Date__c != null;
    }

    private Boolean rca_relevantUpdate(Contract__c oldContract, Contract__c newContract) {
        return oldContract.REMIT_Agreement_Date__c != newContract.REMIT_Agreement_Date__c;
    }

    //REMIT Case for Contract Holder Account change
    public void rcc_identifyContractHolderAccounts() {
        for (Contract__c newContract : triggerNew) {
            Contract__c oldContract = oldMap.get(newContract.Id);
            if (rcc_relevantUpdate(oldContract, newContract)) {
                if (oldContract.Contract_Holder__c != null) {
                    rcc_ContractHolderIds.add(oldContract.Contract_Holder__c);
                }
                if (newContract.Contract_Holder__c != null) {
                    rcc_ContractHolderIds.add(newContract.Contract_Holder__c);
                }
            }
        }
    }

    public void rcc_generateContractHolderChangeCaseIfNecessary_Update(
            Contract__c oldContract,
            Contract__c newContract
    ) {
        if (rcc_relevantContract(newContract) && rcc_relevantUpdate(oldContract, newContract)) {
            Map<String, Object> flowParameters = new Map<String, Object>();
            flowParameters.put('Case_Type', 'REMIT_Contract_Holder_Change_Case');
            flowParameters.put('InputContract', newContract);
            Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
            caseFactory.start();
            Case remitContractHolderChangeCase = (Case) caseFactory.getVariableValue('OutputCase');
            remitContractHolderChangeCase.Description += '\nOld Contract Holder was: ';
            if (oldContract.Contract_Holder__c == null) {
                remitContractHolderChangeCase.Description += 'Empty';
            } else {
                remitContractHolderChangeCase.Description +=
                        oldContract.Contract_Holder__r.Name +
                                ': ' +
                                System.Url.getSalesforceBaseUrl().toExternalForm() +
                                '/' +
                                oldContract.Contract_Holder__c;
            }
            remitContractHolderChangeCase.Description += '\nNew Contract Holder is: ';
            if (newContract.Contract_Holder__c == null) {
                remitContractHolderChangeCase.Description += 'Empty';
            } else {
                remitContractHolderChangeCase.Description +=
                        newContract.Contract_Holder__r.Name +
                                ': ' +
                                System.Url.getSalesforceBaseUrl().toExternalForm() +
                                '/' +
                                newContract.Contract_Holder__c;
            }
            casesToInsert.add(remitContractHolderChangeCase);
        }
    }

    private Boolean rcc_relevantContract(Contract__c newContract) {
        return (newContract.Country__c == 'France'
                || newContract.Country__c == 'Germany'
                || newContract.Country__c == 'Ireland'
                || newContract.Country__c == 'United Kingdom')
                && newContract.RecordTypeId == PPA_CONTRACT_RECORD_TYPE
                && (newContract.Contract_Type_New__c == 'Merchant PPA'
                || newContract.Contract_Type_New__c == 'Feed in Tariff PPA')
                && newContract.Product_Type_New__c != 'Flex Optimization GB'
                && newContract.Product_Type_New__c != 'Flex Optimization IRE'
                && newContract.Product_Type_New__c != 'Flex Optimization NI'
                && newContract.REMIT_Reporting_Relevant__c
                && newContract.Status__c == 'Active'
                && newContract.Contract_Date__c != null;
    }

    private Boolean rcc_relevantUpdate(Contract__c oldContract, Contract__c newContract) {
        return oldContract.Contract_Holder__c != newContract.Contract_Holder__c;
    }

    //Amendment Naming Pattern logic
    private Boolean anp_contractNeedsToUpdateAmendments(Contract__c oldContract, Contract__c newContract) {
        return oldContract.Name != newContract.Name;
    }

    public void anp_identifyContractIds() {
        for (Contract__c newContract : triggerNew) {
            if (anp_contractNeedsToUpdateAmendments(oldMap.get(newContract.Id), newContract)) {
                anp_contractIds.add(newContract.Id);
            }
        }
    }

    public void anp_builtDataModel() {
        if (!anp_contractIds.isEmpty()) {
            for (Ammendment__c amendment : amendmentMap.values()) {
                if (anp_contractIds.contains(amendment.Base_Contract__c)) {
                    anp_contractIdToAmendments.addToMap(amendment.Base_Contract__c, amendment);
                }
            }
        }
    }

    public void anp_renameAmendmentsIfNecessary(Contract__c oldContract, Contract__c newContract) {
        if (anp_contractNeedsToUpdateAmendments(oldContract, newContract)) {
            List<Ammendment__c> amendmentsToRename = anp_contractIdToAmendments.get(newContract.Id);
            for (Ammendment__c amendmentToRename : amendmentsToRename) {
                amendmentToRename.Name = 'Reinitialize';
                amendmentsToUpdate.put(amendmentToRename.Id, amendmentToRename);
            }
        }
    }
}