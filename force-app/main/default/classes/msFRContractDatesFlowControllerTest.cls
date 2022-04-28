/****************************************************************************************************
* Class msFRContractDatesFlowControllerTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-08-02
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)	            2019-08-02       	Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msFRContractDatesFlowControllerTest {
    @TestSetup
    private static void setup() {
        Account account = new Account(Name = 'Test Account');
        insert account;
        Id contrPPARecTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId();
        Contract__c contract = new Contract__c( Name = 'Test Contract',
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addDays(800),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = account.Id,
                DurationMonths__c = 10,
                DurationYears__c = 1,
                Country__c = 'France',
                RecordTypeId = contrPPARecTypeId);
        insert contract;
        Id pcRecTypeId = Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Floating_Energy_Price').getRecordTypeId();
        Pricing_Component__c nonSSP = new Pricing_Component__c( Name='Test NonSSP',
                Contract__c = contract.Id,
                Index_Price__c = 'Monthly M0',
                RecordTypeId = pcRecTypeId,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today());
        insert nonSSP;
        Pricing_Component__c SSP = new Pricing_Component__c(    Name='Test SSP',
                Contract__c = contract.Id,
                Index_Price__c = 'SSP',
                RecordTypeId = pcRecTypeId,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today());
        insert SSP;

    }
    @IsTest
    private static void testGetters() {
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
        System.assertEquals(true,msFRContractDatesFlowController.getStatusOk(contract.Id));
        msFRContractDatesFlowController.getOptions(contract.Id);
    }
    @IsTest
    private static void testLogic() {
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
        msFRContractDatesFlowController.handleInput(contract.Id, Date.today().addDays(1), 'Estimated Commissioning Date');
        msFRContractDatesFlowController.handleInput(contract.Id, Date.today().addDays(1), 'Confirmed Commissioning Date');
        msFRContractDatesFlowController.handleInput(contract.Id, Date.today().addDays(1), 'Estimated Commercial Operations Date');
        msFRContractDatesFlowController.handleInput(contract.Id, Date.today().addDays(1), 'Confirmed Commercial Operations Date');
    }
}