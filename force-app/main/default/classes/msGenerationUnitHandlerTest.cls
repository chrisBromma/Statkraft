/****************************************************************************************************
 * Class msGenerationUnitHandler
 *
 *   Create By	:   Florian Pusse (mindsquare GmbH)
 *   Create Date	:   22.03.2019
 *   Description	:	Test class for the GenerationUnit SObject trigger.
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Florian Pusse (mindsquare AG)		22.03.2019       	Init version.
 *****************************************************************************************************/

@IsTest
public with sharing class msGenerationUnitHandlerTest {

    @TestSetup
    public static void setup() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00);
        insert gUnit;
        Meter__c meter = new Meter__c(Name = 'Meter Name');
        insert meter;

        Meter2GenerationUnitRelationship__c obj = new Meter2GenerationUnitRelationship__c(
                Name = 'gUnitRelation',
                Generator_Unit__c = gUnit.Id,
                Meter__c = meter.Id,
                Active__c = true,
                Valid_from__c = Date.today(),
                Valid_to__c = Date.today());
        insert obj;

        List<Meter2GenerationUnitRelationship__c> relationships = new List<Meter2GenerationUnitRelationship__c>();
        for (Integer i = 0; i < 500; ++i) {
            relationships.add(new Meter2GenerationUnitRelationship__c(
                    Name = 'gUnitRelation' + i,
                    Generator_Unit__c = gUnit.Id,
                    Meter__c = meter.Id,
                    Active__c = true,
                    Valid_from__c = Date.today(),
                    Valid_to__c = Date.today()));
        }
        insert relationships;
    }

    @IsTest
    public static void checkAnnualProduction() {
        Generation_Unit__c gUnit = [
                SELECT
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Generation_Unit__c
                WHERE Name = 'gUnit'
        ][0];

        gUnit.Annual_Production__c = 123;
        update gUnit;

        Meter2GenerationUnitRelationship__c rel = [
                SELECT
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Name = 'gUnitRelation'
        ][0];
        System.assertEquals(123, rel.Annual_Production__c);

        gUnit.Annual_Production__c = 321;
        update gUnit;

        rel = [
                SELECT Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Name = 'gUnitRelation'
        ][0];
        System.assertEquals(321, rel.Annual_Production__c);
    }

    @IsTest
    public static void checkInstalledCapacity() {
        Generation_Unit__c gUnit = [
                SELECT Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Generation_Unit__c
                WHERE Name = 'gUnit'
        ][0];

        gUnit.Installed_Capacity__c = 123;
        update gUnit;

        Meter2GenerationUnitRelationship__c rel = [
                SELECT
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Name = 'gUnitRelation'
        ][0];
        System.assertEquals(123, rel.Installed_Capacity__c);

        gUnit.Installed_Capacity__c = 321;
        update gUnit;

        rel = [
                SELECT
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Name = 'gUnitRelation'
        ][0];
        System.assertEquals(321, rel.Installed_Capacity__c);
    }

    @IsTest
    public static void checkMassUpdate() {
        Generation_Unit__c gUnit = [
                SELECT
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Generation_Unit__c
                WHERE Name = 'gUnit'
        ][0];

        gUnit.Installed_Capacity__c = 123;
        update gUnit;

        List<Meter2GenerationUnitRelationship__c> relationships = [
                SELECT
                        Name,
                        Annual_Production__c,
                        Installed_Capacity__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Name LIKE 'gUnitRelation'
        ];
        Boolean allTrue = true;
        for (Meter2GenerationUnitRelationship__c rel : relationships) {
            if (rel.Installed_Capacity__c != 123) {
                allTrue = false;
            }
        }
        System.assert(allTrue);
    }

    @IsTest
    public static void checkSubsidyEndDate_Insert() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit_Subsidy',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00,
                Commissioning_Date__c = Date.today(),
                Country__c = 'Germany');

        Test.startTest();
        insert gUnit;
        Test.stopTest();

        gUnit = [SELECT Commissioning_Date__c, Last_Day_of_Subsidy_Scheme__c FROM Generation_Unit__c WHERE Id = :gUnit.Id LIMIT 1];
        Date expectedResult = Date.newInstance(gUnit.Commissioning_Date__c.addYears(20).year(), 12, 31);
        System.assertEquals(expectedResult, gUnit.Last_Day_of_Subsidy_Scheme__c, 'The correct Last Day of Subsidy was not Assigned');
    }

    @IsTest
    public static void checkSubsidyEndDate_Update() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit_Subsidy',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00,
                Commissioning_Date__c = Date.today(),
                Country__c = 'Germany');
        insert gUnit;
        Test.startTest();
        gUnit.Commissioning_Date__c = Date.today().addYears(20);
        update gUnit;
        Test.stopTest();
        gUnit = [SELECT Commissioning_Date__c, Last_Day_of_Subsidy_Scheme__c FROM Generation_Unit__c WHERE Id = :gUnit.Id LIMIT 1];
        Date expectedResult = Date.newInstance(gUnit.Commissioning_Date__c.addYears(20).year(), 12, 31);
        System.assertEquals(expectedResult, gUnit.Last_Day_of_Subsidy_Scheme__c, 'The correct Last Day of Subsidy was not Assigned');
    }

    @IsTest
    private static void ensureUpdateWithoutM2GPossible() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit_Subsidy',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00,
                Commissioning_Date__c = Date.today(),
                Country__c = 'Germany');
        insert gUnit;
        Test.startTest();
        gUnit.Installed_Capacity__c = 0;
        update gUnit;
        Test.stopTest();
        System.assertEquals(0, [SELECT Installed_Capacity__c FROM Generation_Unit__c WHERE Id =:gUnit.Id].Installed_Capacity__c);
    }

    @isTest
    private static void ensureControlCircuitInserted() {
        Generation_Unit__c gUnit = new Generation_Unit__c(
                Name = 'gUnit_Subsidy',
                Annual_Production__c = 300.00,
                Installed_Capacity__c = 500.00,
                Commissioning_Date__c = Date.today(),
                Control_Circuit_Id__c = 'testControlCircuit123',
                Country__c = 'Germany');
        insert gUnit;
        System.assertEquals(1, [SELECT Id FROM Control_Circuit__c].size());
    }
}