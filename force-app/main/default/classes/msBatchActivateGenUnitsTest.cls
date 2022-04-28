/****************************************************************************************************
* Class msBatchActivateGenUnits
*
*   Create By	:   Maciej Dudek
*   Create Date	:   2019-07-15
*   Description	:	Testclass for msBatchActivateGenUnits
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Maciej Dudek (mindsquare GmbH)	            2019-07-15          	Init version.
*****************************************************************************************************/
@IsTest
private class msBatchActivateGenUnitsTest {
    @IsTest
    private static void shouldNotActivateRelationshipIfStartDateInFuture() {
        SetupData setupData = new SetupData();
        setupData.createMeter();
        setupData.createGenerationUnit();
        setupData.createRelationship(Date.today().addDays(2), null);

        Test.startTest();
        Database.executeBatch(new msBatchActivateGenUnits());
        Test.stopTest();

        setupData.queryRelationship();
        System.assertNotEquals(true, setupData.relationship.Active__c, 'Relation should not be active');
    }

    @IsTest
    private static void shouldNotActivateRelationshipIfEndDayPassed() {
        SetupData setupData = new SetupData();
        setupData.createMeter();
        setupData.createGenerationUnit();
        setupData.createRelationship(Date.today().addDays(-10), Date.today().addDays(-2));

        Test.startTest();
        Database.executeBatch(new msBatchActivateGenUnits());
        Test.stopTest();

        setupData.queryRelationship();
        System.assertNotEquals(true, setupData.relationship.Active__c, 'Relation should not be active');
    }

    @IsTest
    private static void shouldActivateRelationshipIfStartDayInPast() {
        SetupData setupData = new SetupData();
        setupData.createMeter();
        setupData.createGenerationUnit();
        setupData.createRelationship(Date.today().addDays(-10), null);

        Test.startTest();
        Database.executeBatch(new msBatchActivateGenUnits());
        Test.stopTest();

        setupData.queryRelationship();
        System.assertEquals(true, setupData.relationship.Active__c, 'Relation should be active');
    }

    @IsTest
    private static void shouldActivateNewestRelationship() {
        SetupData setupData = new SetupData();
        setupData.createMeter();
        setupData.createGenerationUnit();
        setupData.createRelationship(Date.today().addDays(-10), null);
        setupData.createRelationship(Date.today().addDays(-5), null);

        Test.startTest();
        Database.executeBatch(new msBatchActivateGenUnits());
        Test.stopTest();

        setupData.queryOlderRelationship();
        System.assertEquals(false, setupData.relationship.Active__c, 'Older relation should not be active');
        setupData.queryNewerRelationship();
        System.assertEquals(true, setupData.relationship.Active__c, 'Newer relation should be active');
    }

    private class SetupData {
        private Meter__c meter;
        private Generation_Unit__c generationUnit;
        private Meter2GenerationUnitRelationship__c relationship;

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