/****************************************************************************************************
* Class Meter2GenerationUnit_ChangeEventTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-08-18
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-08-18       	Init version.
*****************************************************************************************************/
@IsTest
private without sharing class Meter2GenerationUnit_ChangeEventTest {

    /**
     * WARNING: If the run time is too high, the execution of the events will be skipped and the assertions will simply fail.
     *          This can be noticed by the code coverage not even showing the Trigger to have passed.
      */

    @IsTest
    static void shouldActivateNewestRelationship_Insert() {
        Test.enableChangeDataCapture();
        disableTriggers();
        SetupData setupData = new SetupData();
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);

        Test.startTest();
        setupData.createTestData(Date.today().addDays(-10), null, Date.today().addDays(-5), null);
        Test.stopTest();

        setupData.updateRelationships();
        System.assertEquals(false, setupData.relationship1.Active__c, 'Older relation should not be active');
        System.assertEquals(true, setupData.relationship2.Active__c, 'Newer relation should be active');
    }

    @IsTest
    static void shouldActivateNewestRelationship_Update() {
        Test.enableChangeDataCapture();
        disableTriggers();
        SetupData setupData = new SetupData();
        setupData.createTestData(Date.today().addDays(-10), null, Date.today().addDays(-5), null);
        Test.getEventBus().deliver();
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);

        Test.startTest();
        setupData.relationship1.Valid_from__c = Date.today().addDays(-5);
        setupData.relationship2.Valid_from__c = Date.today().addDays(-10);
        update setupData.relationship1;
        update setupData.relationship2;
        Test.stopTest();

        setupData.updateRelationships();
        System.assertEquals(false, setupData.relationship2.Active__c, 'Older relation should not be active');
        System.assertEquals(true, setupData.relationship1.Active__c, 'Newer relation should be active');
    }

    @IsTest
    static void shouldActivateNewestRelationship_Delete() {
        Test.enableChangeDataCapture();
        disableTriggers();
        SetupData setupData = new SetupData();
        setupData.createTestData(Date.today().addDays(-10), null, Date.today().addDays(-5), null);
        Test.getEventBus().deliver();
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);

        Test.startTest();
        delete setupData.relationship2;
        Test.stopTest();

        setupData.relationship1 = [SELECT Id, Active__c FROM Meter2GenerationUnitRelationship__c WHERE Id = :setupData.relationship1.Id];
        System.assertEquals(true, setupData.relationship1.Active__c, 'Remaining relation should be active');
    }

    @IsTest
    static void shouldActivateNewestRelationship_Undelete() {
        Test.enableChangeDataCapture();
        disableTriggers();
        SetupData setupData = new SetupData();
        setupData.createTestData(Date.today().addDays(-10), null, Date.today().addDays(-5), null);
        delete setupData.relationship2;
        Test.getEventBus().deliver();
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);

        Test.startTest();
        undelete setupData.relationship2;
        Test.stopTest();

        setupData.updateRelationships();
        System.assertEquals(false, setupData.relationship1.Active__c, 'Older relation should not be active');
        System.assertEquals(true, setupData.relationship2.Active__c, 'Newer relation should be active');
    }

    private class SetupData {
        public Meter__c meter;
        public Generation_Unit__c generationUnit;
        public Meter2GenerationUnitRelationship__c relationship1 { get; set; }
        public Meter2GenerationUnitRelationship__c relationship2 { get; set; }

        public void createTestData(
                Date validFrom1, Date validTo1,
                Date validFrom2, Date validTo2) {
            createMeter();
            createGenerationUnit();
            createRelationships(validFrom1, validTo1, validFrom2, validTo2);
        }

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

        private void createRelationships(
                Date validFrom1, Date validTo1,
                Date validFrom2, Date validTo2) {
            relationship1 = new Meter2GenerationUnitRelationship__c(
                    Meter__c = meter.Id,
                    Generator_Unit__c = generationUnit.Id,
                    Valid_from__c = validFrom1,
                    Valid_to__c = validTo1);
            relationship2 = new Meter2GenerationUnitRelationship__c(
                    Meter__c = meter.Id,
                    Generator_Unit__c = generationUnit.Id,
                    Valid_from__c = validFrom2,
                    Valid_to__c = validTo2);
            insert relationship1;
            insert relationship2;
        }

        private void updateRelationships() {
            relationship1 = [SELECT Id, Active__c FROM Meter2GenerationUnitRelationship__c WHERE Id = :relationship1.Id];
            relationship2 = [SELECT Id, Active__c FROM Meter2GenerationUnitRelationship__c WHERE Id = :relationship2.Id];
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
    }
}