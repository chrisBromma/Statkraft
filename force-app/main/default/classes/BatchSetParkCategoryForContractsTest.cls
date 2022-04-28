/****************************************************************************************************
* Class BatchSetParkCategoryForContractsTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-09-22
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-09-22       	Init version.
*****************************************************************************************************/

@IsTest
private class BatchSetParkCategoryForContractsTest {
    private static Integer BATCH_SIZE = 50;

    //Resulting values
    private static final String U20_ONLY = 'U20 Only';
    private static final String NOT_U20 = 'Not U20';
    private static final String MIXED = 'Mixed';

    private static Date TODAY = Date.today();
    private static Date START_LAST_YEAR = Date.newInstance(TODAY.year() - 1, 1, 1);
    private static Date START_THIS_YEAR = Date.newInstance(TODAY.year(), 1, 1);
    private static Date MID_THIS_YEAR = Date.newInstance(TODAY.year(), 6, 30);
    private static Date START_NEXT_YEAR = Date.newInstance(TODAY.year() + 1, 1, 1);
    private static Date MID_NEXT_YEAR = Date.newInstance(TODAY.year() + 1, 6, 30);
    private static Date END_NEXT_YEAR = Date.newInstance(TODAY.year() + 1, 12, 31);

    @IsTest
    private static void NotU20_ThisYear_Single() {
        disableTriggers();
        TestDataClass testData = test_Setup(1, START_THIS_YEAR.addYears(-20), MID_THIS_YEAR.addYears(-20));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), 1);
        Test.stopTest();
        testData.runAssertionThisYear(NOT_U20);
    }

    @IsTest
    private static void NotU20_ThisYear_Bulk() {
        disableTriggers();
        TestDataClass testData = test_Setup(BATCH_SIZE, START_THIS_YEAR.addYears(-20), MID_THIS_YEAR.addYears(-20));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), BATCH_SIZE);
        Test.stopTest();
        testData.runAssertionThisYear(NOT_U20);
    }
    @IsTest
    private static void U20_ThisYear_Single() {
        disableTriggers();
        TestDataClass testData = test_Setup(1, START_THIS_YEAR.addYears(-21), MID_THIS_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), 1);
        Test.stopTest();
        testData.runAssertionThisYear(U20_ONLY);
    }
    @IsTest
    private static void U20_ThisYear_Bulk() {
        disableTriggers();
        TestDataClass testData = test_Setup(BATCH_SIZE, START_THIS_YEAR.addYears(-21), MID_THIS_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), BATCH_SIZE);
        Test.stopTest();
        testData.runAssertionThisYear(U20_ONLY);
    }
    @IsTest
    private static void Mixed_ThisYear_Single() {
        disableTriggers();
        TestDataClass testData = test_Setup(1, START_THIS_YEAR.addYears(-20), MID_THIS_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), 1);
        Test.stopTest();
        testData.runAssertionThisYear(MIXED);
    }

    @IsTest
    private static void Mixed_ThisYear_Bulk() {
        disableTriggers();
        TestDataClass testData = test_Setup(BATCH_SIZE, START_THIS_YEAR.addYears(-20), MID_THIS_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), BATCH_SIZE);
        Test.stopTest();
        testData.runAssertionThisYear(MIXED);
    }

    @IsTest
    private static void NotU20_NextYear_Single() {
        disableTriggers();
        TestDataClass testData = test_Setup(1, START_NEXT_YEAR.addYears(-20), MID_NEXT_YEAR.addYears(-20));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), 1);
        Test.stopTest();
        testData.runAssertionNextYear(NOT_U20);
    }

    @IsTest
    private static void NotU20_NextYear_Bulk() {
        disableTriggers();
        TestDataClass testData = test_Setup(BATCH_SIZE, START_NEXT_YEAR.addYears(-20), MID_NEXT_YEAR.addYears(-20));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), BATCH_SIZE);
        Test.stopTest();
        testData.runAssertionNextYear(NOT_U20);
    }
    @IsTest
    private static void U20_NextYear_Single() {
        disableTriggers();
        TestDataClass testData = test_Setup(1, START_NEXT_YEAR.addYears(-21), MID_NEXT_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), 1);
        Test.stopTest();
        testData.runAssertionNextYear(U20_ONLY);
    }
    @IsTest
    private static void U20_NextYear_Bulk() {
        disableTriggers();
        TestDataClass testData = test_Setup(BATCH_SIZE, START_NEXT_YEAR.addYears(-21), MID_NEXT_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), BATCH_SIZE);
        Test.stopTest();
        testData.runAssertionNextYear(U20_ONLY);
    }
    @IsTest
    private static void Mixed_NextYear_Single() {
        disableTriggers();
        TestDataClass testData = test_Setup(1, START_NEXT_YEAR.addYears(-20), MID_NEXT_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), 1);
        Test.stopTest();
        testData.runAssertionNextYear(MIXED);
    }

    @IsTest
    private static void Mixed_NextYear_Bulk() {
        disableTriggers();
        TestDataClass testData = test_Setup(BATCH_SIZE, START_NEXT_YEAR.addYears(-20), MID_NEXT_YEAR.addYears(-21));
        enableTriggers();
        Test.startTest();
        Database.executeBatch(new BatchSetParkCategoryForContracts(), BATCH_SIZE);
        Test.stopTest();
        testData.runAssertionNextYear(MIXED);
    }

    private static TestDataClass test_Setup(Integer batchSize, Date commissioningDateUnit1, Date commissioningDateUnit2) {

        TestDataClass testData = new TestDataClass();

        List<Account> accounts = new List<Account>();
        accounts.add(createAccount('current Owner'));
        insert accounts;

        for (Integer i = 0; i < batchSize; i++) {
            testData.Contracts.add(createContract(START_LAST_YEAR, END_NEXT_YEAR, accounts[0].Id, 'test ' + i));
        }
        insert testData.Contracts;

        for (Contract__c contractItem : testData.Contracts) {
            testData.contractIds.add(contractItem.Id);
        }

        List<Meter__c> meters = new List<Meter__c>();
        List<Meter__c> metersUnit1 = new List<Meter__c>();
        List<Meter__c> metersUnit2 = new List<Meter__c>();
        for (Integer i = 0; i < batchSize; i++) {
            metersUnit1.add(createMeter('Unit 1 Meter of Contract ' + i));
            metersUnit2.add(createMeter('Unit 2 Meter of Contract ' + i));
        }
        meters.addAll(metersUnit1);
        meters.addAll(metersUnit2);
        insert meters;

        List<Generation_Unit__c> gUnits = new List<Generation_Unit__c>();
        List<Generation_Unit__c> gUnits1 = new List<Generation_Unit__c>();
        List<Generation_Unit__c> gUnits2 = new List<Generation_Unit__c>();
        for (Integer i = 0; i < batchSize; i++) {
            gUnits1.add(createGenerationUnit('Unit 1 of Contract ' + i, commissioningDateUnit1));
            gUnits2.add(createGenerationUnit('Unit 2 of Contract ' + i, commissioningDateUnit2));
        }
        gUnits.addAll(gUnits1);
        gUnits.addAll(gUnits2);
        insert gUnits;

        List<MeterRegistration__c> meterRegs = new List<MeterRegistration__c>();
        List<MeterRegistration__c> meterRegsUnit1 = new List<MeterRegistration__c>();
        List<MeterRegistration__c> meterRegsUnit2 = new List<MeterRegistration__c>();
        for (Integer i = 0; i < batchSize; i++) {
            meterRegsUnit1.add(createRegistration(
                    testData.Contracts[i].Id,
                    metersUnit1[i].Id,
                    testData.Contracts[i].Start_Date__c,
                    testData.Contracts[i].End_Date__c,
                    true));
            meterRegsUnit2.add(createRegistration(
                    testData.Contracts[i].Id,
                    metersUnit2[i].Id,
                    testData.Contracts[i].Start_Date__c,
                    testData.Contracts[i].End_Date__c,
                    true));
        }
        meterRegs.addAll(meterRegsUnit1);
        meterRegs.addAll(meterRegsUnit2);
        insert meterRegs;

        List<Meter2GenerationUnitRelationship__c> m2Gs = new List<Meter2GenerationUnitRelationship__c>();
        List<Meter2GenerationUnitRelationship__c> m2GsUnit1 = new List<Meter2GenerationUnitRelationship__c>();
        List<Meter2GenerationUnitRelationship__c> m2GsUnit2 = new List<Meter2GenerationUnitRelationship__c>();
        for (Integer i = 0; i < batchSize; i++) {
            m2GsUnit1.add(createM2G(
                    metersUnit1[i].Id,
                    gUnits1[i].Id,
                    testData.Contracts[i].Start_Date__c,
                    testData.Contracts[i].End_Date__c,
                    true));
            m2GsUnit2.add(createM2G(
                    metersUnit2[i].Id,
                    gUnits2[i].Id,
                    testData.Contracts[i].Start_Date__c,
                    testData.Contracts[i].End_Date__c,
                    true));
        }
        m2Gs.addAll(m2GsUnit1);
        m2Gs.addAll(m2GsUnit2);
        insert m2Gs;

        return testData;
    }

    private static Account createAccount(String nameEntry) {
        return new Account (
                Name = nameEntry,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
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
                Contracted_Annual_Production__c = 0
        );
    }

    private static Generation_Unit__c createGenerationUnit(String nameEntry, Date commissioningDate) {
        return new Generation_Unit__c(
                Name = nameEntry,
                Annual_Production__c = 12,
                Installed_Capacity__c = 1,
                Country__c = 'Germany',
                Commissioning_Date__c = commissioningDate
        );
    }

    private static Meter__c createMeter(String nameEntry) {
        return new Meter__c(
                Name = nameEntry,
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'Germany'
        );
    }

    private static MeterRegistration__c createRegistration(Id contractId, Id meterId, Date startDate, Date endDate, Boolean active) {
        return new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contractId,
                Meter__c = meterId,
                Volume_Share__c = 100,
                Valid_from__c = startDate,
                Valid_to__c = endDate,
                Active__c = active,
                Country__c = 'Germany');
    }

    private static Meter2GenerationUnitRelationship__c createM2G(Id meterId, Id genUnitId, Date startDate, Date endDate, Boolean active) {
        return new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name Over 10',
                Generator_Unit__c = genUnitId,
                Meter__c = meterId,
                Valid_from__c = startDate,
                Valid_to__c = endDate,
                Active__c = active,
                Country__c = 'Germany');
    }

    private class TestDataClass {
        List<Contract__c> Contracts { get; set; }
        Set<Id> contractIds = new Set<Id>();

        public TestDataClass() {
            Contracts = new List<Contract__c>();
        }

        public void updateContracts() {
            Contracts = [
                    SELECT Id,
                            Park_Category__c, Park_Category_Next_Year__c
                    FROM Contract__c
                    WHERE Id IN :this.contractIds
            ];
        }
        public void runAssertionThisYear(String value) {
            updateContracts();
            for (Contract__c contractItem : this.Contracts) {
                System.assertEquals(value, contractItem.Park_Category__c, 'Contract did not receive the intended Park Category');
            }
        }

        public void runAssertionNextYear(String value) {
            updateContracts();
            for (Contract__c contractItem : this.Contracts) {
                System.assertEquals(value, contractItem.Park_Category_Next_Year__c, 'Contract did not receive the intended Park Category Next Year');
            }
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Account.SObjectType);
        TriggerHandlerExtension.enableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit__c.SObjectType);
    }
}