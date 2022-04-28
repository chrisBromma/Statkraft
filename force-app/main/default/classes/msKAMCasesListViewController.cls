/****************************************************************************************************
* Class msKAMCasesListViewController
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2020-02-17
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2020-02-17       	Init version.
*****************************************************************************************************/

public with sharing class msKAMCasesListViewController {
    @AuraEnabled
    public static msKAMUtility.listViewWrapper getCases(Id accountId, String statusFilter) {
        List<Account> childAccounts = [SELECT Id FROM Account WHERE Negotiating_Party__c =: accountId];
        Set<Id> accountIds = new Set<Id>();
        for(Account childItem : childAccounts) {
            accountIds.add(childItem.Id);
        }
        accountIds.add(accountId);
        Map<Id,Contract__c> allContracts = new Map<Id,Contract__c>([
                SELECT Id
                FROM Contract__c
                WHERE Contract_Holder__c IN :accountIds

        ]);
        List<MeterRegistration__c> allMeterRegistrations = [
                SELECT Meter__c, Contract__r.Contract_Holder__r.Name, Contract__r.Contract_Holder__c
                FROM MeterRegistration__c WHERE Contract__c IN :allContracts.keySet()
        ];
        Map<Id, MeterRegistration__c> allMeterRegsMap = new Map<Id,MeterRegistration__c>();
        for(MeterRegistration__c regItem : allMeterRegistrations) {
            allMeterRegsMap.put(regItem.Meter__c, regItem);
        }
        List<Case> allRelatedCases = [
                SELECT
                        Id,
                        AccountId,
                        Subject,
                        Status,
                        OwnerId,
                        CreatedDate,
                        Owner.Name,
                        Account.Name,
                        Contract__c,
                        Contract__r.Contract_Holder__r.Name,
                        Opportunity__c,
                        Opportunity__r.Contract__c,
                        Opportunity__r.Contract__r.Contract_Holder__c,
                        Opportunity__r.Contract__r.Contract_Holder__r.Name,
                        Opportunity__r.AccountId,
                        Opportunity__r.Account.Name,
                        Meter__c
                FROM Case
                WHERE  (   AccountId IN :accountIds
                        OR Contract__r.Contract_Holder__c IN :accountIds
                        OR Opportunity__r.Contract__r.Contract_Holder__c IN :accountIds
                        OR Opportunity__r.AccountId IN :accountIds
                        OR Meter__c IN :allMeterRegsMap.keySet()
                )
                ORDER BY CreatedDate DESC];
        for(Case caseItem : allRelatedCases) {
            if(caseItem.AccountId == null) {
                if(caseItem.Contract__c != null
                        && caseItem.Contract__r.Contract_Holder__c != null) {
                    caseItem.Account = new Account(Name = caseItem.Contract__r.Contract_Holder__r.Name);
                    caseItem.AccountId = caseItem.Contract__r.Contract_Holder__c;
                } else if(caseItem.Opportunity__c != null
                        && caseItem.Opportunity__r.Contract__c != null
                        && caseItem.Opportunity__r.Contract__r.Contract_Holder__c != null) {
                    caseItem.Account = new Account(Name = caseItem.Opportunity__r.Contract__r.Contract_Holder__r.Name);
                    caseItem.AccountId = caseItem.Opportunity__r.Contract__r.Contract_Holder__c;
                } else if(caseItem.Opportunity__c != null
                        && caseItem.Opportunity__r.AccountId != null) {
                    caseItem.Account = new Account(Name = caseItem.Opportunity__r.Account.Name);
                    caseItem.AccountId = caseItem.Opportunity__r.AccountId;
                } else if(allMeterRegsMap.containsKey(caseItem.Meter__c)) {
                    caseItem.Account = new Account(Name = allMeterRegsMap.get(caseItem.Meter__c).Contract__r.Contract_Holder__r.Name);
                    caseItem.AccountId = allMeterRegsMap.get(caseItem.Meter__c).Contract__r.Contract_Holder__c;
                }
            }
        }
        List<PicklistEntry> statusEntries = Case.Status.getDescribe().getSobjectField().getDescribe().getPicklistValues();
        List<String> fieldsToSum = new List<String>();

        return msKAMUtility.wrapRecords(allRelatedCases, statusEntries, 'Status',true, new Set<String>{statusFilter}, fieldsToSum, 'Case');
    }
}