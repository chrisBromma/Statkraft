/****************************************************************************************************
 * Class MarketPresenceHandler
 *
 *   Create By	:   Fabian Murk (mindsquare AG)
 *   Create Date	:   15.12.2021
 *   Description	:	egc_ - Electricity Generation Categorization
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                          	    Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Murk (mindsquare AG)		        15.12.2021       	Init version.
 *****************************************************************************************************/

public without sharing class MarketPresenceHandler extends TriggerHandlerExtension {
    MarketPresenceHelper Helper;

    // Constructor
    public MarketPresenceHandler() {
        super();
        Helper = new MarketPresenceHelper(
                (List<Market_Presence__c>) Trigger.old,
                (List<Market_Presence__c>) Trigger.new,
                (Map<Id, Market_Presence__c>) Trigger.oldMap,
                (Map<Id, Market_Presence__c>) Trigger.newMap
        );
    }

    public override void bulkAfter() {
        if (Trigger.isUpdate) {
            Helper.egc_identifyAccountsOfUpdatedMarketPresences();
        }
        Helper.load_Market_Presences();
        Helper.egc_buildDataModel();
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        Market_Presence__c newMarketPresence = (Market_Presence__c) obj;

        Helper.egc_calculateElectricityConsumptionCategory(newMarketPresence);
    }

    public override void andFinally() {
        if (!Helper.accountUpdateMap.values().isEmpty()) {
            TriggerHandlerExtension.disableObject(Market_Presence__c.SObjectType);
            update Helper.accountUpdateMap.values();
            TriggerHandlerExtension.enableObject(Market_Presence__c.SObjectType);
        }
    }
}