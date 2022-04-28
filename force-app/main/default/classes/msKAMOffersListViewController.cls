/****************************************************************************************************
* Class msKAMOffersListViewController
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

public with sharing class msKAMOffersListViewController {
    @AuraEnabled
    public static msKAMUtility.listViewWrapper getOffers(Id accountId, String statusFilter) {
        List<Account> childAccounts = [SELECT Id FROM Account WHERE Negotiating_Party__c = :accountId];
        Set<Id> childAccountIds = new Set<Id>();
        for (Account childItem : childAccounts) {
            childAccountIds.add(childItem.Id);
        }
        List<Offer__c> allRelatedOffs = [
                SELECT
                        Id,
                        Name,
                        Site_Name__c,
                        Status__c,
                        Offer_Installed_Capacity__c,
                        CreatedDate,
                        Contract_Holder__c,
                        Contract_Holder__r.Name,
                        Base_Contract__r.Name,
                        RecordType.Name,
                        Valid_Until__c,
                        Base_Contract__c,
                        Contract_Start_Date_Offer__c,
                        Risk_Premium_DE__c
                FROM Offer__c
                WHERE (Contract_Holder__c = :accountId
                OR Contract_Holder__c IN :childAccountIds)
                ORDER BY CreatedDate DESC
        ];
        List<PicklistEntry> statusEntries = Offer__c.Status__c.getDescribe().getSobjectField().getDescribe().getPicklistValues();
        List<String> fieldsToSum = new List<String>{
                'Offer_Installed_Capacity__c'
        };
        Set<String> listFilters = new Set<String>();
        Boolean isWhiteListFilter = true;
        if (statusFilter != 'Open') {
            listFilters.add(statusFilter);
        } else {
            isWhiteListFilter = false;
            listFilters.add('Closed Won');
            listFilters.add('Closed Lost');
        }
        msKAMUtility.listViewWrapper wrapper = msKAMUtility.wrapRecords(allRelatedOffs, statusEntries, 'Status__c', isWhiteListFilter, listFilters, fieldsToSum, 'Offer__c');
        wrapper.statusEntryToCountMap.put('Open', 0);
        for (String statusEntry : wrapper.statusEntryToCountMap.keySet()) {
            if (statusEntry != 'Closed Won' && statusEntry != 'Closed Lost' && statusEntry != 'Open') {
                wrapper.statusEntryToCountMap.put('Open',
                        wrapper.statusEntryToCountMap.get('Open') + wrapper.statusEntryToCountMap.get(statusEntry));
            }
        }
        return wrapper;
    }
}