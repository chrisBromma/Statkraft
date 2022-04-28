/**
 * Created by Steffen Naundorf on 16.08.2021.
 */

@isTest
public with sharing class GenerationUnitSplitTest {

    @testSetup
    static void setup() {
        Meter__c testMeter = new Meter__c(
                Name = 'MyMeter');
        insert testMeter;

        Generation_Unit__c representativeGU = new Generation_Unit__c(
                Name = 'MyGenerationUnit',
                Installed_Capacity__c = 1000000,
                Annual_Production__c = 1000000,
                Number_of_Generators__c = 3);
        insert representativeGU;

        Meter2GenerationUnitRelationship__c m2g = new Meter2GenerationUnitRelationship__c(
                Meter__c = testMeter.Id,
                Generator_Unit__c = representativeGU.Id,
                Valid_from__c = Date.today().addDays(-50));
        insert m2g;
    }

    @isTest
    static void testSplittingOfOneGU() {
        Meter__c testMeter = [SELECT Id From Meter__c LIMIT 1];
        List<Generation_Unit__c>gus = [SELECT Number_of_Generators__c, Name, Installed_Capacity__c, Annual_Production__c FROM Generation_Unit__c];
        System.assertEquals(1, gus.size(), 'There are more then expected GUs in the DataBase. TestData seems to bee wrong');
        System.assertEquals(3, gus[0].Number_of_Generators__c, 'TestGU has only one Generator. Need to have more to excetute test');
        System.assertEquals(1000000, gus[0].Installed_Capacity__c, 'Installed Capacity is wrong');
        System.assertEquals(1000000, gus[0].Annual_Production__c, 'Annual Production is wrong');

        List<GenerationUnitSplit.FlowInputs> inputs = new List<GenerationUnitSplit.FlowInputs>();
        GenerationUnitSplit.FlowInputs input = new GenerationUnitSplit.FlowInputs();
        input.meterId = testMeter.Id;
        inputs.add(input);

        Test.startTest();
        GenerationUnitSplit.splitGenerationUnits(inputs);
        Test.stopTest();

        Generation_Unit__c representativeGU = [SELECT Number_of_Generators__c, Name, Installed_Capacity__c, Annual_Production__c FROM Generation_Unit__c WHERE ID = :gus[0].Id];
        System.assertEquals(1, representativeGU.Number_of_Generators__c, 'Representative GU was not changed');
        System.assertEquals(333333.33333, representativeGU.Installed_Capacity__c, 'Installed Capacity is wrong');
        System.assertEquals(333333.3334, representativeGU.Annual_Production__c, 'Annual Production is wrong');
        System.assertEquals('MyMeter Generation Unit 1', representativeGU.Name, 'Name has different naming convention');

        List<Generation_Unit__c> otherGUs = [
                SELECT Id
                FROM Generation_Unit__c
                WHERE ID != :gus[0].Id
                AND Number_of_Generators__c = 1
                AND Installed_Capacity__c = 333333.33333
                AND Annual_Production__c = 333333.3333
        ];
        System.assertEquals(2, otherGUs.size(), 'Other GUs were not created succesfull');
    }

    @isTest
    static void testSplittingOfMultipleGU() {
        Meter__c testMeter = [SELECT Id From Meter__c LIMIT 1];
        List<Generation_Unit__c>gus = [SELECT Number_of_Generators__c, Name, Installed_Capacity__c, Annual_Production__c FROM Generation_Unit__c];
        System.assertEquals(1, gus.size(), 'There are more then expected GUs in the DataBase. TestData seems to bee wrong');
        System.assertEquals(3, gus[0].Number_of_Generators__c, 'TestGU has only one Generator. Need to have more to excetute test');
        System.assertEquals(1000000, gus[0].Installed_Capacity__c, 'Installed Capacity is wrong');
        System.assertEquals(1000000, gus[0].Annual_Production__c, 'Annual Production is wrong');

        Generation_Unit__c representativeGU2 = new Generation_Unit__c(
                Name = 'MyGenerationUnit2',
                Installed_Capacity__c = 2000000,
                Annual_Production__c = 1000000,
                Number_of_Generators__c = 5);
        insert representativeGU2;
        Meter2GenerationUnitRelationship__c m2g = new Meter2GenerationUnitRelationship__c(
                Meter__c = testMeter.Id,
                Generator_Unit__c = representativeGU2.Id,
                Valid_from__c = Date.today().addDays(-50));
        insert m2g;


        List<GenerationUnitSplit.FlowInputs> inputs = new List<GenerationUnitSplit.FlowInputs>();
        GenerationUnitSplit.FlowInputs input = new GenerationUnitSplit.FlowInputs();
        input.meterId = testMeter.Id;
        inputs.add(input);

        Test.startTest();
        GenerationUnitSplit.splitGenerationUnits(inputs);
        Test.stopTest();

        Generation_Unit__c representativeGU = [SELECT Number_of_Generators__c, Name, Installed_Capacity__c, Annual_Production__c FROM Generation_Unit__c WHERE ID = :gus[0].Id];
        System.assertEquals(1, representativeGU.Number_of_Generators__c, 'Representative GU was not changed');
        System.assertEquals(333333.33333, representativeGU.Installed_Capacity__c, 'Installed Capacity is wrong');
        System.assertEquals(333333.3334, representativeGU.Annual_Production__c, 'Annual Production is wrong');
        System.assertEquals('MyMeter Generation Unit 1.1', representativeGU.Name, 'Name has different naming convention');

        List<Generation_Unit__c> otherGUsOf1 = [
                SELECT Id
                FROM Generation_Unit__c
                WHERE ID != :gus[0].Id
                AND Number_of_Generators__c = 1
                AND Installed_Capacity__c = 333333.33333
                AND Annual_Production__c = 333333.3333
        ];
        System.assertEquals(2, otherGUsOf1.size(), 'Other GUs were not created succesfull');


        representativeGU2 = [SELECT Number_of_Generators__c, Name, Installed_Capacity__c, Annual_Production__c FROM Generation_Unit__c WHERE ID = :representativeGU2.Id];
        System.assertEquals(1, representativeGU2.Number_of_Generators__c, 'Representative GU was not changed');
        System.assertEquals(400000, representativeGU2.Installed_Capacity__c, 'Installed Capacity is wrong');
        System.assertEquals(200000, representativeGU2.Annual_Production__c, 'Annual Production is wrong');
        System.assertEquals('MyMeter Generation Unit 2.1', representativeGU2.Name, 'Name has different naming convention');

        List<Generation_Unit__c> allGUsOf2 = [
                SELECT Id
                FROM Generation_Unit__c
                WHERE ID != :gus[0].Id
                AND Number_of_Generators__c = 1
                AND Installed_Capacity__c = 400000
                AND Annual_Production__c = 200000
        ];
        System.assertEquals(5, allGUsOf2.size(), 'Other GUs were not created succesfull'); //Must be 5 because numbers are easily divisible by 5
    }
}