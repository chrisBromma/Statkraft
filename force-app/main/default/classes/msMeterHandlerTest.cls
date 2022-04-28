/****************************************************************************************************
* Class msMeterHandlerTest
*
*   Create By	:   Florian Pusse (mindsquare GmbH)
*   Create Date	:   Florian Pusse
*   Description	:	--
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Florian Pusse (mindsquare GmbH)		25.03.2019       	Init version.
*****************************************************************************************************/

@IsTest
public class msMeterHandlerTest {

    @TestSetup
    public static void setup() {
        Generation_Unit__c gUnit = new Generation_Unit__c(Name = 'gUnit', Annual_Production__c = 300.00, Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c parentMeter = new Meter__c(Name = 'Parent Meter Name', Alternative_Meter_ID__c = '12345678901');
        insert parentMeter;
        Meter__c meter = new Meter__c(Name = 'Meter Name', Alternative_Meter_ID__c = '12345678901', Parent_Meter__c = parentMeter.Id);
        insert meter;
        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addYears(-2),
                Valid_to__c = Date.today().addYears(2),
                Active__c = true);
        insert meter2Gen;
        Account contractHolder = new Account (
                Name = 'Contract Holder',
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
        insert contractHolder;
        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addYears(-2),
                End_Date__c = Date.today().addYears(2),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'test Contract');
        insert contract;
        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = contract.Start_Date__c,
                Valid_to__c = contract.End_Date__c,
                Active__c = true);
        insert meterReg;
    }

    @IsTest
    public static void testCapacityChangeOnChildMeter() {
        Meter__c parent = new Meter__c(Name = 'Parent', Data_Migration_ID__c = 'Parent');
        insert parent;
        Meter__c child1 = new Meter__c(Name = 'Child1', Data_Migration_ID__c = 'Child1', Parent_Meter__c = parent.Id);
        insert child1;
        Meter__c child2 = new Meter__c(Name = 'Child1', Data_Migration_ID__c = 'Child2', Parent_Meter__c = parent.Id);
        insert child2;

        Test.startTest();
        child1.Installed_Capacity_of_Child_Meters__c = 10;
        update child1;
        child2.Installed_Capacity_of_Child_Meters__c = 5;
        update child2;

        parent = [SELECT Id, Installed_Capacity__c FROM Meter__c WHERE Id = :parent.Id];
        System.assertEquals(15, parent.Installed_Capacity__c);

        child2.Installed_Capacity_of_Child_Meters__c = 0;
        update child2;
        Test.stopTest();

        parent = [SELECT Id, Installed_Capacity__c FROM Meter__c WHERE Id = :parent.Id];
        System.assertEquals(10, parent.Installed_Capacity__c);
    }


    @IsTest
    public static void testContractUpdateAfterMeterChange() {
        Generation_Unit__c gUnit = [SELECT Name, Annual_Production__c, Installed_Capacity__c FROM Generation_Unit__c WHERE Name = 'gUnit'];
        Contract__c contract = [SELECT Contracted_Capacity__c, Contracted_Annual_Production__c FROM Contract__c LIMIT 1];
        MeterRegistration__c meterReg = [SELECT Volume_Share__c FROM MeterRegistration__c WHERE Name = 'MeterReg'];

        Test.startTest();

        // Check basic insertion of generation unit and propagation to contract
        System.assertEquals(contract.Contracted_Capacity__c, meterReg.Volume_Share__c * gUnit.Installed_Capacity__c / 100);
        System.assertEquals(contract.Contracted_Annual_Production__c, meterReg.Volume_Share__c * gUnit.Annual_Production__c / 100);

        gUnit.Annual_Production__c = 123;
        gUnit.Installed_Capacity__c = 321;
        update gUnit;

        // Check update of contract if generation unit changes
        contract = [SELECT Contracted_Capacity__c, Contracted_Annual_Production__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(contract.Contracted_Capacity__c, meterReg.Volume_Share__c * gUnit.Installed_Capacity__c / 100);
        System.assertEquals(contract.Contracted_Annual_Production__c, meterReg.Volume_Share__c * gUnit.Annual_Production__c / 100);

        Test.stopTest();
    }

    @IsTest
    private static void testControllableUnitIdSetting() {
        List<Meter__c> metersList = new List<Meter__c>();
        Meter__c meterWithContUnitIdRightFormat = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'France',
                Controllable_Unit_ID__c = '00123');
        metersList.add(meterWithContUnitIdRightFormat);
        Meter__c meterWithContUnitIdOldFormat = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'France',
                Controllable_Unit_ID__c = 'test1234'
        );
        metersList.add(meterWithContUnitIdOldFormat);
        insert metersList;
        Test.startTest();
        Meter__c newMeterWithoutContUnitId = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'France');
        insert newMeterWithoutContUnitId;
        Test.stopTest();

        newMeterWithoutContUnitId = [
                SELECT Controllable_Unit_ID__c
                FROM Meter__c
                WHERE Id = :newMeterWithoutContUnitId.Id
        ];
        System.assert(newMeterWithoutContUnitId.Controllable_Unit_ID__c == '00124');
    }

    @IsTest
    private static void testCheckNoDuplicationAllowedOnContUnitId() {
        List<Meter__c> metersList = new List<Meter__c>();
        String error = '';
        Meter__c meterWithContUnitIdRightFormat = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'France',
                Controllable_Unit_ID__c = '00123');
        metersList.add(meterWithContUnitIdRightFormat);
        insert metersList;
        Test.startTest();
        Meter__c newMeterWithContUnitId = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'France',
                Controllable_Unit_ID__c = '00123');
        try {
            insert newMeterWithContUnitId;
        } catch (Exception e) {
            error = e.getMessage();
        }
        Test.stopTest();
        System.assert(error.contains(Label.validationErrorMeterContUnitIdDuplicate));
    }

    @IsTest
    private static void testSetEmsysByPixosInsert() {
        Meter__c newMeter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Portfolio_ID__c = '123456789');
        Test.startTest();
        insert newMeter;
        Test.stopTest();
        newMeter = [SELECT Id, Portfolio_ID__c, EMSYS_ID__c FROM Meter__c WHERE Id = :newMeter.Id];
        System.assert(newMeter.Portfolio_ID__c == newMeter.EMSYS_ID__c);
    }

    @IsTest
    private static void testSetNoEmsysByPixosInsert() {
        Meter__c newMeter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Portfolio_ID__c = '123456789',
                EMSYS_ID__c = '987654321');
        Test.startTest();
        insert newMeter;
        Test.stopTest();
        newMeter = [SELECT Id, Portfolio_ID__c, EMSYS_ID__c FROM Meter__c WHERE Id = :newMeter.Id];
        System.assert(newMeter.Portfolio_ID__c != newMeter.EMSYS_ID__c);
        System.assert(newMeter.Portfolio_ID__c == '123456789');
        System.assert(newMeter.EMSYS_ID__c == '987654321');
    }
    @IsTest
    private static void testSetEmsysByPixosUpdate() {
        Meter__c newMeter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert newMeter;
        Test.startTest();
        newMeter.Portfolio_ID__c = '123456789';
        update newMeter;
        Test.stopTest();
        newMeter = [SELECT Id, Portfolio_ID__c, EMSYS_ID__c FROM Meter__c WHERE Id = :newMeter.Id];
        System.assert(newMeter.Portfolio_ID__c == newMeter.EMSYS_ID__c);
    }

    @IsTest
    private static void testSetNoEmsysByPixosUpdate() {
        Meter__c newMeter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                Portfolio_ID__c = '123456789',
                EMSYS_ID__c = '987654321');
        insert newMeter;
        Test.startTest();
        newMeter.Portfolio_ID__c = '789456123';
        update newMeter;
        Test.stopTest();
        newMeter = [SELECT Id, Portfolio_ID__c, EMSYS_ID__c FROM Meter__c WHERE Id = :newMeter.Id];
        System.assert(newMeter.Portfolio_ID__c != newMeter.EMSYS_ID__c);
        System.assert(newMeter.Portfolio_ID__c == '789456123');
        System.assert(newMeter.EMSYS_ID__c == '987654321');
    }

    @IsTest
    private static void testSetNoEmsysByPixosUpdate_2() {
        Meter__c newMeter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert newMeter;
        Test.startTest();
        newMeter.Portfolio_ID__c = '789456123';
        newMeter.EMSYS_ID__c = '987654321';
        update newMeter;
        Test.stopTest();
        newMeter = [SELECT Id, Portfolio_ID__c, EMSYS_ID__c FROM Meter__c WHERE Id = :newMeter.Id];
        System.assert(newMeter.Portfolio_ID__c != newMeter.EMSYS_ID__c);
        System.assert(newMeter.Portfolio_ID__c == '789456123');
        System.assert(newMeter.EMSYS_ID__c == '987654321');
    }

    @IsTest
    private static void testBlockEmsysUpdate() {
        Meter__c newMeter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901',
                EMSYS_ID__c = '123456789');
        insert newMeter;
        Test.startTest();
        newMeter.EMSYS_ID__c = '987654321';
        Database.SaveResult result = Database.update(newMeter, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors()[0].getMessage().contains(Label.validationErrorMeterEmsysIdChanged));
    }

    @IsTest
    private static void testRemitRelevantUpdateToNull() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Planned', 11, 5, 'Germany', false);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = null;
        update testSetup.meter;
        Test.stopTest();
        testSetup.updateRemitTestSetup();
        System.assert(testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testRemitRelevantUpdateToRetired() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Planned', 11, 5, 'Germany', false);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = 'Retired';
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testRemitNotRelevantUpdateActive() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Planned', 11, 5, 'Germany', false);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = 'Active';
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testRemitNotRelevantUpdateUnderConstruction() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Planned', 11, 5, 'Germany', false);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = 'Under Construction';
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(!testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testMeterStatusChangeFromUnderConToActive() {

        Generation_Unit__c gUnitOver10 = createGenerationUnit('abc', 11, 'Germany');
        insert gUnitOver10;
        Account contractHolder = createAccount('myAcc', 'Germany');
        insert contractHolder;
        Contract__c contractPlannedOver10 = createContract('TestCon', 'Germany', contractHolder.Id, 12, 9);
        insert contractPlannedOver10;
        Meter__c meterPlannedOver10 = createMeter('myMet', 'Under Construction', 'Germany');
        insert meterPlannedOver10;
        Meter2GenerationUnitRelationship__c m2GOver10 = createMeter2GenUnit('MyM2G', gUnitOver10.Id, meterPlannedOver10.Id, true, 'Germany');
        insert m2GOver10;
        MeterRegistration__c meterRegistration = createMeterReg('MyMeterReg', contractPlannedOver10.Id, meterPlannedOver10.Id, 'Germany', true);
        insert meterRegistration;

        Test.startTest();
        meterPlannedOver10.Status__c = 'Active';
        update meterPlannedOver10;
        Test.stopTest();

        Contract__c contractMeterStatusUpdated1 = [SELECT REMIT_Reporting_Relevant__c FROM Contract__c WHERE Id = :contractPlannedOver10.Id];
        System.assert(contractMeterStatusUpdated1.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testLegCapRemitRelevantUpdateToNull() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Planned', 5, 11, 'Germany',true);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = null;
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(!testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testLegCapRemitRelevantUpdateToRetired() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Planned', 5, 11, 'Germany', true);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = 'Retired';
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(!testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testLegCapRemitNotRelevantUpdateActive() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Planned', 5, 11, 'Germany', true);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = 'Active';
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(!testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testLegCapRemitNotRelevantUpdateUnderConstruction() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Active', 5, 11, 'Germany', false);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = 'Under Construction';
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testLegCapRemitNotRelevantUpdatePlanned() {
        Generation_Unit__c gUnitOver10 = createGenerationUnit('abc', 11, 'Germany');
        insert gUnitOver10;
        Account contractHolder = createAccount('myAcc', 'Germany');
        insert contractHolder;
        Contract__c contractPlannedOver10 = createContract('TestCon', 'Germany', contractHolder.Id, 9, 12);
        insert contractPlannedOver10;
        Meter__c meterPlannedOver10 = createMeter('myMet', 'Retired', 'Germany');
        insert meterPlannedOver10;
        Meter2GenerationUnitRelationship__c m2GOver10 = createMeter2GenUnit('MyM2G', gUnitOver10.Id, meterPlannedOver10.Id, true, 'Germany');
        insert m2GOver10;
        MeterRegistration__c meterRegistration = createMeterReg('MyMeterReg', contractPlannedOver10.Id, meterPlannedOver10.Id, 'Germany', true);
        insert meterRegistration;

        Test.startTest();
        meterPlannedOver10.Status__c = 'Planned';
        update meterPlannedOver10;
        Test.stopTest();
        Contract__c contractPlannedOver10Updated = [SELECT REMIT_Reporting_Relevant__c FROM Contract__c WHERE Id = :contractPlannedOver10.Id];
        System.assert(contractPlannedOver10Updated.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void testRemitNotRelevantUpdatePlanned() {
        disableTriggers();
        RemitTestSetup testSetup = remitTest_Setup('Active', 11, 5, 'Germany', true);
        enableTriggers();

        Test.startTest();
        testSetup.meter.Status__c = 'Planned';
        update testSetup.meter;
        Test.stopTest();

        testSetup.updateRemitTestSetup();
        System.assert(!testSetup.contract.REMIT_Reporting_Relevant__c);
    }

    @IsTest
    private static void renamingOfMeterRenamesContractRoles_singleTest() {
        Account testAccount = createAccount('test', 'Germany');
        insert testAccount;
        Contract__c testContract = createContract('test', 'Germany', testAccount.Id, 0, 0);
        insert testContract;
        Meter__c testMeter = createMeter('testName', null, 'Germany');
        insert testMeter;
        MeterRegistration__c testReg = createMeterReg('test', testContract.Id, testMeter.Id, 'Germany', true);
        insert testReg;
        Contract_Role__c testRole = createContractRole('test', testContract.Id);
        insert testRole;

        String meterName = [SELECT Name FROM Meter__c WHERE Id = :testMeter.Id LIMIT 1].Name;
        Test.startTest();

        testMeter.Name = meterName + ' New Name';
        update testMeter;

        Test.stopTest();
        String newName = [SELECT Name FROM Contract_Role__c WHERE Id = :testRole.Id LIMIT 1].Name;
        meterName = [SELECT Name FROM Meter__c WHERE Id = :testMeter.Id LIMIT 1].Name;
        System.assert(newName.contains(meterName), 'Renaming of Contract Role failed');
    }

    @IsTest
    private static void renamingOfMeterRenamesContractRoles_bulkTest() {
        Integer BULK_SIZE = 20;
        Account testAccount = createAccount('test', 'Germany');
        insert testAccount;
        List<Contract__c> testContracts = new List<Contract__c>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            testContracts.add(createContract('test', 'Germany', testAccount.Id, 0, 0));
        }
        insert testContracts;

        List<Meter__c> testMeters = new List<Meter__c>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            testMeters.add(createMeter('testName', null, 'Germany'));
        }
        insert testMeters;

        List<MeterRegistration__c> testRegs = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            testRegs.add(createMeterReg('test', testContracts[i].Id, testMeters[i].Id, 'Germany', true));
        }
        insert testRegs;

        List<Contract_Role__c> testRoles = new List<Contract_Role__c>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            testRoles.add(createContractRole('test', testContracts[i].Id));
        }
        insert testRoles;

        Test.startTest();

        for (Integer i = 0; i < BULK_SIZE; i++) {
            testMeters[i].Name = testMeters[i].Name + ' New Name';
        }
        update testMeters;

        Test.stopTest();
        Map<Id, Meter__c> meterMapAfterUpdate = new Map<Id, Meter__c>([
                SELECT Id, Name
                FROM Meter__c
                WHERE Id IN :testMeters
        ]);

        Map<Id, Contract_Role__c> contractRolesAfterUpdateMap = new Map<Id, Contract_Role__c>([
                SELECT Name
                FROM Contract_Role__c
                WHERE Id IN :testRoles
        ]);
        for (Integer i = 0; i < BULK_SIZE; i++) {
            String meterName = meterMapAfterUpdate.get(testMeters[i].Id).Name;
            String roleName = contractRolesAfterUpdateMap.get(testRoles[i].Id).Name;
            System.assert(roleName.contains(meterName), 'Renaming of Contract Role failed');
        }
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
    private static Contract_Role__c createContractRole(String name, Id contract) {
        Contract_Role__c newContractRole = new Contract_Role__c(
                Name = name,
                Contract__c = contract
        );
        return newContractRole;
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

    private static RemitTestSetup remitTest_Setup(String meterStatus, Integer contractedCapacity, Integer legalCapacity, String country, Boolean initialRemitStatus) {
        RemitTestSetup testSetup = new RemitTestSetup();
        testSetup.gUnit = createGenUnit(contractedCapacity);
        insert testSetup.gUnit;
        Account contractHolder = createAccount();
        insert contractHolder;
        testSetup.contract = createContract(contractHolder.Id, contractedCapacity, legalCapacity, country, initialRemitStatus);
        insert testSetup.contract;
        testSetup.meter = createMeter('test', meterStatus, country);
        insert testSetup.meter;
        testSetup.m2GU = createMeter2GenUnit('test', testSetup.gUnit.Id, testSetup.meter.Id, true, country);
        insert testSetup.m2GU;
        testSetup.meterReg = createMeterReg('test', testSetup.contract.Id, testSetup.meter.Id, country, true);
        insert testSetup.meterReg;
        return testSetup;
    }

    private static Generation_Unit__c createGenUnit(Integer capacity) {
        return new Generation_Unit__c(
                Name = 'gUnitOver10',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = capacity,
                Country__c = 'Germany'
        );
    }

    private static Account createAccount() {
        return new Account (
                Name = 'abcdefg',
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
    }

    private static Contract__c createContract(Id accountId, Integer contractedCapacity, Integer legalCapacity, String country, Boolean initialRemitStatus) {
        return new Contract__c(
                Start_Date__c = Date.today().addYears(-2),
                End_Date__c = Date.today().addYears(2),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = accountId,
                Contracted_Annual_Production__c = 0,
                Name = 'test Contract1',
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = country,
                Legal_Capacity__c = legalCapacity,
                Contracted_Capacity__c = contractedCapacity,
                Active_Installed_Capacity__c = contractedCapacity,
                REMIT_Reporting_Relevant__c = initialRemitStatus
        );
    }

    private class RemitTestSetup {
        Generation_Unit__c gUnit { get; set; }
        Meter__c meter { get; set; }
        Meter2GenerationUnitRelationship__c m2GU { get; set; }
        Contract__c contract { get; set; }
        MeterRegistration__c meterReg { get; set; }

        public void updateRemitTestSetup() {
            this.contract = [
                    SELECT REMIT_Reporting_Relevant__c
                    FROM Contract__c
                    WHERE Id = :this.contract.Id
            ];
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);
    }
}