/****************************************************************************************************
* Class BatchResetContractCongaContextTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-08-01
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-08-01       	Init version.
*****************************************************************************************************/

@IsTest
private class BatchResetContractCongaContextTest {

    private static final Date TODAY = Date.today();
    private static final Integer BATCH_SIZE = 30;

    @IsTest
    static void test_single_static_noAmendment() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(1, false);
        enableTriggers();
        Test.startTest();

        update BatchResetContractCongaContext.calculateUpdates(testData.contractIds);

        Test.stopTest();

        testData.updateContracts();
        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(contractItem.Start_Date__c, contractItem.Start_for_Conga_Context__c);
            System.assertEquals(contractItem.End_Date__c, contractItem.End_for_Conga_Context__c);
        }
    }

    @IsTest
    static void test_single_static_Amendment() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(1, true);
        enableTriggers();
        Test.startTest();

        update BatchResetContractCongaContext.calculateUpdates(testData.contractIds);

        Test.stopTest();

        testData.updateContracts();
        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(contractItem.Last_Amentment__r.Amendment_Start__c, contractItem.Start_for_Conga_Context__c);
            System.assertEquals(contractItem.Last_Amentment__r.Amendment_End__c, contractItem.End_for_Conga_Context__c);
        }
    }

    @IsTest
    static void test_bulk_noAmendment() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(BATCH_SIZE, false);
        enableTriggers();
        Test.startTest();

        Database.executeBatch(new BatchResetContractCongaContext(), BATCH_SIZE);

        Test.stopTest();

        testData.updateContracts();
        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(contractItem.Start_Date__c, contractItem.Start_for_Conga_Context__c);
            System.assertEquals(contractItem.End_Date__c, contractItem.End_for_Conga_Context__c);
        }
    }

    @IsTest
    static void test_bulk_Amendment() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(BATCH_SIZE, true);
        enableTriggers();
        Test.startTest();

        Database.executeBatch(new BatchResetContractCongaContext(), BATCH_SIZE);

        Test.stopTest();

        testData.updateContracts();
        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(contractItem.Last_Amentment__r.Amendment_Start__c, contractItem.Start_for_Conga_Context__c);
            System.assertEquals(contractItem.Last_Amentment__r.Amendment_End__c, contractItem.End_for_Conga_Context__c);
        }
    }

    private static CongaContextTestData createTestDataConga(Integer batchSize, Boolean withAmendments) {
        CongaContextTestData testData = new CongaContextTestData();

        testData.Owner = createAccount('Owner');
        insert testData.Owner;

        for (Integer i = 0; i < batchSize; i++) {
            testData.Contracts.add(createContract(TODAY.addYears(-1), TODAY.addYears(1), testData.Owner.Id, 'Name' + i));
        }
        insert testData.Contracts;
        for (Contract__c contractItem : testData.Contracts) {
            testData.contractIds.add(contractItem.Id);
        }
        if (withAmendments) {
            //Faulty Flow design force us to have more test data in place in order to create Amendments - uSe DeClArAtIvE ToOlS.....
            Opportunity opp = createOpportunity('test', testData.Owner.Id);
            insert opp;

            List<Ammendment__c> amendments = new List<Ammendment__c>();
            List<Pricing_Component__c> pcList = new List<Pricing_Component__c>();
            for (Integer i = 0; i < batchSize; i++) {
                amendments.add(createAmendment('test' + i, testData.Contracts[i].Id, TODAY, TODAY.addYears(2)));
                pcList.add(createPricingComponent('test', testData.Contracts[i].Id, testData.Contracts[i].Start_Date__c, testData.Contracts[i].End_Date__c));
            }
            insert pcList;
            insert amendments;

            for (Integer i = 0; i < batchSize; i++) {
                testData.Contracts[i].Last_Amentment__c = amendments[i].Id;
            }
            update testData.Contracts;
        }
        return testData;
    }

    private static Account createAccount(String nameEntry) {
        return new Account (
                Name = nameEntry,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
    }

    private static Opportunity createOpportunity(String nameEntry, Id accountId) {
        return new Opportunity(
                RecordTypeId = '0121v00000034W0AAI',
                Country__c = 'Germany',
                Opportunity_Size__c = 'Portfolio',
                AccountId = accountId,
                Name = nameEntry,
                StageName = 'New',
                CloseDate = TODAY
        );
    }

    private static Contract__c createContract(Date startDate, Date endDate, Id contractHolder, String nameString) {
        String status = 'Active';
        if (endDate < TODAY) {
            status = 'Expired';
        } else if (TODAY < startDate) {
            status = 'Draft';
        }
        return new Contract__c(
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Status__c = status,
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Name = nameString,
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = 'Germany',
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Start_for_Conga_Context__c = TODAY.addYears(-1),
                End_for_Conga_Context__c = TODAY.addDays(-1)
        );
    }

    private static Pricing_Component__c createPricingComponent(String nameEntry, Id contractId, Date startDate, Date endDate) {
        return new Pricing_Component__c(
                Name = nameEntry,
                Contract__c = contractId,
                Start_Date__c = startDate,
                End_Date__c = endDate
        );
    }

    private static Ammendment__c createAmendment(String nameString, Id baseContractId, Date startDate, Date endDate) {
        return new Ammendment__c(
                Name = nameString,
                Base_Contract__c = baseContractId,
                Amendment_Start__c = startDate,
                Amendment_End__c = endDate,
                Security_Handling__c = 'no security anymore',
                Status__c = 'In Progress'
        );
    }

    private class CongaContextTestData {
        Account Owner { get; set; }
        List<Contract__c> Contracts { get; set; }
        Set<Id> contractIds = new Set<Id>();

        public CongaContextTestData() {
            Contracts = new List<Contract__c>();
        }

        public void updateContracts() {
            Contracts = [
                    SELECT Id,
                            Start_Date__c,
                            End_Date__c,
                            Start_for_Conga_Context__c,
                            End_for_Conga_Context__c, Last_Amentment__c,
                            Last_Amentment__r.Amendment_Start__c,
                            Last_Amentment__r.Amendment_End__c
                    FROM Contract__c
                    WHERE Id IN :this.Contracts
            ];
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        TriggerHandlerExtension.disableObject(Ammendment__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Assignment__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Account.SObjectType);
        TriggerHandlerExtension.enableObject(Ammendment__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit_Assignment__c.SObjectType);
    }
}