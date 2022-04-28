/****************************************************************************************************
* Class msBatchContractExtension
*
*   Create By	:   ChristianGottlieb (mindsquare AG)
*   Create Date	:   2020-10-16
*   Description	:	TODO: Class currently does not run in the Scheduler Framework, since a Screen Flow executes it,
 *                  This needs to be amended once a Framework solution has been found for this.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-10-16       	Init version.
*****************************************************************************************************/

global without sharing class msBatchContractExtension implements Database.Batchable<SObject>, Database.Stateful {
    private static final Id BATCH_JOB_LOG_PARENT_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Batch_Job_Log__c', 'Batch_Parent_Log').Id;
    private static final Id BATCH_JOB_LOG_CHILD_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Batch_Job_Log__c', 'Batch_Child_Log').Id;
    private static final Id OFFER_PPA_EXTENSION_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Extension').Id;

    private Set<Id> TOTAL_BATCH_SCOPE = new Set<Id>();
    private Integer TOTAL_CONTRACTS = 0;
    private Integer SUCCESS_CONTRACTS = 0;
    private Integer FAILED_CONTRACTS = 0;
    private Integer TOTAL_PCS = 0;
    private Integer SUCCESS_PCS = 0;
    private Integer FAILED_PCS = 0;
    private Integer TOTAL_CASES = 0;
    private Integer SUCCESS_CASES = 0;
    private Integer FAILED_CASES = 0;
    private String RESULT_STATUS = 'Completed';
    private Integer NUMBER_OF_FAILED_BATCHES = 0;

    private Id PARENT_LOG_ID;

    global msBatchContractExtension(Set<Id> contractIds) {
        TOTAL_BATCH_SCOPE.addAll(contractIds);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Batch_Job_Log__c parentLog = new Batch_Job_Log__c(
                Manual_Apex_Batch_Job__c = true,
                Batch_Job_Name__c = 'msBatchContractExtension',
                ClassName__c = 'msBatchContractExtension',
                RecordTypeId = BATCH_JOB_LOG_PARENT_REC_TYPE_ID);
        insert parentLog;
        PARENT_LOG_ID = parentLog.Id;

        return Database.getQueryLocator('SELECT Id, End_Date__c,Originator__c, Contract_Holder__c, ' +
                'REMIT_Reporting_Relevant__c, Country__c, REMIT_Contract_ID__c, ID_18_Digit__c ' +
                'FROM Contract__c ' +
                'WHERE Id IN :TOTAL_BATCH_SCOPE');
    }

    global void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        Integer localErrors = 0;
        TOTAL_CONTRACTS += scope.size();

        Set<Id> contractHolderIds = new Set<Id>();
        Map<Id, Contract__c> scopeMap = new Map<Id, Contract__c>(scope);
        for (Contract__c contractItem : scope) {
            contractHolderIds.add(contractItem.Contract_Holder__c);
        }

        Map<Id, Account> contractHolderMap = new Map<Id, Account>([
                SELECT Id, OwnerId
                FROM Account
                WHERE Id IN :contractHolderIds
        ]);

        String resultMessage = '';

        Map<Id, Offer__c> offersToClose = closeOffers(scope);
        List<Database.SaveResult> offerUpdateResults = Database.update(offersToClose.values(), false);
        Set<Id> failedContractIds = new Set<Id>();
        for (Database.SaveResult updateResult : offerUpdateResults) {
            if (!updateResult.isSuccess()) {
                Id failedContractId = offersToClose.get(updateResult.getId()).Base_Contract__c;
                if(!failedContractIds.contains(failedContractId)) {
                    failedContractIds.add(failedContractId);
                    FAILED_CONTRACTS++;
                }
                localErrors++;
                resultMessage += 'Errors on Offer Id: ' + updateResult.getId() +
                        ' for Contract Id: ' + failedContractId + ' | ';
                for (Database.Error error : updateResult.getErrors()) {
                    resultMessage += error.getStatusCode() + ' : ' + error.getMessage() + '\n';
                }
            }
        }

        List<Contract__c> contractsToUpdate = new List<Contract__c>();
        for (Contract__c scopeItem : scope) {
            if (!failedContractIds.contains(scopeItem.Id)) {
                contractsToUpdate.add(scopeItem);
            }
        }

        contractsToUpdate = extendContracts(contractsToUpdate);
        List<Database.SaveResult> contractUpdateResults = Database.update(contractsToUpdate, false);
        List<Contract__c> contractSuccesses = new List<Contract__c>();
        for (Database.SaveResult updateResult : contractUpdateResults) {
            if (!updateResult.isSuccess()) {
                FAILED_CONTRACTS++;
                localErrors++;
                resultMessage += 'Errors on Contract Id: ' + updateResult.getId() + ' | ';
                for (Database.Error error : updateResult.getErrors()) {
                    resultMessage += error.getStatusCode() + ' : ' + error.getMessage() + '\n';
                }
            } else {
                contractSuccesses.add(scopeMap.get(updateResult.getId()));
                SUCCESS_CONTRACTS++;
            }
        }

        List<Pricing_Component__c> pricingComponentsToUpdate = extendPricingComponents(contractSuccesses);
        TOTAL_PCS += pricingComponentsToUpdate.size();
        List<Database.SaveResult> pricingComponentUpdateResults = Database.update(pricingComponentsToUpdate, false);
        for (Database.SaveResult updateResult : pricingComponentUpdateResults) {
            if (!updateResult.isSuccess()) {
                FAILED_PCS++;
                localErrors++;
                resultMessage += 'Errors on Pricing Component Id: ' + updateResult.getId() + ' | ';
                for (Database.Error error : updateResult.getErrors()) {
                    resultMessage += error.getStatusCode() + ' : ' + error.getMessage() + '\n';
                }
            } else {
                SUCCESS_PCS++;
            }
        }

        List<Case> casesToInsert = contractsExtensionCases(contractSuccesses, contractHolderMap);
        casesToInsert.addAll(contractsRemitCases(contractSuccesses));
        casesToInsert.addAll(contractsGuaranteeCases(contractSuccesses, contractHolderMap));
        TOTAL_CASES += casesToInsert.size();
        List<Database.SaveResult> caseInsertResults = Database.insert(casesToInsert, false);
        for (Database.SaveResult insertResult : caseInsertResults) {
            if (!insertResult.isSuccess()) {
                FAILED_CASES++;
                localErrors++;
                resultMessage += 'Errors on Cases: \n';
                for (Database.Error error : insertResult.getErrors()) {
                    resultMessage += error.getStatusCode() + ' : ' + error.getMessage() + ' | ' + error.getFields() + '\n';
                }
            } else {
                SUCCESS_CASES++;
            }
        }

        String resultStatus = 'Completed';
        if (localErrors > 0) {
            resultMessage += '\n' + '--------------' + '\n';
            resultStatus = 'Error';
            RESULT_STATUS = 'Error';
            NUMBER_OF_FAILED_BATCHES++;
        }

        Batch_Job_Log__c childLog = new Batch_Job_Log__c(
                Manual_Apex_Batch_Job__c = true,
                Batch_Job_Name__c = 'msBatchContractExtension',
                RecordTypeId = BATCH_JOB_LOG_CHILD_REC_TYPE_ID,
                Number_of_Errors__c = localErrors,
                Parent_Log__c = PARENT_LOG_ID,
                Execution_Result__c = resultMessage,
                Status__c = resultStatus,
                Result__c = resultStatus,
                Completed_Date__c = Datetime.now(),
                CPUTimeUsed__c = Limits.getCpuTime(),
                CPUTimeLimit__c = (Decimal) Limits.getLimitCpuTime(),
                DMLRowsUsed__c = Limits.getDmlRows(),
                DMLRowsLimit__c = Limits.getLimitDmlRows(),
                DMLStatementsUsed__c = Limits.getDmlStatements(),
                DMLStatementsLimit__c = Limits.getLimitDmlStatements(),
                SOQLQueriesUsed__c = Limits.getQueries(),
                SOQLQueriesLimit__c = Limits.getLimitQueries(),
                SOQLRowsUsed__c = Limits.getQueryRows(),
                SOQLRowsLimit__c = Limits.getLimitQueryRows(),
                AsyncApexCallsUsed__c = Limits.getAsyncCalls(),
                AsyncApexCallsLimit__c = Limits.getLimitAsyncCalls()
        );
        insert childLog;
    }

    global void finish(Database.BatchableContext bc) {
        //TODO: This portion should be handled by the Apex Scheduling Framework, once we can embed this job
        AsyncApexJob jobResult = [
                SELECT Id, CompletedDate, NumberOfErrors, JobItemsProcessed
                FROM AsyncApexJob
                WHERE Id = :bc.getJobId()
                LIMIT 1
        ];

        String resultSummary = 'Result summary:\n' +
                'Contract updates: ' + TOTAL_CONTRACTS + '\n' +
                'Contracts successful: ' + SUCCESS_CONTRACTS + '\n' +
                'Contracts failed: ' + FAILED_CONTRACTS + '\n' +
                'Pricing Components updates: ' + TOTAL_PCS + '\n' +
                'Pricing Components successful: ' + SUCCESS_PCS + '\n' +
                'Pricing Components failed: ' + FAILED_PCS + '\n' +
                'Cases tried to insert: ' + TOTAL_CASES + '\n' +
                'Cases successful: ' + SUCCESS_CASES + '\n' +
                'Cases failed: ' + FAILED_CASES + '\n\n' + '--------' + '\n';

        Batch_Job_Log__c log = new Batch_Job_Log__c(
                Batches_Processed__c = jobResult.JobItemsProcessed,
                FailedBatches__c = NUMBER_OF_FAILED_BATCHES,
                Number_of_Errors__c = FAILED_CONTRACTS + FAILED_PCS + FAILED_CASES,
                Completed_Date__c = jobResult.CompletedDate,
                SuccessfulBatches__c = jobResult.JobItemsProcessed - NUMBER_OF_FAILED_BATCHES,
                Execution_Result__c = resultSummary,
                Status__c = RESULT_STATUS,
                Result__c = RESULT_STATUS,
                Id = PARENT_LOG_ID);
        update log;
    }

    private List<Contract__c> extendContracts(List<Contract__c> contractList) {
        List<Contract__c> updateContractsList = new List<Contract__c>();
        for (Contract__c item : contractList) {
            item.End_Date__c = item.End_Date__c.addYears(1);
            item.Workflow_Type__c = 'Auto-Extension';
            updateContractsList.add(item);
        }
        return updateContractsList;
    }

    private Map<Id, Offer__c> closeOffers(List<Contract__c> contractList) {
        List<Offer__c> offersToClose = [
                SELECT Id, Workflow_Type__c, Status__c, Base_Contract__c
                FROM Offer__c
                WHERE Base_Contract__c IN :contractList
                AND Status__c != 'Closed Won'
                AND Status__c != 'Closed Lost'
                AND Status__c != 'Rejected - New Offer'
                AND RecordTypeId = :OFFER_PPA_EXTENSION_REC_TYPE_ID
        ];
        for (Offer__c item : offersToClose) {
            item.Workflow_Type__c = 'Auto-Extension';
            item.Resulting_Contract__c = item.Base_Contract__c;
            item.Status__c = 'Closed Won';
        }
        return new Map<Id, Offer__c>(offersToClose);
    }

    private List<Pricing_Component__c> extendPricingComponents(List<Contract__c> contractList) {
        List<Pricing_Component__c> pricingComponentList = [
                SELECT Id, End_Date__c, Active__c, Contract__r.End_Date__c
                FROM Pricing_Component__c
                WHERE Contract__c IN :contractList
        ];
        List<Pricing_Component__c> updateListPricingComponents = new List<Pricing_Component__c>();
        if (pricingComponentList.size() > 0) {
            for (Pricing_Component__c item : pricingComponentList) {
                if (item.End_Date__c.addYears(1) == item.Contract__r.End_Date__c) {
                    item.End_Date__c = item.End_Date__c.addYears(1);
                    updateListPricingComponents.add(item);
                }
            }
        }
        return updateListPricingComponents;
    }

    private List<Case> contractsExtensionCases(List<Contract__c> contractList, Map<Id, Account> contractHolderMap) {

        List<Case> caseList = new List<Case>();
        for (Contract__c contractItem : contractList) {
            Map<String, Object> flowParameters = new Map<String, Object>();
            flowParameters.put('Case_Type', 'Auto_Contract_Extension');
            flowParameters.put('InputAccount', contractHolderMap.get(contractItem.Contract_Holder__c));
            flowParameters.put('InputContract', contractItem);
            Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
            caseFactory.start();
            Case extensionCase = (Case) caseFactory.getVariableValue('OutputCase');
            caseList.add(extensionCase);
        }
        return (List<Case>) msLepton.flowObjectComposer(caseList);
    }

    private List<Case> contractsRemitCases(List<Contract__c> contractList) {

        List<Case> caseList = new List<Case>();
        for (Contract__c contractItem : contractList) {
            if (contractItem.REMIT_Reporting_Relevant__c) {
                Map<String, Object> flowParameters = new Map<String, Object>();
                flowParameters.put('Case_Type', 'REMIT_Contract_Auto_Extension_Case');
                flowParameters.put('InputContract', contractItem);
                Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
                caseFactory.start();
                Case extensionCase = (Case) caseFactory.getVariableValue('OutputCase');
                caseList.add(extensionCase);
            }
        }
        return (List<Case>) msLepton.flowObjectComposer(caseList);
    }

    private List<Case> contractsGuaranteeCases(List<Contract__c> contractList, Map<Id, Account> contractHolderMap) {
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>(contractList);

        List<SK_Security__c> guaranteeSecurities = [
                SELECT
                        Id, SK_Contract__c, SK_Notional_Amount__c,
                        SK_No_End_Date__c, SK_End_Date__c, SK_Guarantee_Record_Type__c,
                        SK_Contract__r.Contract_Holder__c
                FROM SK_Security__c
                WHERE (SK_Status__c = 'Guarantee Issued' OR SK_Status__c = 'Expiring')
                AND (SK_End_Date__c >= TODAY OR SK_No_End_Date__c = TRUE)
                AND SK_Contract__c IN :contractsMap.keySet()
        ];
        List<Contract_Role__c> contractRolesCP = [
                SELECT Contact__c, Contract__c
                FROM Contract_Role__c
                WHERE Contract__c IN :contractsMap.keySet()
                AND Role__c = 'Contractual Contact'
                AND (End_Date__c >= TODAY OR End_Date__c = NULL)
        ];
        List<Contract_Role__c> contractRolesMR = [
                SELECT Contract__c, Account__c
                FROM Contract_Role__c
                WHERE Contract__c IN :contractsMap.keySet()
                AND Role__c = 'Mail recipient'
                AND (End_Date__c >= TODAY OR End_Date__c = NULL)
        ];
        List<Case> caseList = new List<Case>();

        for (SK_Security__c gItem : guaranteeSecurities) {
            Contract_Role__c contractualContactRole = null;
            Contract_Role__c mailingRecipientRole = null;

            for (Contract_Role__c contractRoleItem : contractRolesCP) {
                if (contractRoleItem.Contract__c == gItem.SK_Contract__c) {
                    if (contractRoleItem.Contact__c != null) {
                        contractualContactRole = contractRoleItem;
                    }
                }
            }
            for (Contract_Role__c roleItem : contractRolesMR) {
                if (roleItem.Contract__c == gItem.SK_Contract__c) {
                    if (roleItem.Account__c != null) {
                        mailingRecipientRole = roleItem;
                    }
                }
            }

            Map<String, Object> flowParameters = new Map<String, Object>();
            flowParameters.put('Case_Type', 'Guarantee_Amendment_Request');
            flowParameters.put('InputGuarantee', gItem);
            flowParameters.put('InputAccount', contractHolderMap.get(gItem.SK_Contract__r.Contract_Holder__c));
            flowParameters.put('InputContract', contractsMap.get(gItem.SK_Contract__c));
            flowParameters.put('InputContractRole_Contractual_Contact', contractualContactRole);
            flowParameters.put('InputContractRole_Mail_Recipient', mailingRecipientRole);
            Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
            caseFactory.start();
            Case guaranteeCase = (Case) caseFactory.getVariableValue('OutputCase');
            caseList.add(guaranteeCase);
        }
        return (List<Case>) msLepton.flowObjectComposer(caseList);
    }
}