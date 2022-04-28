/****************************************************************************************************
* Class msBatchTerminateOffersTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-09-01
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-09-01       	Init version.
*****************************************************************************************************/

@IsTest
private class msBatchTerminateOffersTest {

    static final Date THIS_DAY = Date.today();
    static final String PPA_CONTRACT_RECORD_TYPE =
            Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId();

    @TestSetup
    static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    static void testOneOffer() {
        Account randomAccount = [SELECT Id FROM Account LIMIT 1];
        Contract__c randomContract = [SELECT Id FROM Contract__c LIMIT 1];
        Opportunity dummyOpp = new Opportunity(
                Name = 'Test',
                StageName = 'Analysis',
                CloseDate = Date.today()
        );
        insert dummyOpp;
        insert new Offer__c(
                Base_Contract__c = randomContract.Id,
                Workflow_Type__c = 'Cancellation Amendment',
                Status__c = 'Document Generation',
                Valid_Until__c = Date.today().addDays(-1),
                Opportunity__c = dummyOpp.Id,
                Contract_Holder__c = randomAccount.Id,
                Reason_Offer_Lost__c = 'Price',
                Third_Party_Contract__c = true
        );
        Test.startTest();
        Database.executeBatch(new msBatchTerminateOffers(), 200);
        Test.stopTest();
        List<Offer__c> listShouldBeEmpty = [
                SELECT Id, Valid_Until__c
                FROM Offer__c
                WHERE Workflow_Type__c = 'Cancellation Amendment'
                AND Valid_Until__c = YESTERDAY
                AND Status__c != 'Closed Won'
                AND Status__c != 'Rejected - New Offer'
                AND Status__c != 'Closed Lost'
        ];
        System.assert(listShouldBeEmpty.isEmpty(), 'The batch did not terminate the offer');
    }

    @IsTest
    static void testBulkOffers() {

        Account randomAccount = [SELECT Id FROM Account LIMIT 1];
        List<Contract__c> dummyContracts = new List<Contract__c>();
        List<Opportunity> dummyOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 50; i++) {
            dummyContracts.add(new Contract__c(
                    Name = 'Test ' + i,
                    Contract_Holder__c = randomAccount.Id,
                    RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract ' + i,
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Settlement_SubModel__c = null
            ));
            dummyOpportunities.add(new Opportunity(
                    Name = 'Test',
                    StageName = 'Analysis',
                    CloseDate = Date.today()
            ));
        }
        insert dummyContracts;
        insert dummyOpportunities;

        List<Offer__c> bulkOffers = new List<Offer__c>();
        for (Integer i = 0; i < 50; i++) {
            bulkOffers.add(new Offer__c(
                    Base_Contract__c = dummyContracts[i].Id,
                    Opportunity__c = dummyOpportunities[i].Id,
                    Workflow_Type__c = 'Cancellation Amendment',
                    Status__c = 'Document Generation',
                    Valid_Until__c = Date.today().addDays(-1),
                    Contract_Holder__c = randomAccount.Id,
                    Reason_Offer_Lost__c = 'Price',
                    Third_Party_Contract__c = true
            ));
        }
        insert bulkOffers;

        Test.startTest();
        Database.executeBatch(new msBatchTerminateOffers(), 50);
        Test.stopTest();
        List<Offer__c> listShouldBeEmpty = [
                SELECT Id, Valid_Until__c
                FROM Offer__c
                WHERE Workflow_Type__c = 'Cancellation Amendment'
                AND Valid_Until__c = YESTERDAY
                AND Status__c != 'Closed Won'
                AND Status__c != 'Rejected - New Offer'
                AND Status__c != 'Closed Lost'
        ];
        System.assert(listShouldBeEmpty.isEmpty(), 'The batch did not terminate the offers');
    }
}