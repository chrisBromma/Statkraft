/****************************************************************************************************
* Class msKAMOpportunitiesListViewController
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2020-02-17
*   Description	:	---
*
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2020-02-17       	Init version.
*****************************************************************************************************/

public with sharing class msKAMOpportunitiesListViewController {
    @AuraEnabled
    public static msKAMUtility.listViewWrapper getOpportunities(Id accountId, String statusFilter) {
        List<Account> childAccounts = [SELECT Id FROM Account WHERE  Negotiating_Party__c=:accountId];
        Set<Id> childAccountIds = new Set<Id>();
        for(Account childItem : childAccounts) {
            childAccountIds.add(childItem.Id);
        }
        List<Opportunity> allRelatedOpps = [
                SELECT Id, Name, StageName, Expected_Start_Date__c, Opportunity_Installed_Capacity__c, RecordType.Name
                FROM Opportunity
                WHERE  ( AccountId = :accountId
                OR AccountId IN :childAccountIds
                )
                ORDER BY Expected_Start_Date__c ASC];
        List<PicklistEntry> statusEntries = Opportunity.StageName.getDescribe().getSobjectField().getDescribe().getPicklistValues();
        List<String> fieldsToSum = new List<String>{'Opportunity_Installed_Capacity__c'};
        return msKAMUtility.wrapRecords(allRelatedOpps, statusEntries, 'StageName',true,  new Set<String> {statusFilter}, fieldsToSum, 'Opportunity');
    }
}