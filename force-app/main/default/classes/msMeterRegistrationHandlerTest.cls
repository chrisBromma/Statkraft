/****************************************************************************************************
 * Class MeterRegistrationHandlerTest
 *
 *   Create By	:   Fabian Kramer (mindsquare GmbH)
 *   Create Date	:   14.03.2019
 *   Description	:	Test class for the class msMeterRegistrationHandler
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Kramer (mindsquare GmbH)		14.03.2019      	Init version.
 *****************************************************************************************************/
@IsTest
private class msMeterRegistrationHandlerTest {
    private static final Id DE_ACC_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Account', 'Account').Id;
    private static final Id PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;

    private static List<String> validBalancingCircleNames = new List<String>();

    private static final Integer BULK_SIZE = 200;

    @TestSetup
    private static void setup() {
        Set<String> systemWideBalCircleNames = new Set<String>();
        Set<String> knownBalancingCircleNames = new Set<String>();

        Schema.DescribeFieldResult F = MeterRegistration__c.Balancing_Circle__c.getDescribe();
        Schema.SObjectField T = F.getSobjectField();
        List<PicklistEntry> balCircleEntries = T.getDescribe().getPicklistValues();

        for (PicklistEntry entryItem : balCircleEntries) {
            systemWideBalCircleNames.add(entryItem.value);
        }

        List<Balancing_Circle__c> presentBalCirclesRecords = [
                SELECT Id, Name
                FROM Balancing_Circle__c
        ];

        for (Balancing_Circle__c balCircleItem : presentBalCirclesRecords) {
            knownBalancingCircleNames.add(balCircleItem.Name);
        }

        systemWideBalCircleNames.removeAll(knownBalancingCircleNames);
        List<Balancing_Circle__c> balCirclesToInsert = new List<Balancing_Circle__c>();
        for (String newEntry : systemWideBalCircleNames) {
            balCirclesToInsert.add(new Balancing_Circle__c(
                    Name = newEntry
            ));
        }
        insert balCirclesToInsert;
    }

    @IsTest
    public static void testInsertTrigger() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;
        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-6),
                Valid_to__c = Date.today().addMonths(6),
                Active__c = true);
        insert meter2Gen;
        Account contractHolder = new Account (
                Name = 'Contract Holder',
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
        contractHolder.RecordTypeId = DE_ACC_RECORD_TYPE;
        contractHolder.BillingCountry = 'Germany';
        contractHolder.Customer_Type__c = 'not yet identified';
        contractHolder.Customer_Segment_industry__c = 'Large industrials';
        insert contractHolder;
        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'test Contract 2');
        insert contract;
        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today(),
                Active__c = true);
        Test.startTest();
        insert meterReg;
        Test.stopTest();

        contract = [
                SELECT
                        Contracted_Capacity__c,
                        Contracted_Annual_Production__c
                FROM Contract__c
                WHERE Id = :contract.Id
        ];
        System.assertEquals(contract.Contracted_Capacity__c, meterReg.Volume_Share__c * gUnit.Installed_Capacity__c / 100);
        System.assertEquals(contract.Contracted_Annual_Production__c, meterReg.Volume_Share__c * gUnit.Annual_Production__c / 100);
    }

    @IsTest
    public static void testUndeleteTrigger() {
        disableTriggers();
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;
        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-6),
                Valid_to__c = Date.today().addMonths(6),
                Active__c = true);
        insert meter2Gen;
        Account contractHolder = new Account (
                Name = 'Contract Holder',
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
        contractHolder.RecordTypeId = DE_ACC_RECORD_TYPE;
        contractHolder.BillingCountry = 'Germany';
        contractHolder.Customer_Type__c = 'not yet identified';
        contractHolder.Customer_Segment_industry__c = 'Large industrials';
        insert contractHolder;
        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'test Contract 2');
        insert contract;
        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today(),
                Active__c = true);
        insert meterReg;
        delete meterReg;
        enableTriggers();

        Test.startTest();
        undelete meterReg;
        Test.stopTest();

        contract = [
                SELECT
                        Contracted_Capacity__c,
                        Contracted_Annual_Production__c
                FROM Contract__c
                WHERE Id = :contract.Id
        ];
        System.assertEquals(contract.Contracted_Capacity__c, meterReg.Volume_Share__c * gUnit.Installed_Capacity__c / 100);
        System.assertEquals(contract.Contracted_Annual_Production__c, meterReg.Volume_Share__c * gUnit.Annual_Production__c / 100);
    }

    @IsTest
    public static void testDeleteTrigger() {
        disableTriggers();
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;
        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-6),
                Valid_to__c = Date.today().addMonths(6),
                Active__c = true);
        insert meter2Gen;
        Account contractHolder = new Account (
                Name = 'Contract Holder',
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
        contractHolder.RecordTypeId = DE_ACC_RECORD_TYPE;
        contractHolder.BillingCountry = 'Germany';
        contractHolder.Customer_Type__c = 'not yet identified';
        contractHolder.Customer_Segment_industry__c = 'Large industrials';
        insert contractHolder;
        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'test Contract 2');
        insert contract;
        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today(),
                Active__c = true);
        insert meterReg;
        enableTriggers();

        Test.startTest();
        delete meterReg;
        Test.stopTest();

        contract = [
                SELECT
                        Contracted_Capacity__c,
                        Contracted_Annual_Production__c
                FROM Contract__c
                WHERE Id = :contract.Id
        ];
        System.assertEquals(0, contract.Contracted_Capacity__c);
        System.assertEquals(0, contract.Contracted_Annual_Production__c);
    }

    @IsTest
    public static void testUpdateTrigger() {

        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;
        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-6),
                Valid_to__c = Date.today().addMonths(6),
                Active__c = true);
        insert meter2Gen;
        Account contractHolder = new Account (Name = 'Contract Holder');
        contractHolder.RecordTypeId = DE_ACC_RECORD_TYPE;
        contractHolder.BillingCountry = 'Germany';
        contractHolder.Customer_Type__c = 'not yet identified';
        contractHolder.Customer_Segment_industry__c = 'Large industrials';
        insert contractHolder;
        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'test_Contract');
        insert contract;
        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today(),
                Active__c = true);
        insert meterReg;

        Test.startTest();

        meterReg.Volume_Share__c = 50;
        update meterReg;

        List<Contract__c> newContract = [
                SELECT
                        Id,
                        Name,
                        Contracted_Capacity__c,
                        Contracted_Annual_Production__c
                FROM Contract__c
                LIMIT 1
        ];
        List<MeterRegistration__c> newMeterReg = [
                SELECT
                        Id,
                        Name,
                        Volume_Share__c
                FROM MeterRegistration__c
                WHERE Name = 'MeterReg'
                LIMIT 1
        ];
        List<Generation_Unit__c> newGUnit = [
                SELECT
                        Id,
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Generation_Unit__c
                WHERE Name = 'gUnit'
                LIMIT 1
        ];

        System.assertEquals(newContract[0].Contracted_Capacity__c, newMeterReg[0].Volume_Share__c * newGUnit[0].Installed_Capacity__c / 100);
        System.assertEquals(newContract[0].Contracted_Annual_Production__c, newMeterReg[0].Volume_Share__c * newGUnit[0].Annual_Production__c / 100);

        meterReg.Volume_Share__c = 23;
        update meterReg;

        newContract = [
                SELECT
                        Id,
                        Name,
                        Contracted_Capacity__c,
                        Contracted_Annual_Production__c
                FROM Contract__c
                LIMIT 1
        ];
        newMeterReg = [
                SELECT
                        Id,
                        Name,
                        Volume_Share__c
                FROM MeterRegistration__c
                WHERE Name = 'MeterReg'
                LIMIT 1
        ];
        newGUnit = [
                SELECT
                        Id,
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Generation_Unit__c
                WHERE Name = 'gUnit'
                LIMIT 1
        ];

        System.assertEquals(newContract[0].Contracted_Capacity__c, newMeterReg[0].Volume_Share__c * newGUnit[0].Installed_Capacity__c / 100);
        System.assertEquals(newContract[0].Contracted_Annual_Production__c, newMeterReg[0].Volume_Share__c * newGUnit[0].Annual_Production__c / 100);

        Test.stopTest();
    }

    @IsTest
    public static void testBulkInsertAndUpdateTrigger() {

        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;
        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-6),
                Valid_to__c = Date.today().addMonths(6),
                Active__c = true);
        insert meter2Gen;
        Account contractHolder = new Account (Name = 'Contract Holder');
        contractHolder.RecordTypeId = DE_ACC_RECORD_TYPE;
        contractHolder.BillingCountry = 'Germany';
        contractHolder.Customer_Type__c = 'not yet identified';
        contractHolder.Customer_Segment_industry__c = 'Large industrials';
        insert contractHolder;
        Contract__c contract = new Contract__c(Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Draft',
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'test Contract');
        insert contract;

        Test.startTest();

        List<MeterRegistration__c> bulkRegistrationsList = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 200; i++) {
            MeterRegistration__c meterReg = new MeterRegistration__c (
                    Name = 'MeterReg' + i,
                    Contract__c = contract.Id,
                    Meter__c = meter.Id,
                    Volume_Share__c = 100,
                    Active__c = true,
                    Valid_from__c = Date.today()
            );
            bulkRegistrationsList.add(meterReg);
        }
        insert bulkRegistrationsList;

        update bulkRegistrationsList;

        Test.stopTest();
    }

    @IsTest
    private static void testFrenchBehaviour() {
        disableTriggers();

        Meter__c meter = new Meter__c(Name = 'Meter Name', Alternative_Meter_ID__c = '12345678901');
        insert meter;
        Account contractHolder = new Account (Name = 'Contract Holder');
        contractHolder.RecordTypeId = DE_ACC_RECORD_TYPE;
        contractHolder.BillingCountry = 'Germany';
        contractHolder.Customer_Type__c = 'not yet identified';
        contractHolder.Customer_Segment_industry__c = 'Large industrials';
        insert contractHolder;
        Contract__c contract = new Contract__c(Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Draft',
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'test Contract');
        insert contract;

        List<MeterRegistration__c> bulkRegistrationsList = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            MeterRegistration__c meterReg = new MeterRegistration__c (
                    Name = 'MeterReg' + i,
                    Contract__c = contract.Id,
                    Meter__c = meter.Id,
                    Volume_Share__c = 100,
                    Active__c = true,
                    Valid_from__c = Date.today(),
                    Country__c = 'France'
            );
            bulkRegistrationsList.add(meterReg);
        }
        enableTriggers();

        Test.startTest();
        insert bulkRegistrationsList;
        System.assert([SELECT COUNT() FROM MeterRegistration__c WHERE Balancing_Circle__c = '11XSTATKRAFT001N'] == BULK_SIZE,
                'All French Meter Registrations should default to Balancing Circle 11XSTATKRAFT001N');
        for (MeterRegistration__c regItem : bulkRegistrationsList) {
            regItem.Balancing_Circle__c = null;
        }
        update bulkRegistrationsList;
        Test.stopTest();
        System.assert([SELECT COUNT() FROM MeterRegistration__c WHERE Balancing_Circle__c = '11XSTATKRAFT001N'] == BULK_SIZE,
                'All French Meter Registrations should default to Balancing Circle 11XSTATKRAFT001N even after updates');
    }

    @IsTest
    private static void testStatusUpdateToContract() {
        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;
        Account contractHolder = new Account (Name = 'Contract Holder');
        contractHolder.RecordTypeId = DE_ACC_RECORD_TYPE;
        contractHolder.BillingCountry = 'Germany';
        contractHolder.Customer_Type__c = 'not yet identified';
        contractHolder.Customer_Segment_industry__c = 'Large industrials';
        insert contractHolder;
        Contract__c contract = new Contract__c(
                RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Country__c = 'Germany',
                Workflow_Type__c = 'New',
                Name = 'test Contract');
        insert contract;
        List<MeterRegistration__c> regs = new List<MeterRegistration__c>();
        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Country__c = 'Germany',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today(),
                Active__c = true);
        regs.add(meterReg);
        MeterRegistration__c meterRegOld = new MeterRegistration__c (
                Name = 'MeterRegOld',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Country__c = 'Germany',
                Volume_Share__c = 100,
                Valid_from__c = Date.today().addMonths(-1),
                Valid_to__c = Date.today().addMonths(-1),
                Active__c = false);
        regs.add(meterRegOld);
        insert regs;

        Test.startTest();
        meterReg.Status__c = 'Pending';
        update regs;
        meterRegOld.Status__c = 'In Progress';
        meterReg.Status__c = 'Registration rejected';
        update regs;
        meterRegOld.Status__c = 'Completed';
        meterReg.Status__c = 'Registration rejected';
        update regs;
        meterRegOld.Status__c = 'Completed';
        meterReg.Status__c = 'Completed';
        update regs;
        Test.stopTest();
        System.assert([
                SELECT Meter_Registration_Status__c
                FROM Contract__c
                WHERE Id = :contract.Id
        ].Meter_Registration_Status__c != null,
                'Should have created a status entry');
    }

    @IsTest
    private static void correctBalancingCircleOnInsert() {
        SetupData setupData = new SetupData();
        Balancing_Circle__c nonFranceCircle = [
                SELECT Id
                FROM Balancing_Circle__c
                WHERE Name != '11XSTATKRAFT001N'
                LIMIT 1
        ];
        Test.startTest();
        MeterRegistration__c newMeterReg = new MeterRegistration__c(
                Name = 'test',
                Balancing_Circle__c = '11XSTATKRAFT001N',
                Country__c = 'France',
                Balancing_Circle_Lookup__c = nonFranceCircle.Id,
                Meter__c = setupData.meter.Id,
                Contract__c = setupData.contract.Id,
                Valid_from__c = setupData.contract.Start_Date__c
        );
        insert newMeterReg;
        Test.stopTest();
        newMeterReg = [SELECT Id, Balancing_Circle__c, Balancing_Circle_Lookup__c FROM MeterRegistration__c WHERE Id = :newMeterReg.Id];
        Balancing_Circle__c franceBC = [SELECT Id FROM Balancing_Circle__c WHERE Name = '11XSTATKRAFT001N'];
        System.assert(newMeterReg.Balancing_Circle__c == '11XSTATKRAFT001N');
        System.assert(newMeterReg.Balancing_Circle_Lookup__c == franceBC.Id);
    }

    @IsTest
    private static void correctBalancingCircleOnInsertNull() {
        SetupData setupData = new SetupData();
        Balancing_Circle__c randomBalancingCircle = [
                SELECT Id
                FROM Balancing_Circle__c
                LIMIT 1
        ];
        Test.startTest();
        MeterRegistration__c newMeterReg = new MeterRegistration__c(
                Name = 'test',
                Balancing_Circle__c = null,
                Country__c = 'Germany',
                Balancing_Circle_Lookup__c = randomBalancingCircle.Id,
                Meter__c = setupData.meter.Id,
                Contract__c = setupData.contract.Id,
                Valid_from__c = setupData.contract.Start_Date__c
        );
        insert newMeterReg;
        Test.stopTest();
        newMeterReg = [SELECT Id, Balancing_Circle__c, Balancing_Circle_Lookup__c FROM MeterRegistration__c WHERE Id = :newMeterReg.Id];
        System.assert(newMeterReg.Balancing_Circle__c == null);
        System.assert(newMeterReg.Balancing_Circle_Lookup__c == null);
    }

    @IsTest
    private static void correctBalancingCircleOnUpdate() {
        SetupData setupData = new SetupData();
        Balancing_Circle__c randomBalancingCircle = [
                SELECT Id
                FROM Balancing_Circle__c
                WHERE Name != '11XSTATKRAFT001N'
                LIMIT 1
        ];

        MeterRegistration__c newMeterReg1 = new MeterRegistration__c(
                Name = 'test',
                Balancing_Circle__c = '11XSTATKRAFT001N',
                Country__c = 'France',
                Meter__c = setupData.meter.Id,
                Contract__c = setupData.contract.Id,
                Valid_from__c = setupData.contract.Start_Date__c
        );
        insert newMeterReg1;

        MeterRegistration__c newMeterReg2 = new MeterRegistration__c(
                Name = 'test',
                Balancing_Circle__c = '11XSTATKRAFT001N',
                Country__c = 'France',
                Meter__c = setupData.meter.Id,
                Contract__c = setupData.contract.Id,
                Valid_from__c = setupData.contract.Start_Date__c
        );
        insert newMeterReg2;

        Test.startTest();
        newMeterReg1.Balancing_Circle__c = null;
        newMeterReg1.Country__c = 'Germany';
        newMeterReg2.Balancing_Circle_Lookup__c = randomBalancingCircle.Id;
        update newMeterReg1;
        update newMeterReg2;
        Test.stopTest();
        newMeterReg1 = [SELECT Id, Balancing_Circle__c, Balancing_Circle_Lookup__c FROM MeterRegistration__c WHERE Id = :newMeterReg1.Id];
        newMeterReg2 = [SELECT Id, Balancing_Circle__c, Balancing_Circle_Lookup__c FROM MeterRegistration__c WHERE Id = :newMeterReg2.Id];
        Balancing_Circle__c franceBC = [SELECT Id FROM Balancing_Circle__c WHERE Name = '11XSTATKRAFT001N'];
        System.assert(newMeterReg1.Balancing_Circle__c == null);
        System.assert(newMeterReg1.Balancing_Circle_Lookup__c == null);
        System.assert(newMeterReg2.Balancing_Circle__c == '11XSTATKRAFT001N');
        System.assert(newMeterReg2.Balancing_Circle_Lookup__c == franceBC.Id);
    }

    private class SetupData {
        private Meter__c meter;
        private Contract__c contract;
        private MeterRegistration__c firstRegistration;
        private MeterRegistration__c secondRegistration;

        private SetupData() {
            createMeter();
            createContract();
            List<PicklistEntry> picklistEntriesBalancingCircle
                    = MeterRegistration__c.Balancing_Circle__c.getDescribe().getSobjectField().getDescribe().getPicklistValues();
            for (PicklistEntry entryItem : picklistEntriesBalancingCircle) {
                validBalancingCircleNames.add(entryItem.value);
            }
        }

        private void createMeter() {
            meter = new Meter__c();
            meter.Name = 'Test Meter';
            meter.Alternative_Meter_ID__c = '12345678901';
            insert meter;
        }

        private void createContract() {
            Account testAccount = new Account();
            testAccount.BillingCountry = 'Germany';
            testAccount.Customer_Type__c = 'not yet identified';
            testAccount.Customer_Segment_industry__c = 'Large industrials';
            testAccount.Name = 'TestAccount';
            insert testAccount;

            contract = new Contract__c(
                    RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract1',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'DETestContract1',
                    Settlement_SubModel__c = null
            );
            insert contract;
        }

        private void createFirstRegistration(Date validFrom, Date validTo, Boolean isActive) {
            firstRegistration = new MeterRegistration__c();
            firstRegistration.Name = 'First Registration';
            firstRegistration.Meter__c = meter.Id;
            firstRegistration.Contract__c = contract.Id;
            firstRegistration.Valid_from__c = validFrom;
            firstRegistration.Valid_to__c = validTo;
            firstRegistration.Active__c = isActive;
            insert firstRegistration;
        }

        private void createSecondRegistration(Date validFrom, Date validTo, Boolean isActive) {
            secondRegistration = new MeterRegistration__c();
            secondRegistration.Name = 'Second Registration';
            secondRegistration.Meter__c = meter.Id;
            secondRegistration.Contract__c = contract.Id;
            secondRegistration.Valid_from__c = validFrom;
            secondRegistration.Valid_to__c = validTo;
            secondRegistration.Active__c = isActive;
            insert secondRegistration;
        }

        private void queryFirstRegistration() {
            firstRegistration = [SELECT Id, Active__c FROM MeterRegistration__c WHERE Name = 'First Registration'];
        }

        private void querySecondRegistration() {
            secondRegistration = [SELECT Id, Active__c FROM MeterRegistration__c WHERE Name = 'Second Registration'];
        }
    }
    @IsTest
    private static void testRemitDeleteAllActiveMeterRegLegalCapOver10() {
        Generation_Unit__c gUnitOver10 = createGenerationUnit('abc', 0, 'Germany');
        insert gUnitOver10;
        Account contractHolder = createAccount('myAcc', 'Germany');
        insert contractHolder;
        Contract__c contractPlannedOver10 = createContract('TestCon', 'Germany', contractHolder.Id, 1, 11);
        insert contractPlannedOver10;
        Meter__c meterPlannedOver10 = createMeter('myMet', 'Under Construction', 'Germany');
        insert meterPlannedOver10;
        Meter2GenerationUnitRelationship__c m2GOver10 = createMeter2GenUnit('MyM2G', gUnitOver10.Id, meterPlannedOver10.Id,true, 'Germany'  );
        insert m2GOver10;
        MeterRegistration__c meterRegistration = createMeterReg('MyMeterReg', contractPlannedOver10.Id, meterPlannedOver10.Id, 'Germany', true );
        insert meterRegistration;

        Test.startTest();
        delete meterRegistration;
        Test.stopTest();
        Contract__c contractActiveCapOver10Updated = [SELECT REMIT_Reporting_Relevant__c FROM Contract__c WHERE Id = :contractPlannedOver10.Id];
        System.assert(contractActiveCapOver10Updated.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testRemitAddActiveMeterWithActiveCapOver10() {

        Generation_Unit__c gUnitOver10 = createGenerationUnit('abc', 11, 'Germany');
        insert gUnitOver10;
        Account contractHolder = createAccount('myAcc', 'Germany');
        insert contractHolder;
        Contract__c contractPlannedOver10 = createContract('TestCon', 'Germany', contractHolder.Id, 11, 1);
        insert contractPlannedOver10;
        Meter__c meterPlannedOver10 = createMeter('myMet', 'Active', 'Germany');
        insert meterPlannedOver10;
        Meter2GenerationUnitRelationship__c m2GOver10 = createMeter2GenUnit('MyM2G', gUnitOver10.Id, meterPlannedOver10.Id,true, 'Germany'  );
        insert m2GOver10;
        MeterRegistration__c meterRegistration = createMeterReg('MyMeterReg', contractPlannedOver10.Id, meterPlannedOver10.Id, 'Germany', false );
        insert meterRegistration;

        Test.startTest();
        MeterRegistration__c meterRegistration1 = createMeterReg('MyMeterReg2', contractPlannedOver10.Id, meterPlannedOver10.Id, 'Germany', true );
        insert meterRegistration1;
        Test.stopTest();
        Contract__c contractPlannedOver10Updated = [SELECT REMIT_Reporting_Relevant__c FROM Contract__c WHERE Id = :contractPlannedOver10.Id];
        System.assert(contractPlannedOver10Updated.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testSetMeterRegToActiveCapOver10() {

        Generation_Unit__c gUnitOver10 = createGenerationUnit('abc', 11, 'Germany');
        insert gUnitOver10;
        Account contractHolder = createAccount('myAcc', 'Germany');
        insert contractHolder;
        Contract__c contractPlannedOver10 = createContract('TestCon', 'Germany', contractHolder.Id, 11, 0);
        insert contractPlannedOver10;
        Meter__c meterPlannedOver10 = createMeter('myMet', 'Active', 'Germany');
        insert meterPlannedOver10;
        Meter2GenerationUnitRelationship__c m2GOver10 = createMeter2GenUnit('MyM2G', gUnitOver10.Id, meterPlannedOver10.Id,true, 'Germany'  );
        insert m2GOver10;
        MeterRegistration__c meterRegistration = createMeterReg('MyMeterReg', contractPlannedOver10.Id, meterPlannedOver10.Id, 'Germany', false );
        insert meterRegistration;

        Test.startTest();
        meterRegistration.Active__c = true;
        update meterRegistration;
        Test.stopTest();
        Contract__c contractActiveCapOver10Updated = [SELECT REMIT_Reporting_Relevant__c FROM Contract__c WHERE Id = :contractPlannedOver10.Id];
        System.assert(contractActiveCapOver10Updated.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testSetMeterRegToNotActiveCapOver10() {

        Generation_Unit__c gUnitOver10 = createGenerationUnit('abc', 11, 'Germany');
        insert gUnitOver10;
        Account contractHolder = createAccount('myAcc', 'Germany');
        insert contractHolder;
        Contract__c contractPlannedOver10 = createContract('TestCon', 'Germany', contractHolder.Id, 11, 0);
        insert contractPlannedOver10;
        Meter__c meterPlannedOver10 = createMeter('myMet', 'Under Construction', 'Germany');
        insert meterPlannedOver10;
        Meter2GenerationUnitRelationship__c m2GOver10 = createMeter2GenUnit('MyM2G', gUnitOver10.Id, meterPlannedOver10.Id,true, 'Germany'  );
        insert m2GOver10;
        MeterRegistration__c meterRegistration = createMeterReg('MyMeterReg', contractPlannedOver10.Id, meterPlannedOver10.Id, 'Germany', true );
        insert meterRegistration;

        Test.startTest();
        meterRegistration.Active__c = false;
        update meterRegistration;
        Test.stopTest();
        Contract__c contractActiveCapOver10Updated = [SELECT REMIT_Reporting_Relevant__c FROM Contract__c WHERE Id = :contractPlannedOver10.Id];
        System.assert(!contractActiveCapOver10Updated.REMIT_Reporting_Relevant__c);
    }

    private static Contract__c createContract(
            String name,
            String country,
            Id contractHolder,
            Integer activeCapacity,
            Integer legalCapacity
    ) {
        Contract__c newContract = new Contract__c(
                Start_Date__c = Date.today().addYears(-2),
                End_Date__c = Date.today().addYears(2),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Contracted_Capacity__c = activeCapacity,
                Active_Installed_Capacity__c = activeCapacity,
                Legal_Capacity__c = legalCapacity,
                Contracted_Annual_Production__c = 34,
                Name = name,
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = country
        );

        return newContract;
    }

    private static Account createAccount(
            String name,
            String country) {

        Account newAccount = new Account(
                Name = name,
                BillingCountry = country,
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'

        );
        return newAccount;
    }

    private static Generation_Unit__c createGenerationUnit(
            String name,
            Integer installedCap,
            String country) {
        Generation_Unit__c newGenerationUnit = new Generation_Unit__c(
                Name = name,
                Annual_Production__c = 300,
                Installed_Capacity__c = installedCap,
                Country__c = country

        );
        return newGenerationUnit;

    }

    private static Meter__c createMeter(
            String name,
            String Status,
            String country) {
        Meter__c newMeter = new Meter__c(
                Name = name,
                Status__c = Status,
                Alternative_Meter_ID__c = '12345678901',
                Country__c = country

        );
        return newMeter;

    }
    private static MeterRegistration__c createMeterReg(
            String name,
            Id contract,
            Id meter,
            String country,
            Boolean active) {
        MeterRegistration__c newMeterReg = new MeterRegistration__c(
                Name = name,
                Contract__c = contract,
                Meter__c = meter,
                Country__c = country,
                Active__c = active,
                Volume_Share__c = 100,
                Valid_from__c = Date.today().addYears(-2),
                Valid_to__c = Date.today().addYears(2)
        );
        return newMeterReg;
    }

    private static Meter2GenerationUnitRelationship__c createMeter2GenUnit(
            String name,
            Id genUnit,
            Id meter,
            Boolean active,
            String country) {
        Meter2GenerationUnitRelationship__c newM2GU = new Meter2GenerationUnitRelationship__c(
                Name = name,
                Generator_Unit__c = genUnit,
                Meter__c = meter,
                Valid_from__c = Date.today().addYears(-2),
                Valid_to__c = Date.today().addYears(2),
                Active__c = active,
                Country__c = country);

        return newM2GU;
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
    }
}