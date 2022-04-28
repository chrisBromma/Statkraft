/****************************************************************************************************
 * Class msAccountHelper
 *
 *   Create By	:   (mindsquare AG)
 *   Create Date	:   ---
 *   Description	:	rac_ - Remit ACER Code Change Cases
 *                   npo_ -  Negotiating Partner Ownership -
 *                           in Germany, the Owner of the Negotiation Party always has to be the Owner of the Account as well
 *                   scm_ - Sync Customer Needs into Market Presence
 *                   TODO: The old logic still needs to be refactored to avoid double SOQLs etc
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare AG)	            2021-10-22       	Documentation and Remit Cases
 *****************************************************************************************************/

public without sharing class msAccountHelper {
    //Trigger Maps/Lists
    private List<Account> triggerOld;
    private List<Account> triggerNew;
    private Map<Id, Account> oldMap;
    private Map<Id, Account> newMap;

    public msAccountHelper(
        List<Account> oldList,
        List<Account> newList,
        Map<Id, Account> mapOld,
        Map<Id, Account> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    public msAccountHelper() {
    }

    //Global Variables
    public static final Id PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;

    //SOQL Maps
    private Map<Id, Account> accountMap = new Map<Id, Account>();
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Product_need_Link__c> customerNeedLinkMap = new Map<Id, Product_need_Link__c>();
    private Map<Id, Market_Presence__c> marketPresenceMap = new Map<Id, Market_Presence__c>();

    //DML Lists, Sets and Maps. Important only ever use one Map/List per SObject Type and DML operation!
    public Map<Id, Account> accountUpdateMap = new Map<Id, Account>();
    public List<Case> casesToInsert = new List<Case>();

    //ACER Code Change Variables
    private Set<Id> rac_contractHoldersToQueryContractsFor = new Set<Id>();
    private ListMapContainer rac_ContractHolderIdToContracts = new ListMapContainer(Contract__c.SObjectType);

    //Sync Customer Needs into Market Presence variables
    private ListMapContainer scm_customerNeedLinksByAccountMap = new ListMapContainer(Product_need_Link__c.SObjectType);

    //All Helper Variables for Negotiating Party hierarchy prevention
    private Set<Id> negPartySublist = new Set<Id>();
    private Map<Id, Account> negoPartyChildAccounts;
    private Set<Id> middleAccountIdSet = new Set<Id>();
    Set<Id> scm_accountIds = new Set<Id>();

    //All Helper Variables for KAM Task Allocation
    public Set<Id> taskIdsForOwnerUpdate = new Set<Id>();
    public Set<Id> accIdsToCreateTasksFor = new Set<Id>();
    public static final String TASK_STATUS_OPEN = 'Open';
    private static Set<Id> accountIdsToCalculateTasks = new Set<Id>();
    @TestVisible private List<Task> KAMTasksOfAccounts;
    public Map<String, Account_KAM_Tasks_Configuration__mdt> taskConfigByTaskSubjectMap;
    @TestVisible private Map<Id, List<Task>> tasksByAccountId = new Map<Id, List<Task>>();

    //All Helper Variables for Negotiating Party Processes
    private Map<Id, Account> negotiatingParties = new Map<Id, Account>();
    private Set<Id> negotiatingPartyIds = new Set<Id>();

    //All Helper Variables for Market Presence Generation
    private ListMapContainer mpg_marketPresencesByAccountId = new ListMapContainer(Market_Presence__c.SObjectType);
    private Set<Id> mpg_marketPresenceRelevantAccountIds = new Set<Id>();
    public Map<String, Market_Presence__c> mpg_marketPresencesToCreate = new Map<String, Market_Presence__c>();
    public Map<String, Market_Presence__c> mpg_marketPresencesToDelete = new Map<String, Market_Presence__c>();

    //Negotiating Party Owner logic variables
    private Set<Id> npo_negotiatingPartyIdsToLoad = new Set<Id>();

    //SOQL Methods
    public void load_Accounts() {
        if (!npo_negotiatingPartyIdsToLoad.isEmpty()) {
            accountMap = new Map<Id, Account>([
                    SELECT Id, OwnerId, Owner.Profile.Name
                    FROM Account
                    WHERE Id IN :npo_negotiatingPartyIdsToLoad
            ]);
        }
    }

    public void load_Contracts() {
        if (!rac_contractHoldersToQueryContractsFor.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Id, Contract_Type_New__c, Country__c,
                            Product_Type_New__c, Status__c, RecordTypeId,
                            REMIT_Reporting_Relevant__c, Contract_Date__c, Contract_Holder__c,
                            ID_18_Digit__c, REMIT_Contract_ID__c
                    FROM Contract__c
                    WHERE Contract_Holder__c IN :rac_contractHoldersToQueryContractsFor
            ]);
        }
    }
    public void load_Market_Presences() {
        if (!mpg_marketPresenceRelevantAccountIds.isEmpty()) {
            marketPresenceMap = new Map<Id, Market_Presence__c>([
                SELECT Id, Name, Account__c
                FROM Market_Presence__c
                WHERE Account__c IN :mpg_marketPresenceRelevantAccountIds
            ]);
        }
    }

    public void load_CustomerNeedLinks(){
        if(!scm_accountIds.isEmpty()){
            customerNeedLinkMap = new Map<Id, Product_need_Link__c>([
                SELECT Id, Country__c, Account__c
                FROM Product_need_Link__c
                WHERE Account__c IN :scm_accountIds
            ]);
        }
    }

    //Negotiating Party Owner methods
    private Boolean npo_isRelevantToCheck_Insert(Account newAccount) {
        return newAccount.BillingCountry == 'Germany' && newAccount.Negotiating_Party__c != null;
    }

    private Boolean npo_isRelevantToCheck_Update(Account oldAccount, Account newAccount) {
        return npo_isRelevantToCheck_Insert(newAccount)
                && (oldAccount.BillingCountry != newAccount.BillingCountry
                || oldAccount.Negotiating_Party__c != newAccount.Negotiating_Party__c);
    }

    public void npo_listNegotiatingParties_Insert() {
        for (Account newAccount : triggerNew) {
            if (npo_isRelevantToCheck_Insert(newAccount)) {
                npo_negotiatingPartyIdsToLoad.add(newAccount.Negotiating_Party__c);
            }
        }
    }

    public void npo_listNegotiatingParties_Update() {
        for (Account newAccount : triggerNew) {
            if (npo_isRelevantToCheck_Update(oldMap.get(newAccount.Id), newAccount)) {
                npo_negotiatingPartyIdsToLoad.add(newAccount.Negotiating_Party__c);
            }
        }
    }

    private Boolean npo_isRelevantToSetOwnerId_Insert(Account newAccount) {
        return npo_isRelevantToCheck_Insert(newAccount)
                && accountMap.get(newAccount.Negotiating_Party__c).Owner.Profile.Name == 'DE EEG';
    }

    private Boolean npo_isRelevantToSetOwnerId_Update(Account oldAccount, Account newAccount) {
        return npo_isRelevantToCheck_Update(oldAccount, newAccount)
                && npo_isRelevantToSetOwnerId_Insert(newAccount);
    }

    public void npo_ensureCorrectOwnerId_Insert(Account newAccount) {
        if (npo_isRelevantToSetOwnerId_Insert(newAccount)) {
            npo_updateOwnerId(newAccount);
        }
    }

    public void npo_ensureCorrectOwnerId_Update(Account oldAccount, Account newAccount) {
        if (npo_isRelevantToSetOwnerId_Update(oldAccount, newAccount)) {
            npo_updateOwnerId(newAccount);
        }
    }

    private void npo_updateOwnerId(Account newAccount) {
        newAccount.OwnerId = accountMap.get(newAccount.Negotiating_Party__c).OwnerId;
    }

    //Todo: These need to be refactored!
    public void loadRelatedNegotiatingPartyParentAccounts() {
        if (!Trigger.isDelete) {
            for (Account accountItem : triggerNew) {
                if (
                    accountItem.Negotiating_Party__c != null &&
                    ((oldMap != null && oldMap.get(accountItem.Id)?.Negotiating_Party__c == null) || oldMap == null)
                ) {
                    negPartySublist.add(accountItem.Id);
                }
            }
            negoPartyChildAccounts = new Map<Id, Account>(
                [SELECT Id, Negotiating_Party__c FROM Account WHERE Negotiating_Party__c IN :negPartySublist]
            );

            if (!negoPartyChildAccounts.isEmpty()) {
                for (Account negoChildItem : negoPartyChildAccounts.values()) {
                    middleAccountIdSet.add(negoChildItem.Negotiating_Party__c);
                }
            }
        }
    }

    public void preventNegotiatingPartyHierarchy(Account newAccount) {
        if (middleAccountIdSet.contains(newAccount.Id)) {
            newAccount.addError(
                'Warning: This account is already a negotiating party for another account and therefore this account may not have a negotiating party.'
            );
            return;
        }
    }

    public void calculateNegotiatingPartyChildren(Account newAccount) {
        Account negotiatingParty;

        if (this.negotiatingPartyWasRemoved(newAccount)) {
            negotiatingParty = negotiatingParties.get(oldMap.get(newAccount.Id).Negotiating_Party__c);
            negotiatingParty.Negotiating_for_X_Accounts__c--;
        } else if (this.negotiatingPartyIsPresent(newAccount)) {
            negotiatingParty = negotiatingParties.get(newAccount.Negotiating_Party__c);
            negotiatingParty.Negotiating_for_X_Accounts__c = negotiatingParties.get(newAccount.Negotiating_Party__c)
                .Accounts1__r.size();
        }

        if (negotiatingParty != null) {
            accountUpdateMap.put(negotiatingParty.Id, negotiatingParty);
        }
    }

    public void subtractNegotiatingPartyChild(Account oldAccount) {
        Account negotiatingParty;

        if (this.accountHadNegotiatingParty(oldAccount)) {
            negotiatingParty = negotiatingParties.get(oldAccount.Negotiating_Party__c);
            negotiatingParty.Negotiating_for_X_Accounts__c--;
        }

        if (negotiatingParty != null) {
            accountUpdateMap.put(negotiatingParty.Id, negotiatingParty);
        }
    }

    public Boolean negotiatingPartyWasRemoved(Account newAccount) {
        return newAccount.Negotiating_Party__c == null && oldMap?.get(newAccount.Id).Negotiating_Party__c != null;
    }

    public Boolean negotiatingPartyIsPresent(Account newAccount) {
        return newAccount.Negotiating_Party__c != null;
    }

    public Boolean accountHadNegotiatingParty(Account oldAccount) {
        return oldAccount.Negotiating_Party__c != null &&
            negotiatingParties.keySet().contains(oldAccount.Negotiating_Party__c);
    }

    public void addNegotiatingPartyIdsToSet(List<Account> triggerList) {
        for (Account acc : triggerList) {
            if (acc.Negotiating_Party__c != null) {
                negotiatingPartyIds.add(acc.Negotiating_Party__c);
            }
        }
    }

    public void loadNegotiatingParties() {
        if (Trigger.isUpdate || Trigger.isInsert) {
            addNegotiatingPartyIdsToSet(triggerNew);
        }
        if (Trigger.isDelete || Trigger.isUpdate) {
            addNegotiatingPartyIdsToSet(triggerOld);
        }
        negotiatingParties = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    KAM_relevant__c,
                    KAM_relevant_approved__c,
                    KAM_pending__c,
                    last_KAM_Submitter__c,
                    OwnerId,
                    Owner.Username,
                    Owner.Name,
                    KAM_proposal__c,
                    Negotiating_for_X_Accounts__c,
                    (SELECT Id FROM Accounts1__r)
                FROM Account
                WHERE Id IN :negotiatingPartyIds
            ]
        );
    }

    public void load_KamTaskData() {
        this.loadKamTasksConfigurationsBySubjectsMap();
        this.loadKAMTaskRelevantAccounts();
        this.loadAccountIdToKAMTaskMap();
    }

    public Map<String, Account_KAM_Tasks_Configuration__mdt> loadKamTasksConfigurationsBySubjectsMap() {
        if (taskConfigByTaskSubjectMap == null) {
            taskConfigByTaskSubjectMap = msTaskHelper.getAccountKamTasksConfigurationsBySubjects();
        }
        return taskConfigByTaskSubjectMap;
    }

    public void loadKAMTaskRelevantAccounts() {
        for (Account acc : newMap.values()) {
            if (acc.KAM_relevant__c && oldMap.get(acc.Id).KAM_approved__c != acc.KAM_approved__c) {
                accountIdsToCalculateTasks.add(acc.Id);
            }
        }
        KAMTasksOfAccounts = [
            SELECT Id, Subject, AccountId, ActivityDate, Status
            FROM Task
            WHERE AccountId IN :accountIdsToCalculateTasks AND Subject IN :taskConfigByTaskSubjectMap.keySet()
        ];
    }

    public void loadAccountIdToKAMTaskMap() {
        if (!accountIdsToCalculateTasks.isEmpty()) {
            this.fillAccountIdToTaskListMap();
        }
    }

    public void fillAccountIdToTaskListMap() {
        for (Task task : KAMTasksOfAccounts) {
            if (tasksByAccountId.containsKey(task.AccountId)) {
                tasksByAccountId.get(task.AccountId).add(task);
            } else {
                tasksByAccountId.put(task.AccountId, new List<Task>{ task });
            }
        }
    }

    public void defineKAMTasksToCreateOrReassign(Account newAccount) {
        if (tasksByAccountId.containsKey(newAccount.Id)) {
            for (Task task : tasksByAccountId.get(newAccount.Id)) {
                if (task.Status == TASK_STATUS_OPEN) {
                    taskIdsForOwnerUpdate.add(task.Id);
                }
            }
        } else if (
            newAccount.KAM_Approval_Step__c == 'approved' &&
            newAccount.KAM_Approval_Step__c != oldMap.get(newAccount.Id).KAM_Approval_Step__c
        ) {
            accIdsToCreateTasksFor.add(newAccount.Id);
        }
    }

    @Future
    public static void createNewTasks(List<Id> accountsToCreateTasksFor, String serializedTaskConfig) {
        List<Task> tasksWithNotification = new List<Task>();
        List<Task> tasksWithoutNotification = new List<Task>();
        msAccountHelper Helper = new msAccountHelper();

        Map<String, Account_KAM_Tasks_Configuration__mdt> taskConfigByTaskSubjectMap = (Map<String, Account_KAM_Tasks_Configuration__mdt>) JSON.deserialize(
            serializedTaskConfig,
            Map<String, Account_KAM_Tasks_Configuration__mdt>.class
        );

        Map<Id, Set<String>> accIdToSubjectSet = new Map<Id, Set<String>>();
        for (Task task : [SELECT Subject, WhatId FROM Task WHERE WhatId IN :accountsToCreateTasksFor]) {
            if (accIdToSubjectSet.get(task.WhatId) != null) {
                accIdToSubjectSet.get(task.WhatId).add(task.Subject);
            } else {
                accIdToSubjectSet.put(task.WhatId, new Set<String>{ task.Subject });
            }
        }

        for (Account acc : [SELECT OwnerId FROM Account WHERE Id IN :accountsToCreateTasksFor]) {
            Id newOwnerId = acc.OwnerId;
            Id accId = acc.Id;
            for (Account_KAM_Tasks_Configuration__mdt config : taskConfigByTaskSubjectMap.values()) {
                if (
                    accIdToSubjectSet.get(accId) == null || !accIdToSubjectSet.get(acc.Id).contains(config.Subject__c)
                ) {
                    if (config.Send_Notification__c) {
                        tasksWithNotification.add(msTaskHelper.extractTaskFromKAMConfig(newOwnerId, accId, config));
                    } else {
                        tasksWithoutNotification.add(msTaskHelper.extractTaskFromKAMConfig(newOwnerId, accId, config));
                    }
                }
            }
        }

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.emailHeader.triggerUserEmail = false;
        if (!tasksWithoutNotification.isEmpty()) {
            Database.insert(tasksWithoutNotification, dmo);
        }
        if (!tasksWithNotification.isEmpty()) {
            Database.insert(tasksWithNotification);
        }
    }

    @Future
    public static void updateTaskOwner(List<Id> IdsOfTasksToUpdate, String serializedTaskConfig) {
        List<Task> tasksWithNotification = new List<Task>();
        List<Task> tasksWithoutNotification = new List<Task>();
        msAccountHelper Helper = new msAccountHelper();

        Map<String, Account_KAM_Tasks_Configuration__mdt> taskConfigByTaskSubjectMap = (Map<String, Account_KAM_Tasks_Configuration__mdt>) JSON.deserialize(
            serializedTaskConfig,
            Map<String, Account_KAM_Tasks_Configuration__mdt>.class
        );
        List<Task> tasksToUpdate = [
            SELECT Id, WhatId, Account.OwnerId, Subject
            FROM Task
            WHERE Id IN :IdsOfTasksToUpdate AND Subject IN :taskConfigByTaskSubjectMap.keySet()
        ];

        for (Task task : tasksToUpdate) {
            task.OwnerId = task.Account.OwnerId;
            task.ActivityDate = Date.today()
                .addDays(Integer.valueOf(taskConfigByTaskSubjectMap.get(task.Subject).Deadline_in_days__c));
            if (taskConfigByTaskSubjectMap.get(task.Subject).Send_Notification__c) {
                tasksWithNotification.add(task);
            } else {
                tasksWithoutNotification.add(task);
            }
        }

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.emailHeader.triggerUserEmail = false;
        if (!tasksWithoutNotification.isEmpty()) {
            Database.update(tasksWithoutNotification, dmo);
        }
        if (!tasksWithNotification.isEmpty()) {
            Database.update(tasksWithNotification);
        }
    }

    //Remit Acer Code Change Methods
    public void rac_identifyContractHolderForCases_Update() {
        for (Account newAccount : triggerNew) {
            if (rac_ContractHolderRelevantChange(oldMap.get(newAccount.Id), newAccount)) {
                rac_contractHoldersToQueryContractsFor.add(newAccount.Id);
            }
        }
    }

    public void rac_buildDataModel() {
        if (!rac_contractHoldersToQueryContractsFor.isEmpty() && !contractMap.isEmpty()) {
            for (Contract__c contractToSort : contractMap.values()) {
                if (
                    rac_contractHoldersToQueryContractsFor.contains(contractToSort.Contract_Holder__c) &&
                    (contractToSort.Country__c == 'France' ||
                    contractToSort.Country__c == 'Germany' ||
                    contractToSort.Country__c == 'Ireland' ||
                    contractToSort.Country__c == 'United Kingdom') &&
                    contractToSort.Product_Type_New__c != 'Flex Optimization GB' &&
                    contractToSort.Product_Type_New__c != 'Flex Optimization IRE' &&
                    contractToSort.Product_Type_New__c != 'Flex Optimization NI' &&
                    contractToSort.REMIT_Reporting_Relevant__c &&
                    contractToSort.Contract_Date__c != null &&
                    contractToSort.RecordTypeId == PPA_CONTRACT_RECORD_TYPE &&
                    contractToSort.Status__c == 'Active'
                ) {
                    rac_ContractHolderIdToContracts.addToMap(contractToSort.Contract_Holder__c, contractToSort);
                }
            }
        }
    }

    public void rac_createAcerCodeChangeRemitCasesIfNecessary(Account oldAccount, Account newAccount) {
        if (rac_ContractHolderRelevantChange(oldAccount, newAccount)) {
            List<Contract__c> contractsToIssueCasesFor = rac_ContractHolderIdToContracts.get(newAccount.Id);
            for (Contract__c contractToIssueCaseFor : contractsToIssueCasesFor) {
                Map<String, Object> flowParameters = new Map<String, Object>();
                flowParameters.put('Case_Type', 'REMIT_ACER_Code_Change_Case');
                flowParameters.put('InputContract', contractToIssueCaseFor);
                Flow.Interview.Case_Factory caseFactory = new Flow.Interview.Case_Factory(flowParameters);
                caseFactory.start();
                Case remitTerminationCase = (Case) caseFactory.getVariableValue('OutputCase');
                remitTerminationCase.Description +=
                    '\nOld ACER Code: ' +
                    oldAccount.REMIT_Acer_Code__c +
                    '\nNew ACER Code: ' +
                    newAccount.REMIT_Acer_Code__c;
                casesToInsert.add(remitTerminationCase);
            }
        }
    }

    private Boolean rac_ContractHolderRelevantChange(Account oldAccount, Account newAccount) {
        return oldAccount.REMIT_Acer_Code__c != newAccount.REMIT_Acer_Code__c;
    }

    // Sync Customer Needs into Market Presence
    public void scm_defineAccountsToSyncMarketPresenceFor(){
        for (Account acc : triggerNew) {
            if (acc.Market_Presence__c != oldMap.get(acc.Id).Market_Presence__c) {
                scm_accountIds.add(acc.Id);
            }
        }

    }

    public void scm_buildDataModel(){
        for (Product_Need_Link__c cnl : customerNeedLinkMap.values()) {
            scm_customerNeedLinksByAccountMap.addToMap(cnl.Account__c, cnl);
        }
    }

    public void scm_addMissingMarketsIntoMarketPresence(Account newAccount){
        for (Product_Need_Link__c cnl : (List<Product_Need_Link__c>) scm_customerNeedLinksByAccountMap.get(newAccount.Id)) {
            if (!newAccount.Market_Presence__c.contains(cnl.Country__c)) {
                newAccount.Market_Presence__c += ';' + cnl.Country__c;
            }
        }
    }

    //Market Presence Generation logic
    public void mpg_gatherMarketPresenceRelevantAccountIds() {
        for (Account acc : triggerNew) {
            if (Trigger.isInsert || acc.Market_Presence__c != oldMap.get(acc.Id).Market_Presence__c) {
                mpg_marketPresenceRelevantAccountIds.add(acc.Id);
            }
        }
    }

    public void mpg_buildDataModel() {
        for (Market_Presence__c mp : marketPresenceMap.values()) {
            mpg_marketPresencesByAccountId.addToMap(mp.Account__c, mp);
        }
    }
    public void mpg_getMarketPresencesToCreate(Account acc) {
        if (acc.Market_Presence__c != null && mpg_marketPresenceRelevantAccountIds.contains(acc.Id)) {
            List<Market_Presence__c> marketPresencesOfThisAcc = mpg_marketPresencesByAccountId.get(acc.Id);

            Map<String, Market_Presence__c> nameToMarketPresence = new Map<String, Market_Presence__c>();
            if (marketPresencesOfThisAcc != null) {
                for (Market_Presence__c marketPresence : marketPresencesOfThisAcc) {
                    nameToMarketPresence.put(marketPresence.Name, marketPresence);
                }
            }
            for (String relevantMarket : acc.Market_Presence__c.split(';')) {
                if (nameToMarketPresence.get(relevantMarket) == null) {
                    mpg_marketPresencesToCreate.put(
                        relevantMarket,
                        new Market_Presence__c(Name = relevantMarket, Account__c = acc.Id)
                    );
                }
            }
        }
    }
    public void mpg_getMarketPresencesToDelete(Account acc) {
        if (mpg_marketPresenceRelevantAccountIds.contains(acc.Id)) {
            List<Market_Presence__c> marketPresencesOfThisAcc = mpg_marketPresencesByAccountId.get(acc.Id);

            if (marketPresencesOfThisAcc != null) {
                for (Market_Presence__c marketPresence : marketPresencesOfThisAcc) {
                    if (
                        acc.Market_Presence__c == null ||
                        !acc.Market_Presence__c.split(';').contains(marketPresence.Name)
                    ) {
                        mpg_marketPresencesToDelete.put(marketPresence.Id, marketPresence);
                    }
                }
            }
        }
    }
}