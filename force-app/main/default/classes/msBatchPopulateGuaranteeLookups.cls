/**************************************************************************************************** 
* Class msBatchPopulateGuaranteeLookups 
* 
*   Created By :   Fabian Murk (mindsquare AG) 
*   Create Date :   09.04.2021 
*   Description : 
* 
*   Modification Log: 
*   ------------------------------------------------------------------------------------------------- 
*   * Developer                        Date             Description 
*   * -----------------------------------------------------------------------------------------------                  
*   * Fabian Murk (mindsquare AG)      09.04.2021         Init version.
*****************************************************************************************************/

global with sharing class msBatchPopulateGuaranteeLookups implements Database.Batchable<SObject>{
    public static Set<String> STATKRAFT_ENTITY_NAMES = new Set<String>();
    global Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([
        SELECT Id, SK_Account__c, SK_Issuing_Entity_Lookup__c, SK_On_behalf_of_Lookup__c,
                SK_BeneficiaryList__c, SK_Issuing_Entity__c, SK_On_behalf_of__c
        FROM SK_Security__c
        WHERE (SK_Account__c = NULL AND SK_BeneficiaryList__c != NULL)
        OR (SK_Issuing_Entity_Lookup__c = NULL AND SK_Issuing_Entity__c != NULL)
        OR (SK_On_behalf_of_Lookup__c = NULL AND SK_On_behalf_of__c != NULL)
        ]);
    }
    global void execute(Database.BatchableContext BC, List<SK_Security__c> guarantees) {
        Map<String, Id>statkraftAccountIdsByAccountName = getStatkraftEntityAccountsByNamesMap();
        System.debug(JSON.serializePretty(statkraftAccountIdsByAccountName));
        for (SK_Security__c guarantee : guarantees){
            if (guarantee.SK_Account__c == null) {
                guarantee.SK_Account__c = statkraftAccountIdsByAccountName.get(guarantee.SK_BeneficiaryList__c);
            }
            if (guarantee.SK_Issuing_Entity_Lookup__c == null) {
                guarantee.SK_Issuing_Entity_Lookup__c = statkraftAccountIdsByAccountName.get(guarantee.SK_Issuing_Entity__c);
            }
            if (guarantee.SK_On_behalf_of_Lookup__c == null) {
                guarantee.SK_On_behalf_of_Lookup__c = statkraftAccountIdsByAccountName.get(guarantee.SK_On_behalf_of__c);
            }
        }
        update guarantees;
    }
    global void finish(Database.BatchableContext BC) {

    }

    private static void getStatkraftEntityNames(){
        SObjectField picklistUsingGlobal = SObjectType.SK_Security__c.fields.SK_BeneficiaryList__c.getSobjectField();
        List<PicklistEntry> entries = picklistUsingGlobal.getDescribe().getPicklistValues();
        for (PicklistEntry entry : entries){
            System.debug('PICKLIST ENTRY:');
            System.debug(entry.getLabel());
            System.debug(entry.getValue());
            STATKRAFT_ENTITY_NAMES.add(entry.getValue());
        }
    }
    private static List<Account> getStatkraftEntityAccounts(){
        getStatkraftEntityNames();
        System.debug(JSON.serializePretty(STATKRAFT_ENTITY_NAMES));
        List<Account> statkraftEntityAccounts = [SELECT Id, Name FROM Account WHERE Name IN :STATKRAFT_ENTITY_NAMES];
        System.debug(JSON.serializePretty(statkraftEntityAccounts));
        return statkraftEntityAccounts;
    }
    private static Map<String, Id> getStatkraftEntityAccountsByNamesMap(){
        Map<String, Id> statkraftEntityAccountsByNames = new Map<String, Id>();
        for (Account statkraftEntity : getStatkraftEntityAccounts()){
            statkraftEntityAccountsByNames.put(statkraftEntity.Name, statkraftEntity.Id);
        }
        return statkraftEntityAccountsByNames;
    }
}