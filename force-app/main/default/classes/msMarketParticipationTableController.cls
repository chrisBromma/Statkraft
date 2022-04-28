/****************************************************************************************************
 * Class msMarketParticipationTableController
 *
 *   Created By :   Fabian Murk (mindsquare AG)
 *   Create Date :   02.03.2021
 *   Description :
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        Date             Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Murk (mindsquare AG)      02.03.2021       Init version.
 *****************************************************************************************************/

public without sharing class msMarketParticipationTableController {
    public static Id DOWNSTREAM_OPP = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Downstream_Opportunity')
        .getRecordTypeId();

    @AuraEnabled
    public static List<Market_Participation__c> getMarketParticipations(Id recordId) {
        List<Market_Participation__c> marketParticipations = [
            SELECT
                Id,
                Name,
                msPreferredVolumesGWhpa__c,
                msRfPAssetOwnersNotParticipatingReason__c,
                msRfPAssetOwnersParticipating__c,
                msRfPMilestoneAssetOwnersInfoBids__c,
                msRfPMilestoneMTProjectInfoBids__c,
                msRfPMTNotParticipatingReason__c,
                msRfPMTParticipating__c
            FROM Market_Participation__c
            WHERE Opportunity__c = :recordId
        ];
        return marketParticipations;
    }
    @AuraEnabled
    public static void saveMarketParticipation(String marketParticipation) {
        update (Market_Participation__c) JSON.deserialize(marketParticipation, Market_Participation__c.class);
    }
    @AuraEnabled
    public static Boolean checkForOppDuplicate(Id parentOppId, Market_Participation__c market) {
        List<Opportunity> childOppsWithSameName = new List<Opportunity>();
        childOppsWithSameName = [
            SELECT Id
            FROM Opportunity
            WHERE Parent_Opportunity__c = :parentOppId AND Relevant_country_ies__c = :market.Name
        ];
        Boolean duplicateExists = !childOppsWithSameName.isEmpty();
        return duplicateExists;
    }
    @AuraEnabled
    public static void createOpportunity(Id oppOwner, Id parentOppId, Market_Participation__c market) {
        Opportunity parentOpp = [
            SELECT
                Id,
                Name,
                AccountId,
                Account.Name,
                CloseDate,
                msRfPContractStartDatePreferred__c,
                msRfPTenorPreferred__c,
                msRfPEACRequired__c,
                Relevant_technology_ies_PPA__c,
                Volume_in_GWh_p_a__c,
                Physical_Financial__c,
                PPA_Pricing__c,
                PPA_Profile__c,
                msRfPPlatformConsultantFeeMWh__c,
                RfP_Platform_Consultant_Fee_Fixed_MWh__c,
                CurrencyIsoCode
            FROM Opportunity
            WHERE Id = :parentOppId
        ];
        Date today = Date.today();
        String year = String.valueOf(today.year()).right(2);
        String month = String.valueOf(today.month()).leftPad(2, '0');
        String day = String.valueOf(today.day()).leftPad(2, '0');
        Date endDate = parentOpp.msRfPContractStartDatePreferred__c != null &&
            parentOpp.msRfPTenorPreferred__c != null
            ? (parentOpp.msRfPContractStartDatePreferred__c).addYears(Integer.valueOf(parentOpp.msRfPTenorPreferred__c))
            : null;

        Opportunity childOpp = new Opportunity(
            Name = year + month + day + '_CPPA_RfP_' + parentOpp.Account.Name + '_' + market.Name,
            Parent_Opportunity__c = parentOppId,
            StageName = 'Offer Development',
            LeadSource = 'RfP platform/consultant',
            AccountId = parentOpp.AccountId,
            CloseDate = parentOpp.CloseDate,
            Start_Date__c = parentOpp.msRfPContractStartDatePreferred__c,
            End_Date__c = endDate,
            Product_Origination__c = parentOpp.msRfPEACRequired__c ? 'Green PPA' : 'GreyPower',
            Description = Label.msRfPOppDescription,
            Relevant_country_ies__c = market.Name,
            Relevant_technology_ies_PPA__c = parentOpp.Relevant_technology_ies_PPA__c,
            Volume_in_GWh_p_a__c = market.msPreferredVolumesGWhpa__c,
            Physical_Financial__c = parentOpp.Physical_Financial__c,
            PPA_Pricing__c = parentOpp.PPA_Pricing__c,
            PPA_Profile__c = parentOpp.PPA_Profile__c,
            msRfPPlatformConsultantFeeMWh__c = parentOpp.msRfPPlatformConsultantFeeMWh__c,
            RfP_Platform_Consultant_Fee_Fixed_MWh__c = parentOpp.RfP_Platform_Consultant_Fee_Fixed_MWh__c,
            OwnerId = oppOwner,
            RecordTypeId = DOWNSTREAM_OPP,
            CurrencyIsoCode = parentOpp.CurrencyIsoCode
        );
        insert childOpp;
    }
}