/****************************************************************************************************
* Class BatchCalculateCapAndProdOnContractsTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-30
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-30       	Init version.
*****************************************************************************************************/

@IsTest
private class BatchCalculateCapAndProdOnContractsTest {
    static final Date today = Date.today();
    static final Integer BATCH_SIZE = 50;


    @IsTest
    static void testCalculationViaAssignments_single_static_parent() {
        disableTriggers();
        AssignmentTestData testData = createTestDataAssignments(1);
        enableTriggers();

        List<Contract__c> parents = new List<Contract__c>();
        Set<Id> contractIds = new Set<Id>();
        for (Contract__c contractItem : testData.Contracts) {
            contractIds.add(contractItem.Id);
            parents.add(createContract(today, today, contractItem.Contract_Holder__c, 'parent ' + contractItem.Id));
        }
        insert parents;
        for (Integer i = 0; i < testData.Contracts.size(); i++) {
            testData.Contracts[i].Parent_Contract__c = parents[i].Id;
        }
        update testData.Contracts;

        Test.startTest();

        BatchCalculateCapAndProdOnContracts.checkForUpdateAndExecuteUpdate(contractIds);

        Test.stopTest();

        parents = [
                SELECT Installed_Capacity__c, Active_Installed_Capacity__c,
                        Active_Installed_Capacity_Conga__c, Installed_Annual_Production__c,
                        Active_Installed_Annual_Production__c, Active_Installed_Production_Conga__c
                FROM Contract__c
                WHERE Id IN :parents
        ];

        for (Contract__c contractItem : parents) {
            System.assertEquals(2, contractItem.Installed_Capacity__c);
            System.assertEquals(0, contractItem.Active_Installed_Capacity__c);
            System.assertEquals(1, contractItem.Active_Installed_Capacity_Conga__c);
            System.assertEquals(24, contractItem.Installed_Annual_Production__c);
            System.assertEquals(0, contractItem.Active_Installed_Annual_Production__c);
            System.assertEquals(12, contractItem.Active_Installed_Production_Conga__c);
        }
    }

    @IsTest
    static void testCalculationViaAssignments_single_static() {
        disableTriggers();
        AssignmentTestData testData = createTestDataAssignments(1);
        enableTriggers();

        Set<Id> contractIds = new Set<Id>();
        for (Contract__c contractItem : testData.Contracts) {
            contractIds.add(contractItem.Id);
        }
        Test.startTest();

        BatchCalculateCapAndProdOnContracts.checkForUpdateAndExecuteUpdate(contractIds);

        Test.stopTest();

        testData.updateContracts();

        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(2, contractItem.Installed_Capacity__c);
            System.assertEquals(0, contractItem.Active_Installed_Capacity__c);
            System.assertEquals(1, contractItem.Active_Installed_Capacity_Conga__c);
            System.assertEquals(24, contractItem.Installed_Annual_Production__c);
            System.assertEquals(0, contractItem.Active_Installed_Annual_Production__c);
            System.assertEquals(12, contractItem.Active_Installed_Production_Conga__c);
        }
    }

    @IsTest
    static void testCalculationViaAssignments_batch_static() {
        disableTriggers();
        AssignmentTestData testData = createTestDataAssignments(BATCH_SIZE);
        enableTriggers();

        Set<Id> contractIds = new Set<Id>();
        for (Contract__c contractItem : testData.Contracts) {
            contractIds.add(contractItem.Id);
        }
        Test.startTest();

        BatchCalculateCapAndProdOnContracts.checkForUpdateAndExecuteUpdate(contractIds);

        Test.stopTest();

        testData.updateContracts();

        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(2, contractItem.Installed_Capacity__c);
            System.assertEquals(0, contractItem.Active_Installed_Capacity__c);
            System.assertEquals(1, contractItem.Active_Installed_Capacity_Conga__c);
            System.assertEquals(24, contractItem.Installed_Annual_Production__c);
            System.assertEquals(0, contractItem.Active_Installed_Annual_Production__c);
            System.assertEquals(12, contractItem.Active_Installed_Production_Conga__c);
        }
    }

    @IsTest
    static void testCalculationViaAssignments_batch() {
        disableTriggers();
        AssignmentTestData testData = createTestDataAssignments(BATCH_SIZE);
        enableTriggers();

        Set<Id> contractIds = new Set<Id>();
        for (Contract__c contractItem : testData.Contracts) {
            contractIds.add(contractItem.Id);
        }
        Test.startTest();

        Database.executeBatch(new BatchCalculateCapAndProdOnContracts(), BATCH_SIZE);

        Test.stopTest();

        testData.updateContracts();

        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(2, contractItem.Installed_Capacity__c);
            System.assertEquals(0, contractItem.Active_Installed_Capacity__c);
            System.assertEquals(1, contractItem.Active_Installed_Capacity_Conga__c);
            System.assertEquals(24, contractItem.Installed_Annual_Production__c);
            System.assertEquals(0, contractItem.Active_Installed_Annual_Production__c);
            System.assertEquals(12, contractItem.Active_Installed_Production_Conga__c);
        }
    }


    private static AssignmentTestData createTestDataAssignments(Integer batchSize) {
        AssignmentTestData testData = new AssignmentTestData();

        testData.Owner = createAccount('earliest Owner');
        insert testData.Owner;

        List<Generation_Unit__c> gUnitsPast = new List<Generation_Unit__c>();
        List<Generation_Unit__c> gUnitsFuture = new List<Generation_Unit__c>();
        for (Integer i = 0; i < batchSize; i++) {
            gUnitsPast.add(createGenerationUnit('Unit Name ' + i));
            gUnitsFuture.add(createGenerationUnit('Unit Name Else ' + i));
            testData.Contracts.add(createContract(today.addYears(-1), today.addYears(1), testData.Owner.Id, 'Name' + i));
        }
        List<Generation_Unit__c> gUnits = new List<Generation_Unit__c>();
        gUnits.addAll(gUnitsPast);
        gUnits.addAll(gUnitsFuture);
        insert gUnits;
        insert testData.Contracts;

        List<Generation_Unit_Assignment__c> assignments = new List<Generation_Unit_Assignment__c>();
        for (Integer i = 0; i < batchSize; i++) {
            assignments.add(createAssignment(
                    testData.Contracts[i].Id,
                    gUnitsPast[i].Id,
                    testData.Contracts[i].Start_Date__c,
                    today.addDays(-1)
            ));
            assignments.add(createAssignment(
                    testData.Contracts[i].Id,
                    gUnitsFuture[i].Id,
                    today.addDays(1),
                    testData.Contracts[i].End_Date__c
            ));
        }
        insert assignments;
        return testData;
    }

    private static Account createAccount(String nameEntry) {
        return new Account (
                Name = nameEntry,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
    }

    private static Generation_Unit__c createGenerationUnit(String nameEntry) {
        return new Generation_Unit__c(
                Name = nameEntry,
                Annual_Production__c = 12,
                Installed_Capacity__c = 1,
                Country__c = 'Germany'
        );
    }

    private static Contract__c createContract(Date startDate, Date endDate, Id contractHolder, String nameString) {
        String status = 'Active';
        if (endDate < today) {
            status = 'Expired';
        } else if (today < startDate) {
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
                Start_for_Conga_Context__c = today.addYears(-1),
                End_for_Conga_Context__c = today.addDays(-1)
        );
    }

    private static Generation_Unit_Assignment__c createAssignment(Id contractId, Id genUnitId, Date startDate, Date endDate) {
        return new Generation_Unit_Assignment__c(
                Contract__c = contractId,
                Generation_Unit__c = genUnitId,
                Start_Date__c = startDate,
                End_Date__c = endDate
        );
    }
    private class AssignmentTestData {
        Account Owner { get; set; }
        List<Contract__c> Contracts { get; set; }

        public AssignmentTestData() {
            Contracts = new List<Contract__c>();
        }

        public void updateContracts() {
            Contracts = [
                    SELECT Id,
                            Installed_Capacity__c,
                            Active_Installed_Capacity__c,
                            Active_Installed_Capacity_Conga__c,
                            Installed_Annual_Production__c,
                            Active_Installed_Annual_Production__c,
                            Active_Installed_Production_Conga__c,
                            Contracted_Annual_Production__c,
                            Contracted_Capacity__c
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