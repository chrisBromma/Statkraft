/****************************************************************************************************
* Class msMeter2GenerationUnitHandlerTest
*
*   Create By	:   Fabian Kramer (mindsquare GmbH)
*   Create Date	:   13.03.2019
*   Description	:   Test class for the class msMeter2GenerationUnitHandler
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Kramer (mindsquare GmbH)       13.03.2019      	    Init version.
*****************************************************************************************************/
@IsTest
private class msMeter2GenerationUnitHandlerTest {

    @IsTest
    static void testInsertTrigger() {

        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(Name = 'Meter Name', Alternative_Meter_ID__c = '12345678901');
        insert meter;

        Meter2GenerationUnitRelationship__c obj = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Active__c = true,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today());

        Test.startTest();
        insert obj;

        List<Meter2GenerationUnitRelationship__c> result = [
                SELECT Id, Name, Annual_Production__c, Installed_Capacity__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Name = 'Test Name'
                LIMIT 1
        ];
        System.assertEquals(gUnit.Annual_Production__c, result[0].Annual_Production__c);

        Test.stopTest();

    }

    @IsTest
    static void testUpdateTrigger() {

        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;

        Meter2GenerationUnitRelationship__c obj = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Active__c = true,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today());
        insert obj;

        Test.startTest();
        obj.Name = 'TestName';
        obj.Annual_Production__c = 200.00;
        obj.Installed_Capacity__c = 300.00;
        update obj;

        List<Meter2GenerationUnitRelationship__c> result2 = [
                SELECT Id, Name, Annual_Production__c, Installed_Capacity__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Name = 'TestName'
                LIMIT 1
        ];
        System.assertEquals(gUnit.Annual_Production__c, result2[0].Annual_Production__c);
        System.assertEquals(gUnit.Installed_Capacity__c, result2[0].Installed_Capacity__c);

        Test.stopTest();

    }

    @IsTest
    static void testDoubleGenerationUnitRelationship() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Generation_Unit__c gUnit2 = new Generation_Unit__c(
                Name = 'gUnit2',
                Annual_Production__c = 200.00,
                Installed_Capacity__c = 100.00);
        insert gUnit2;

        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;

        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = Date.today().addMonths(2),
                Active__c = true);
        insert meter2Gen;

        Meter2GenerationUnitRelationship__c meter2Gen2 = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name2',
                Generator_Unit__c = gUnit2.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = Date.today().addMonths(2),
                Active__c = true);
        insert meter2Gen2;

        Account contractHolder = new Account (Name = 'Contract Holder');
        insert contractHolder;
        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addMonths(-2),
                End_Date__c = Date.today().addMonths(2),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'uniquename');
        insert contract;

        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = Date.today().addMonths(2),
                Active__c = true);
        insert meterReg;

        Test.startTest();

        contract = [
                SELECT
                        Contracted_Capacity__c,
                        Contracted_Annual_Production__c
                FROM Contract__c
                WHERE Id = :contract.Id
        ];
        System.assertEquals(contract.Contracted_Capacity__c, meterReg.Volume_Share__c * (gUnit.Installed_Capacity__c + gUnit2.Installed_Capacity__c) / 100);
        System.assertEquals(contract.Contracted_Annual_Production__c, meterReg.Volume_Share__c * (gUnit.Annual_Production__c + gUnit2.Annual_Production__c) / 100);

        Test.stopTest();
    }

    @IsTest
    static void testGenerationUnitRelationshipDeletion() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Generation_Unit__c gUnit2 = new Generation_Unit__c(
                Name = 'gUnit2',
                Annual_Production__c = 200.00,
                Installed_Capacity__c = 100.00);
        insert gUnit2;

        Meter__c meter = new Meter__c(
                Name = 'Meter Name',
                Alternative_Meter_ID__c = '12345678901');
        insert meter;

        Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = Date.today().addMonths(2),
                Active__c = true);
        insert meter2Gen;

        Meter2GenerationUnitRelationship__c meter2Gen2 = new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name2',
                Generator_Unit__c = gUnit2.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = Date.today().addMonths(2),
                Active__c = true);
        insert meter2Gen2;

        Account contractHolder = new Account (Name = 'Contract Holder');
        insert contractHolder;
        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addMonths(-2),
                End_Date__c = Date.today().addMonths(2),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Name = 'unique');
        insert contract;

        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contract.Id,
                Meter__c = meter.Id,
                Volume_Share__c = 100,
                Valid_from__c = Date.today().addMonths(-2),
                Valid_to__c = Date.today().addMonths(2),
                Active__c = true);
        insert meterReg;

        Test.startTest();

        delete meter2Gen2;

        contract = [
                SELECT
                        Contracted_Capacity__c,
                        Contracted_Annual_Production__c
                FROM Contract__c
                WHERE Id = :contract.Id
        ];
        System.assertEquals(contract.Contracted_Capacity__c, meterReg.Volume_Share__c * (gUnit.Installed_Capacity__c) / 100);
        System.assertEquals(contract.Contracted_Annual_Production__c, meterReg.Volume_Share__c * (gUnit.Annual_Production__c) / 100);

        Test.stopTest();
    }

    @IsTest
    static void setSRId_InsertTest() {
        SetupData setup = new SetupData();
        setup.createMeter();
        setup.createGenerationUnit();
        Test.startTest();

        Meter2GenerationUnitRelationship__c relationship = new Meter2GenerationUnitRelationship__c();
        relationship.Meter__c = setup.meter.Id;
        relationship.Generator_Unit__c = setup.generationUnit.Id;
        relationship.Valid_from__c = Date.today().addDays(-1);
        relationship.Valid_to__c = Date.today().addDays(1);
        relationship.Active__c = true;
        relationship.SR_ID__c = 'test';
        insert relationship;

        Test.stopTest();

        Generation_Unit__c generationUnit = [SELECT SR_ID__c FROM Generation_Unit__c WHERE Id = :setup.generationUnit.Id];
        System.assertEquals('test', generationUnit.SR_ID__c, 'SR Id was not properly populated');
    }
    @IsTest
    static void setSRId_InsertNegativeTest() {
        SetupData setup = new SetupData();
        setup.createMeter();
        setup.createGenerationUnit();
        Test.startTest();

        Meter2GenerationUnitRelationship__c relationship = new Meter2GenerationUnitRelationship__c();
        relationship.Meter__c = setup.meter.Id;
        relationship.Generator_Unit__c = setup.generationUnit.Id;
        relationship.Valid_from__c = Date.today().addDays(-2);
        relationship.Valid_to__c = Date.today().addDays(-1);
        relationship.Active__c = false;
        relationship.SR_ID__c = 'test';
        insert relationship;

        Test.stopTest();

        Generation_Unit__c generationUnit = [SELECT SR_ID__c FROM Generation_Unit__c WHERE Id = :setup.generationUnit.Id];
        System.assertEquals(null, generationUnit.SR_ID__c, 'SR Id was wrongly populated');
    }

    @IsTest
    static void setSRId_UpdateDateTest() {
        SetupData setup = new SetupData();
        setup.createMeter();
        setup.createGenerationUnit();
        Meter2GenerationUnitRelationship__c relationship = new Meter2GenerationUnitRelationship__c();
        relationship.Meter__c = setup.meter.Id;
        relationship.Generator_Unit__c = setup.generationUnit.Id;
        relationship.Valid_from__c = Date.today().addDays(-2);
        relationship.Valid_to__c = Date.today().addDays(-1);
        relationship.Active__c = false;
        relationship.SR_ID__c = 'test';
        insert relationship;
        Test.startTest();
        relationship.Valid_to__c = null;
        relationship.Active__c = true;
        update relationship;
        Test.stopTest();

        Generation_Unit__c generationUnit = [SELECT SR_ID__c FROM Generation_Unit__c WHERE Id = :setup.generationUnit.Id];
        System.assertEquals('test', generationUnit.SR_ID__c, 'SR Id was not properly populated');
    }

    @IsTest
    static void setSRId_UpdateSRIDTest() {
        SetupData setup = new SetupData();
        setup.createMeter();
        setup.createGenerationUnit();
        Meter2GenerationUnitRelationship__c relationship = new Meter2GenerationUnitRelationship__c();
        relationship.Meter__c = setup.meter.Id;
        relationship.Generator_Unit__c = setup.generationUnit.Id;
        relationship.Valid_from__c = Date.today().addDays(-2);
        relationship.Valid_to__c = Date.today().addDays(1);
        relationship.SR_ID__c = 'test';
        relationship.Active__c = true;
        insert relationship;
        Test.startTest();
        relationship.SR_ID__c = 'new_id';
        update relationship;
        Test.stopTest();

        Generation_Unit__c generationUnit = [SELECT SR_ID__c FROM Generation_Unit__c WHERE Id = :setup.generationUnit.Id];
        System.assertEquals('new_id', generationUnit.SR_ID__c, 'SR Id was not properly updated');
    }
    private class SetupData {
        public Meter__c meter;
        public Generation_Unit__c generationUnit;
        public Meter2GenerationUnitRelationship__c relationship;

        private void createMeter() {
            meter = new Meter__c();
            meter.Name = 'Test Meter';
            meter.Alternative_Meter_ID__c = '12345678901';
            insert meter;
        }

        private void createGenerationUnit() {
            generationUnit = new Generation_Unit__c();
            generationUnit.Name = 'Test Generation Unit';
            generationUnit.CurrencyIsoCode = 'EUR';
            insert generationUnit;
        }

        private void createRelationship(Date validFrom, Date validTo) {
            relationship = new Meter2GenerationUnitRelationship__c();
            relationship.Meter__c = meter.Id;
            relationship.Generator_Unit__c = generationUnit.Id;
            relationship.Valid_from__c = validFrom;
            relationship.Valid_to__c = validTo;
            insert relationship;
        }

        private void queryRelationship() {
            relationship = [SELECT Id, Active__c FROM Meter2GenerationUnitRelationship__c LIMIT 1];
        }

        private void queryOlderRelationship() {
            relationship = [SELECT Id, Active__c FROM Meter2GenerationUnitRelationship__c ORDER BY Valid_from__c ASC LIMIT 1];
        }

        private void queryNewerRelationship() {
            relationship = [SELECT Id, Active__c FROM Meter2GenerationUnitRelationship__c ORDER BY Valid_from__c DESC LIMIT 1];
        }
    }
}