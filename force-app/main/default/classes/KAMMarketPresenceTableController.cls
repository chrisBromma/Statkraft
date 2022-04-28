public without sharing class KAMMarketPresenceTableController {
    @AuraEnabled
    public static List<Object> getMarketPresence(Id recordId) {
        List<Market_Presence__c> marketPresences = [
            SELECT Id, Name, Electricity_consumption_generation_p_a__c
            FROM Market_Presence__c
            WHERE Account__c = :recordId
        ];
        List<MarketPresenceWrapper> marketPresenceWrappers = new List<MarketPresenceWrapper>();
        for (Market_Presence__c mp : marketPresences) {
            marketPresenceWrappers.add(new MarketPresenceWrapper(mp));
        }
        return marketPresenceWrappers;
    }
    @AuraEnabled
    public static void updateMarketPresenceCountry(String marketPresenceCountry) {
        MarketPresenceWrapper marketPresenceWrapper = (MarketPresenceWrapper) JSON.deserialize(marketPresenceCountry, MarketPresenceWrapper.class);

        update new Market_Presence__c(
            Id = marketPresenceWrapper.marketPresenceId, 
            Electricity_consumption_generation_p_a__c = marketPresenceWrapper.electricityConsumptionGenerationGWH
            ); 
    }
    public class MarketPresenceWrapper{
        @AuraEnabled
        public Id marketPresenceId {get; set;}
        @AuraEnabled
        public String marketName {get; set;}
        @AuraEnabled
        public Double electricityConsumptionGenerationGWH {get; set;}
        @AuraEnabled
        public Boolean isChanged {get; set;}

        public MarketPresenceWrapper(Market_Presence__c marketPresence){
            marketPresenceId = marketPresence.Id;
            marketName = marketPresence.Name;
            electricityConsumptionGenerationGWH = marketPresence.Electricity_consumption_generation_p_a__c;
            isChanged = false;
        }
    }
}