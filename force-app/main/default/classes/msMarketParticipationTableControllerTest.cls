/****************************************************************************************************
 * Class msMarketParticipationTableControllerTest
 *
 *   Created By :   Fabian Murk (mindsquare AG)
 *   Create Date :   24.03.2021
 *   Description :
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        Date             Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Murk (mindsquare AG)      24.03.2021       Init version.
 *****************************************************************************************************/

@IsTest
public with sharing class msMarketParticipationTableControllerTest {
    @TestSetup
    public static void testSetup() {
        Account account = new Account(Name = 'TestAcc');
        insert account;
        Opportunity opportunity = new Opportunity(
            AccountId = account.Id,
            Name = 'TestOpp',
            StageName = 'Prospecting',
            CloseDate = Date.today() + 1,
            Relevant_country_ies__c = 'Germany;France;Italy',
            RecordTypeId = msOpportunityHandler.CORPORATE_PPA_RFP_OPPORTUNITY_REC_TYPE
        );
        insert opportunity;
    }
    @IsTest
    public static void testGetMarketParticipations() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Market_Participation__c> marketParticipations = msMarketParticipationTableController.getMarketParticipations(
            opportunity.Id
        );
        Test.stopTest();

        // Should be 3 records, because for each country in Relevant_country_ies__c one record is created by the trigger.
        System.assertEquals(3, marketParticipations.size());
    }
    @IsTest
    public static void testSaveMarketParticipations() {
        Market_Participation__c marketParticipation = [SELECT Id, Name FROM Market_Participation__c LIMIT 1];
        marketParticipation.msRfPMTParticipating__c = false;
        marketParticipation.msRfPMTNotParticipatingReason__c = 'Not participating';
        marketParticipation.msRfPAssetOwnersParticipating__c = true;

        Test.startTest();
        msMarketParticipationTableController.saveMarketParticipation(JSON.serialize(marketParticipation));
        Test.stopTest();

        Market_Participation__c marketParticipationUpdated = [
            SELECT msRfPMTParticipating__c, msRfPMTNotParticipatingReason__c, msRfPAssetOwnersParticipating__c
            FROM Market_Participation__c
            WHERE Id = :marketParticipation.Id
        ];
        System.assertEquals(false, marketParticipationUpdated.msRfPMTParticipating__c);
        System.assertEquals('Not participating', marketParticipationUpdated.msRfPMTNotParticipatingReason__c);
        System.assertEquals(true, marketParticipationUpdated.msRfPAssetOwnersParticipating__c);
    }
    @IsTest
    public static void testCreateOpportunity() {
        Id userId = UserInfo.getUserId();
        Opportunity parentOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Market_Participation__c marketParticipation = [
            SELECT Id, Name, msPreferredVolumesGWhpa__c
            FROM Market_Participation__c
            LIMIT 1
        ];

        Test.startTest();
        msMarketParticipationTableController.createOpportunity(userId, parentOpportunity.Id, marketParticipation);
        Test.stopTest();

        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE Parent_Opportunity__c = :parentOpportunity.Id];
        System.assert(newOpp != null);
    }
    @IsTest
    public static void testCheckForDuplicates() {
        Boolean duplicateExistsBefore;
        Boolean duplicateExistsAfter;
        Id userId = UserInfo.getUserId();
        Opportunity parentOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Market_Participation__c marketParticipation = [
            SELECT Id, Name, msPreferredVolumesGWhpa__c
            FROM Market_Participation__c
            LIMIT 1
        ];

        Test.startTest();
        duplicateExistsBefore = msMarketParticipationTableController.checkForOppDuplicate(
            parentOpportunity.Id,
            marketParticipation
        );
        msMarketParticipationTableController.createOpportunity(userId, parentOpportunity.Id, marketParticipation);
        duplicateExistsAfter = msMarketParticipationTableController.checkForOppDuplicate(
            parentOpportunity.Id,
            marketParticipation
        );
        Test.stopTest();

        System.assertEquals(false, duplicateExistsBefore);
        System.assertEquals(true, duplicateExistsAfter);
    }
}