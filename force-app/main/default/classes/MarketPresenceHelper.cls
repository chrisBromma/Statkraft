public with sharing class MarketPresenceHelper {
    //Trigger Maps/Lists
    private List<Market_Presence__c> triggerOld;
    private List<Market_Presence__c> triggerNew;
    private Map<Id, Market_Presence__c> oldMap;
    private Map<Id, Market_Presence__c> newMap;

    public MarketPresenceHelper(
            List<Market_Presence__c> oldList,
            List<Market_Presence__c> newList,
            Map<Id, Market_Presence__c> mapOld,
            Map<Id, Market_Presence__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    public MarketPresenceHelper() {
    }

    //SOQL Maps
    public Map<Id, Market_Presence__c> marketPresenceMap = new Map<Id, Market_Presence__c>();

    //DML Lists
    public Map<Id, Account> accountUpdateMap = new Map<Id, Account>();

    //All Helper Variables for Electricity Generation Categorization
    private ListMapContainer egc_marketPresencesByAccountId = new ListMapContainer(Market_Presence__c.SObjectType);
    private Set<Id> egc_accountIds = new Set<Id>();
    
    @TestVisible private Double GWH_300 = 300.0;
    @TestVisible private Double GWH_100 = 100.0;
    @TestVisible private Double GWH_50 = 50.0;
    @TestVisible private Double GWH_0 = 0.0;

    @TestVisible private String GWH_CATEGORY_GREATER_300 = '>300 GWh';
    @TestVisible private String GWH_CATEGORY_100_TO_300 = '100-300 GWh';
    @TestVisible private String GWH_CATEGORY_50_TO_100 = '50-99 GWh';
    @TestVisible private String GWH_CATEGORY_0_TO_49 = '0-49 GWh';

    //SOQL Methods
    public void load_Market_Presences(){
        if (!egc_accountIds.isEmpty()) {
            marketPresenceMap = new Map<Id, Market_Presence__c>([
                SELECT Id, Electricity_consumption_generation_p_a__c, Account__c
                FROM Market_Presence__c
                WHERE Account__c IN :egc_accountIds
            ]);
        }
    }

    // Electricity Generation Categorization
    public void egc_identifyAccountsOfUpdatedMarketPresences(){
        for (Market_Presence__c mp : TriggerNew) {
            egc_accountIds.add(mp.Account__c);
        }
    }

    public void egc_buildDataModel(){
        if (!egc_accountIds.isEmpty()) {
            for (Market_Presence__c mp : marketPresenceMap.values()) {
                egc_marketPresencesByAccountId.addToMap(mp.Account__c, mp);
            }
        }
    }

    public void egc_calculateElectricityConsumptionCategory(Market_Presence__c marketPresence){
        Double electricityGeneration = 0.0;
        for (Market_Presence__c mp : (List<Market_Presence__c>) egc_marketPresencesByAccountId.get(marketPresence.Account__c)) {
            if (mp.Electricity_consumption_generation_p_a__c != null) {
                electricityGeneration += mp.Electricity_consumption_generation_p_a__c;
            }
        }

        String electricityGenerationCategory;
        if (electricityGeneration > GWH_300) {
            electricityGenerationCategory = GWH_CATEGORY_GREATER_300;
        } else if(electricityGeneration >= GWH_100){
            electricityGenerationCategory = GWH_CATEGORY_100_TO_300;
        } else if(electricityGeneration >= GWH_50){
            electricityGenerationCategory = GWH_CATEGORY_50_TO_100;
        } else if(electricityGeneration > GWH_0){
            electricityGenerationCategory = GWH_CATEGORY_0_TO_49;
        } else if(electricityGeneration == GWH_0){
            electricityGenerationCategory = null;
        }
        accountUpdateMap.put(
            marketPresence.Account__c,
            new Account(
                Id = marketPresence.Account__c, 
                YearlyElectricityConsumption__c = electricityGenerationCategory
            ));
    }
}