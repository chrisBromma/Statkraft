/**
 * Created by Fabian on 03.03.2021.
 * @testedBy msKAMProductNeedSelectorControllerTest
 * @testedBy msOpportunityHandlerTest
 */

public without sharing class msOpportunityHandler extends TriggerHandlerExtension {
    public static Set<Opportunity> OPPS_RELEVANT_FOR_MARKET_PARTICIPATION =
            new Set<Opportunity>();
    public static Map<Id, List<Market_Participation__c>> MARKET_PARTICIPATIONS_BY_OPP_ID =
            new Map<Id, List<Market_Participation__c>>();
    public static Map<String, Market_Participation__c> MARKET_PARTICIPATIONS_TO_INSERT =
            new Map<String, Market_Participation__c>();
    public static Map<Id, Market_Participation__c> MARKET_PARTICIPATIONS_TO_DELETE =
            new Map<Id, Market_Participation__c>();

    public static Set<Id> ACCS_RELEVANT_FOR_NEGOTIATING_PARTY_AUTOMATION =
            new Set<Id>();
    public static Map<Id, Account> ACCOUNTS_BY_ACC_ID =
            new Map<Id, Account>();

    public static Set<Id> CONTRACTS_RELEVANT_FOR_EXTENSION_OR_REACTIVATION_UPDATE =
            new Set<Id>();
    public static Map<Id, Contract__c> CONTRACTS_BY_CONTRACT_ID =
            new Map<Id, Contract__c>();

    public static final Id CORPORATE_PPA_RFP_OPPORTUNITY_REC_TYPE =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Corporate_PPA_RfP').getRecordTypeId();
    public static final Id SHORT_TERM_BROKER_PPA_OPPORTUNITY_REC_TYPE =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Short_Term_Broker_PPA').getRecordTypeId();
    public static final Id LONG_TERM_PPA_OPPORTUNITY_REC_TYPE =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Long_Term_PPA').getRecordTypeId();
    public static final Id SHORT_TERM_NPFA_AUCTION_OPPORTUNITY_REC_TYPE =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Short_Term_NPFA_Auction').getRecordTypeId();
    public static final Id UK_PPA_EXTENSION_OPPORTUNITY_REC_TYPE =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('UK_PPA_Extension').getRecordTypeId();
    public static final List<Id> UK_PPA_AUTOMATED_TASKS_RECORD_TYPES = new List<Id>{
            SHORT_TERM_BROKER_PPA_OPPORTUNITY_REC_TYPE,
            LONG_TERM_PPA_OPPORTUNITY_REC_TYPE,
            SHORT_TERM_NPFA_AUCTION_OPPORTUNITY_REC_TYPE,
            UK_PPA_EXTENSION_OPPORTUNITY_REC_TYPE
    };

    // Constructor
    public msOpportunityHandler() {
        super();
    }


    public override void bulkBefore() {
        if(Trigger.isInsert||Trigger.isUpdate){
            for (SObject obj : Trigger.new) {
                Opportunity opp = (Opportunity) obj;
                if (opp.RecordTypeId == CORPORATE_PPA_RFP_OPPORTUNITY_REC_TYPE) {
                    OPPS_RELEVANT_FOR_MARKET_PARTICIPATION.add(opp);
                }
                if (opp.Country__c == 'India' || opp.Country__c == 'Germany') {
                    ACCS_RELEVANT_FOR_NEGOTIATING_PARTY_AUTOMATION.add(opp.AccountId);
                }
                if (Trigger.isInsert) {
                    if (opp.Contract__c != null) {
                        CONTRACTS_RELEVANT_FOR_EXTENSION_OR_REACTIVATION_UPDATE.add(opp.Contract__c);
                    }
                }
                if (Trigger.isUpdate) {
                    Opportunity oldOpp = (Opportunity) Trigger.oldMap.get(opp.Id);
                    if (opp.Contract__c != null && opp.Contract__c != oldOpp.Contract__c) {
                        CONTRACTS_RELEVANT_FOR_EXTENSION_OR_REACTIVATION_UPDATE.add(opp.Contract__c);
                    }
                }
            }
        }
        if (!OPPS_RELEVANT_FOR_MARKET_PARTICIPATION.isEmpty()) {
            List<Market_Participation__c> marketParticipations = [SELECT Id, Name, Opportunity__c FROM Market_Participation__c WHERE Opportunity__c IN :OPPS_RELEVANT_FOR_MARKET_PARTICIPATION];
            for (Market_Participation__c marketParticipation : marketParticipations) {
                if (!MARKET_PARTICIPATIONS_BY_OPP_ID.containsKey(marketParticipation.Opportunity__c)) {
                    MARKET_PARTICIPATIONS_BY_OPP_ID.put(marketParticipation.Opportunity__c, new List<Market_Participation__c>());
                }
                MARKET_PARTICIPATIONS_BY_OPP_ID.get(marketParticipation.Opportunity__c).add(marketParticipation);
            }
        }
        if (!ACCS_RELEVANT_FOR_NEGOTIATING_PARTY_AUTOMATION.isEmpty()) {
            ACCOUNTS_BY_ACC_ID = new Map<Id, Account>([SELECT Id, Negotiating_Party__c FROM Account WHERE Id IN :ACCS_RELEVANT_FOR_NEGOTIATING_PARTY_AUTOMATION]);
        }
        if (!CONTRACTS_RELEVANT_FOR_EXTENSION_OR_REACTIVATION_UPDATE.isEmpty()) {
            CONTRACTS_BY_CONTRACT_ID = new Map<Id, Contract__c>([SELECT Id, Extension_Reactivation_Started__c FROM Contract__c WHERE Id IN :CONTRACTS_RELEVANT_FOR_EXTENSION_OR_REACTIVATION_UPDATE]);
        }


        if (Trigger.isUpdate && msKAMProductNeedSelectorController.disableOpportunityTriggerToUpdateLinks==false) {
            Map<Id, Id>oppIdToCustomerNeed = new Map<Id, Id>();
            Map<Id, Opportunity>oldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
            for (Opportunity newOpportunity : (List<Opportunity>) Trigger.new) {

                if (newOpportunity.Customer_Need_in_scope_primary__c != null &&
                        newOpportunity.Customer_Need_in_scope_primary__c != oldOppMap.get(newOpportunity.Id).Customer_Need_in_scope_primary__c) {
                    oppIdToCustomerNeed.put(newOpportunity.Id, newOpportunity.Customer_Need_in_scope_primary__c);
                }
            }
            if (oppIdToCustomerNeed.size() > 0) {
                Map<Id, Product_Need_Link__c> oppIdToNewCustomerNeed = msKAMProductNeedSelectorController.saveLinks(oppIdToCustomerNeed);

                for (Opportunity newOpportunity : (List<Opportunity>) Trigger.new) {
                    if (oppIdToNewCustomerNeed.get(newOpportunity.Id) != null) {
                        newOpportunity.Customer_Need_in_scope_primary__c = oppIdToNewCustomerNeed.get(newOpportunity.Id).Id;
                    }
                }
            }
        }
    }

    //public override void bulkAfter() { addToLoopCount();}

    public override void beforeInsert(SObject obj) {
        addToLoopCount();
        Opportunity insertedOpp = (Opportunity) obj;
        if (UK_PPA_AUTOMATED_TASKS_RECORD_TYPES.contains(insertedOpp.RecordTypeId)) {
            msOpportunityHelper.updateTaskCreateStage(insertedOpp);
        }
        if (ACCS_RELEVANT_FOR_NEGOTIATING_PARTY_AUTOMATION.contains(insertedOpp.AccountId)) {
            msOpportunityHelper.setNegotiatingParty(insertedOpp);
        }
        if (CONTRACTS_RELEVANT_FOR_EXTENSION_OR_REACTIVATION_UPDATE.contains(insertedOpp.Contract__c)) {
            msOpportunityHelper.setExtensionOrReactivationFlag(insertedOpp);
        }
    }

    public override void beforeUpdate(SObject oldObj, SObject obj) {
        addToLoopCount();

        Opportunity oldOpp = (Opportunity) oldObj;
        Opportunity updatedOpp = (Opportunity) obj;

        if (UK_PPA_AUTOMATED_TASKS_RECORD_TYPES.contains(updatedOpp.RecordTypeId)) {
            msOpportunityHelper.updateTaskCreateStage(updatedOpp);
        }
        if (ACCS_RELEVANT_FOR_NEGOTIATING_PARTY_AUTOMATION.contains(updatedOpp.AccountId)
                && oldOpp.AccountId != updatedOpp.AccountId) {
            msOpportunityHelper.setNegotiatingParty(updatedOpp);
        }
        if (CONTRACTS_RELEVANT_FOR_EXTENSION_OR_REACTIVATION_UPDATE.contains(updatedOpp.Contract__c)) {
            msOpportunityHelper.setExtensionOrReactivationFlag(updatedOpp);
        }
    }

    //public override void beforeDelete(SObject obj) { addToLoopCount();}

    public override void afterInsert(SObject obj) {
        addToLoopCount();
        Opportunity insertedOpp = (Opportunity) obj;
        if (insertedOpp.RecordTypeId == CORPORATE_PPA_RFP_OPPORTUNITY_REC_TYPE && insertedOpp.Relevant_country_ies__c != null) {
            MARKET_PARTICIPATIONS_TO_INSERT = msOpportunityHelper.getMarketParticipationsToCreate(insertedOpp);
            MARKET_PARTICIPATIONS_TO_DELETE = msOpportunityHelper.getMarketParticipationsToDelete(insertedOpp);
        }
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        addToLoopCount();

        Opportunity oldOpp = (Opportunity) oldObj;
        Opportunity updatedOpp = (Opportunity) obj;

        if (updatedOpp.RecordTypeId == CORPORATE_PPA_RFP_OPPORTUNITY_REC_TYPE) {
            MARKET_PARTICIPATIONS_TO_INSERT = msOpportunityHelper.getMarketParticipationsToCreate(updatedOpp);
            MARKET_PARTICIPATIONS_TO_DELETE = msOpportunityHelper.getMarketParticipationsToDelete(updatedOpp);
        }
    }

    //public override void afterDelete(SObject obj) { addToLoopCount();}

    public override void andFinally() {
        if (Trigger.isAfter) {
            if (!MARKET_PARTICIPATIONS_TO_INSERT.values().isEmpty()) {
                insert MARKET_PARTICIPATIONS_TO_INSERT.values();
            }
            if (!MARKET_PARTICIPATIONS_TO_DELETE.values().isEmpty()) {
                delete MARKET_PARTICIPATIONS_TO_DELETE.values();
            }
            if (!CONTRACTS_BY_CONTRACT_ID.values().isEmpty()) {
                update CONTRACTS_BY_CONTRACT_ID.values();
            }
        }
    }
}