/**
 * Created by Fabian on 22.03.2021.
 */
@IsTest
public without sharing class msOpportunityHandlerTest {
    @TestSetup
    public static void setup() {
        Account acc = new Account(Name = 'testAcc', BvD_Catalyst_Status__c = 'Green');
        insert acc;

        List<Contract__c> contracts = new List<Contract__c>();
        Contract__c newContract1 = new Contract__c();
        newContract1.RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE;
        newContract1.Start_Date__c = Date.today();
        newContract1.End_Date__c = Date.today().addDays(1);
        newContract1.Status__c = 'Active';
        newContract1.Contract_Holder__c = acc.Id;
        newContract1.Country__c = 'Germany';
        newContract1.Sandbox_Migration_Id__c = 'GermanTestContract1';
        newContract1.Approved__c = true;
        newContract1.Meter_Billing_Type__c = 'Sub-Meter Yearly';
        newContract1.Workflow_Type__c = 'New';
        newContract1.Name = 'DETestContract1';
        contracts.add(newContract1);

        Contract__c newContract2 = new Contract__c();
        newContract2.RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE;
        newContract2.Start_Date__c = Date.today();
        newContract2.End_Date__c = Date.today().addDays(1);
        newContract2.Status__c = 'Active';
        newContract2.Contract_Holder__c = acc.Id;
        newContract2.Country__c = 'Germany';
        newContract2.Sandbox_Migration_Id__c = 'GermanTestContract2';
        newContract2.Approved__c = true;
        newContract2.Meter_Billing_Type__c = 'Sub-Meter Yearly';
        newContract2.Workflow_Type__c = 'New';
        newContract2.Name = 'DETestContract2';
        contracts.add(newContract2);
        insert contracts;

        List<Opportunity> opps = new List<Opportunity>();
        Opportunity opportunity = new Opportunity(
            AccountId = acc.Id,
            Name = 'test without Negotiating Party',
            Amount = 111,
            CloseDate = Date.today() + 7,
            StageName = 'Prospecting',
            Contract__c = newContract1.Id
        );
        opps.add(opportunity);
        insert opps;
    }
    @IsTest
    public static void testUpdateTaskCreateStage() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Contract__c newContract = [SELECT Id FROM Contract__c LIMIT 1];

        List<Opportunity> opps = new List<Opportunity>();
        // Generate Opps relevant for task automation
        for (String recordType : msOpportunityHandler.UK_PPA_AUTOMATED_TASKS_RECORD_TYPES) {
            Opportunity opp = new Opportunity(
                Contract__c = newContract.Id,
                AccountId = acc.Id,
                RecordTypeId = recordType,
                Name = 'test ' + recordType,
                Amount = 111,
                CloseDate = Date.today() + 7,
                StageName = recordType == msOpportunityHandler.SHORT_TERM_NPFA_AUCTION_OPPORTUNITY_REC_TYPE
                    ? 'Analysis'
                    : 'Negotiation'
            );
            System.debug(opp);
            opps.add(opp);
        }

        Test.startTest();
        insert opps;
        Test.stopTest();

        for (Opportunity opp : [SELECT StageName, Tasks_Create_Stage__c, RecordTypeId FROM Opportunity]) {
            System.assertEquals(
                msOpportunityHelper.TASK_CREATE_STAGE_BY_IDENTIFIER.get(opp.RecordTypeId + opp.StageName),
                opp.Tasks_Create_Stage__c
            );
        }
    }
    @IsTest
    public static void getMarketParticipations() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity RfPOpp = new Opportunity(
            RecordTypeId = msOpportunityHandler.CORPORATE_PPA_RFP_OPPORTUNITY_REC_TYPE,
            AccountId = acc.Id,
            Name = 'test RfP',
            Amount = 111,
            CloseDate = Date.today() + 7,
            StageName = 'Submission'
        );
        RfPOpp.Relevant_country_ies__c = 'Germany;Brazil';

        Test.startTest();
        insert RfPOpp;
        List<Market_Participation__c> marketParticipationOfRfPOpp = [
            SELECT Name
            FROM Market_Participation__c
            WHERE Opportunity__c = :RfPOpp.Id
        ];
        RfPOpp.Relevant_country_ies__c = 'Germany';
        update RfPOpp;
        List<Market_Participation__c> marketParticipationOfRfPOppAfterUpdate = [
            SELECT Name
            FROM Market_Participation__c
            WHERE Opportunity__c = :RfPOpp.Id
        ];
        Test.stopTest();

        System.assertEquals(2, marketParticipationOfRfPOpp.size());
        System.assertEquals(1, marketParticipationOfRfPOppAfterUpdate.size());
        System.assertEquals('Germany', marketParticipationOfRfPOppAfterUpdate[0].Name);
    }
    @IsTest
    public static void testSetNegotiatingParty() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Account accWNegotiatingParty = new Account(Name = 'W/ Negotiating Party', Negotiating_Party__c = acc.Id);
        insert accWNegotiatingParty;

        List<Opportunity> testOpps = new List<Opportunity>();
        Opportunity opportunityAccWithNegotiatingParty = new Opportunity(
            AccountId = accWNegotiatingParty.Id,
            Name = 'test Negotiating Party',
            Amount = 111,
            CloseDate = Date.today() + 7,
            StageName = 'Prospecting'
        );
        testOpps.add(opportunityAccWithNegotiatingParty);
        Opportunity opportunityAccWithoutNegotiatingParty = new Opportunity(
            AccountId = accWNegotiatingParty.Id,
            Name = 'test without Negotiating Party',
            Amount = 111,
            CloseDate = Date.today() + 7,
            StageName = 'Prospecting'
        );
        testOpps.add(opportunityAccWithoutNegotiatingParty);

        Test.startTest();
        insert testOpps;
        opportunityAccWithoutNegotiatingParty.AccountId = acc.Id;
        update opportunityAccWithoutNegotiatingParty;
        Test.stopTest();

        Opportunity updatedOppWithNegotiatingParty = [
            SELECT Negotiating_Party__c
            FROM Opportunity
            WHERE Id = :opportunityAccWithNegotiatingParty.Id
        ];
        System.assertEquals(acc.Id, updatedOppWithNegotiatingParty.Negotiating_Party__c);
        Opportunity updatedOppWithOwnAccAsNegotiatingParty = [
            SELECT Negotiating_Party__c
            FROM Opportunity
            WHERE Id = :opportunityAccWithoutNegotiatingParty.Id
        ];
        System.assertEquals(acc.Id, updatedOppWithOwnAccAsNegotiatingParty.Negotiating_Party__c);
    }
    @IsTest
    public static void testSetExtensionOrReactivationFlag() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<Contract__c> contract = [SELECT Id FROM Contract__c LIMIT 2];
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'test Negotiating Party',
            Amount = 111,
            CloseDate = Date.today() + 7,
            StageName = 'Prospecting',
            Contract__c = contract[0].Id
        );
        insert opp;

        Test.startTest();
        opp.Contract__c = contract[1].Id;
        update opp;
        Test.stopTest();

        Contract__c updatedContract = [
            SELECT Extension_Reactivation_Started__c
            FROM Contract__c
            WHERE Id = :contract[1].Id
        ];
        System.assertEquals(true, updatedContract.Extension_Reactivation_Started__c);
    }
}