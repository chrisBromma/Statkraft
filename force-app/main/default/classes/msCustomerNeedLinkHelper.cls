/****************************************************************************************************
* Class msCustomerNeedLinkHelper
*
*   Created By	:   Fabian Murk (mindsquare AG)
*   Created Date	:   2021-11-29
*   Description	:	mpa_ - Market Presence Automation
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Fabian Murk (mindsquare AG)	                    2021-11-29          Init version.
*****************************************************************************************************/
public without sharing class msCustomerNeedLinkHelper {
    
    private List<Product_need_Link__c> triggerOld;
    private List<Product_need_Link__c> triggerNew;
    private Map<Id, Product_need_Link__c> oldMap;
    private Map<Id, Product_need_Link__c> newMap;

    public msCustomerNeedLinkHelper(List<Product_need_Link__c> oldList,
            List<Product_need_Link__c> newList,
            Map<Id, Product_need_Link__c> mapOld,
            Map<Id, Product_need_Link__c> mapNew) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //SOQL Maps
    private Map<Id, Account> accountMap = new Map<Id, Account>();

    //DML Lists/Maps
    public List<Account> accountsToUpdate = new List<Account>();

    //Market Presence Automation
    public Set<Id> mpa_accountIds = new Set<Id>();

    //SOQL methods
    public void load_Accounts(){
        if(!mpa_accountIds.isEmpty()){
            accountMap = new Map<Id, Account>([
                SELECT Market_Presence__c
                FROM Account
                WHERE Id IN :mpa_accountIds
            ]);
        }
    }

    // mpa - Market Presence Automation logic
    public void mpa_indentifyCustomerNeedAccounts(){
        for (Product_need_Link__c cnLink : triggerNew) {
            mpa_accountIds.add(cnLink.Account__c);
        }
    }

    public void mpa_addCountryToMarketPresenceIfNeeded(Product_need_Link__c newCustomerNeedLink){
        Account accOfCustomerNeedLink = accountMap.get(newCustomerNeedLink.Account__c);
        String market = newCustomerNeedLink.Country__c;
        if (accOfCustomerNeedLink != null && market != 'Other') {
            if (accOfCustomerNeedLink.Market_Presence__c == null) {
                accOfCustomerNeedLink.Market_Presence__c = market;
            } else {
                List<String> marketPresenceCountries = accOfCustomerNeedLink.Market_Presence__c.split(';');
                if (!marketPresenceCountries.contains(market)) {
                    accOfCustomerNeedLink.Market_Presence__c += ';' + market;
                }
            }
            accountsToUpdate.add(accOfCustomerNeedLink);
        }
    }
}