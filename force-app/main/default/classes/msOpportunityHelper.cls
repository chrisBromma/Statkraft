/**
 * Created by Fabian on 03.03.2021.
 */

public without sharing class msOpportunityHelper {
    public static Map<String, Integer> TASK_CREATE_STAGE_BY_IDENTIFIER = new Map<String, Integer>{
        msOpportunityHandler.SHORT_TERM_BROKER_PPA_OPPORTUNITY_REC_TYPE + 'Proposal' => 1,
        msOpportunityHandler.SHORT_TERM_BROKER_PPA_OPPORTUNITY_REC_TYPE + 'Negotiation' => 2,
        msOpportunityHandler.SHORT_TERM_BROKER_PPA_OPPORTUNITY_REC_TYPE + 'Approval' => 3,
        msOpportunityHandler.LONG_TERM_PPA_OPPORTUNITY_REC_TYPE + 'Proposal' => 1,
        msOpportunityHandler.LONG_TERM_PPA_OPPORTUNITY_REC_TYPE + 'Negotiation' => 2,
        msOpportunityHandler.LONG_TERM_PPA_OPPORTUNITY_REC_TYPE + 'Review' => 3,
        msOpportunityHandler.LONG_TERM_PPA_OPPORTUNITY_REC_TYPE + 'Approval' => 4,
        msOpportunityHandler.SHORT_TERM_NPFA_AUCTION_OPPORTUNITY_REC_TYPE + 'Analysis' => 1,
        msOpportunityHandler.SHORT_TERM_NPFA_AUCTION_OPPORTUNITY_REC_TYPE + 'Auction' => 2,
        msOpportunityHandler.SHORT_TERM_NPFA_AUCTION_OPPORTUNITY_REC_TYPE + 'Approval' => 3,
        msOpportunityHandler.UK_PPA_EXTENSION_OPPORTUNITY_REC_TYPE + 'Negotiation' => 1
    };

    public static Map<String, Market_Participation__c> getMarketParticipationsToCreate(Opportunity opp) {
        Map<String, Market_Participation__c> marketParticipationsToCreate = new Map<String, Market_Participation__c>();
        List<Market_Participation__c> marketParticipationsOfThisOpp = msOpportunityHandler.MARKET_PARTICIPATIONS_BY_OPP_ID.get(
            opp.Id
        );

        Map<String, Market_Participation__c> nameToMarketParticipation = new Map<String, Market_Participation__c>();
        if (marketParticipationsOfThisOpp != null) {
            for (Market_Participation__c marketParticipation : marketParticipationsOfThisOpp) {
                nameToMarketParticipation.put(marketParticipation.Name, marketParticipation);
            }
        }
        for (String relevantMarket : opp.Relevant_country_ies__c.split(';')) {
            if (nameToMarketParticipation.get(relevantMarket) == null) {
                marketParticipationsToCreate.put(
                    relevantMarket,
                    new Market_Participation__c(Name = relevantMarket, Opportunity__c = opp.Id)
                );
            }
        }
        return marketParticipationsToCreate;
    }
    public static Map<Id, Market_Participation__c> getMarketParticipationsToDelete(Opportunity opp) {
        Map<Id, Market_Participation__c> marketParticipationsToDelete = new Map<Id, Market_Participation__c>();
        List<Market_Participation__c> marketParticipationsOfThisOpp = msOpportunityHandler.MARKET_PARTICIPATIONS_BY_OPP_ID.get(
            opp.Id
        );

        if (marketParticipationsOfThisOpp != null) {
            for (Market_Participation__c marketParticipation : marketParticipationsOfThisOpp) {
                if (!opp.Relevant_country_ies__c.split(';').contains(marketParticipation.Name)) {
                    marketParticipationsToDelete.put(marketParticipation.Id, marketParticipation);
                }
            }
        }
        return marketParticipationsToDelete;
    }
    public static void updateTaskCreateStage(Opportunity opp) {
        String Identifier = opp.RecordTypeId + opp.StageName;
        opp.Tasks_Create_Stage__c = opp.Tasks_Create_Stage__c == null ? 0 : opp.Tasks_Create_Stage__c;
        if (
            TASK_CREATE_STAGE_BY_IDENTIFIER.get(Identifier) != null &&
            TASK_CREATE_STAGE_BY_IDENTIFIER.get(Identifier) > opp.Tasks_Create_Stage__c
        ) {
            opp.Tasks_Create_Stage__c = TASK_CREATE_STAGE_BY_IDENTIFIER.get(Identifier);
        }
    }
    public static void setNegotiatingParty(Opportunity opp) {
        Account acc = msOpportunityHandler.ACCOUNTS_BY_ACC_ID.get(opp.AccountId);
        if (acc != null) {
            //The check above is needed for opportunities created without an account attached
            if (acc.Negotiating_Party__c == null) {
                opp.Negotiating_Party__c = acc.Id;
            } else {
                opp.Negotiating_Party__c = acc.Negotiating_Party__c;
            }
        }
    }
    public static void setExtensionOrReactivationFlag(Opportunity opp) {
        msOpportunityHandler.CONTRACTS_BY_CONTRACT_ID.get(opp.Contract__c).Extension_Reactivation_Started__c = true;
    }
}