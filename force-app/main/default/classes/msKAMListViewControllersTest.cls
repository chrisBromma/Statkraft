/****************************************************************************************************
* Class msKAMListViewControllersTest
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2020-02-17
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2020-02-17       	Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msKAMListViewControllersTest {
    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account DE' LIMIT 1];
        Contract__c contr = [SELECT Id FROM Contract__c WHERE Contract_Holder__c = :acc.Id LIMIT 1];
        Opportunity oppty = new Opportunity(Name='test', Contract__c = contr.Id, StageName = 'Qualified', CloseDate = Date.today());
        insert oppty;
        Opportunity oppty2 = new Opportunity(Name='test', AccountId=acc.Id, StageName = 'Qualified', CloseDate = Date.today());
        insert oppty2;
        Meter__c meter = [SELECT Id FROM Meter__c WHERE Name = 'deMeter1' LIMIT 1];
        List<Case> cases = new List<Case>();
        cases.add(new Case(AccountId = acc.Id, Subject='test'));
        cases.add(new Case(Contract__c = contr.Id, Subject='test'));
        cases.add(new Case(Opportunity__c = oppty.Id, Subject='test'));
        cases.add(new Case(Opportunity__c = oppty2.Id, Subject='test'));
        cases.add(new Case(Meter__c = meter.Id, Subject='test'));
        insert cases;

    }
    @IsTest
    private static void testAllContractListGetters() {
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account DE' LIMIT 1];
        msKAMContractsListViewController.getContracts(acc.Id, 'Draft');
        msKAMContractsListViewController.getContracts(acc.Id, 'In Approval');
        msKAMContractsListViewController.getContracts(acc.Id, 'Active');
        msKAMContractsListViewController.getContracts(acc.Id, 'Expired');
    }
    @IsTest
    private static void testAllCasesListGetters() {
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account DE' LIMIT 1];
        msKAMCasesListViewController.getCases(acc.Id, 'New');
        msKAMCasesListViewController.getCases(acc.Id, 'In Progress');
        msKAMCasesListViewController.getCases(acc.Id, 'Closed');
    }
    @IsTest
    private static void testAllOppListGetters() {
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account DE' LIMIT 1];
        msKAMOpportunitiesListViewController.getOpportunities(acc.Id, 'Qualification');
    }
    @IsTest
    private static void testAllOffListGetters() {
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account DE' LIMIT 1];
        msKAMOffersListViewController.getOffers(acc.Id, 'Sent');
        msKAMOffersListViewController.getOffers(acc.Id, 'Open');
    }
    @IsTest
    private static void testAllContactGetters() {
        Account acc = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account DE' LIMIT 1];
        msKAMContactsListViewController.getContacts(acc.Id,'Commercial Contact');
        msKAMContactsListViewController.getContacts(acc.Id,'Contractual Contact');
        msKAMContactsListViewController.getContacts(acc.Id,'Technical Contact');
        msKAMContactsListViewController.getContacts(acc.Id,'Customer Portal');
    }
}