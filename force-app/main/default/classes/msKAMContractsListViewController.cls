/****************************************************************************************************
* Class msKAMContractsListViewController
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

public with sharing class msKAMContractsListViewController {
    @AuraEnabled
    public static msKAMUtility.listViewWrapper getContracts(Id accountId, String statusFilter) {
        List<Account> childAccounts = [SELECT Id FROM Account WHERE Negotiating_Party__c = :accountId];
        Set<Id> childAccountIds = new Set<Id>();
        for (Account childItem : childAccounts) {
            childAccountIds.add(childItem.Id);
        }
        List<Contract__c> allRelatedContracts = [
                SELECT Id, Alternative_Contract_Name__c,
                        Contracted_Capacity__c, Profit__c, End_Date__c,
                        Name, Contract_Holder__c, Contract_Holder__r.Name, Status__c
                FROM Contract__c
                WHERE (Contract_Holder__c = :accountId
                OR Contract_Holder__c IN :childAccountIds
                )
                ORDER BY Contracted_Capacity__c DESC
        ];
        List<PicklistEntry> statusEntries = Contract__c.Status__c.getDescribe().getSobjectField().getDescribe().getPicklistValues();
        List<String> fieldsToSum = new List<String>{'Contracted_Capacity__c', 'Profit__c'};
        return msKAMUtility.wrapRecords(allRelatedContracts, statusEntries, 'Status__c',true, new Set<String>{statusFilter}, fieldsToSum, 'Contract__c');
    }
}