/****************************************************************************************************
* Class msUpdateMeterGPSLocationBatchTest
*
*   Create By	:   Maciej Dudek
*   Create Date	:   26.06.2019
*   Description	:	Test class for msUpdateMeterGPSLocationBatchTest
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Maciej Dudek                  	               26.06.2019       	Init version.
*****************************************************************************************************/

@IsTest
private class msUpdateMeterGPSLocationBatchTest {

    private static final Integer BULK_SIZE = 101;
    public static final Decimal DEFAULT_LONGITUDE = 6.9603;
    public static final Decimal DEFULT_LATITUDE = 50.9375;

    @IsTest
    private static void shouldUpdateMeterGPSLocation() {
        SetupData setupData = new SetupData();
        setupData.createMetersWithoutGeolocation();
        setupData.createGenerationUnits();
        setupData.createMeter2GenerationUnitRelationships();

        Test.startTest();
            Database.executeBatch(new msUpdateMeterGPSLocationBatch());
        Test.stopTest();

        setupData.queryMeters();

        for(Meter__c meter : setupData.testMeters) {
            System.assertNotEquals(null, meter.GPS_Location__Longitude__s, 'GRS Longitude not set');
            System.assertNotEquals(null, meter.GPS_Location__Latitude__s, 'GRS Latitude not set');
        }
    }

    private class SetupData {
        private List<Meter__c> testMeters;
        private List<Generation_Unit__c> testGenerationUnits;
        private List<Meter2GenerationUnitRelationship__c> testMeter2GenerationUnitRelationships;

        private void createMetersWithoutGeolocation() {
            testMeters = new List<Meter__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                testMeters.add(createTestMeter(i));
            }
            insert testMeters;
        }

        private Meter__c createTestMeter(Integer index) {
            Meter__c meter = new Meter__c();
            meter.Name = 'Meter' + index;
            meter.Status__c = 'Active';
            meter.Country__c = 'Germany';
            meter.Portfolio_ID__c = 'as_de2_an_11210_windpark_hohenseefeld' + index;
            meter.Alternative_Meter_ID__c = 'ABCDEFGHIJK';
            return meter;
        }

        private void createGenerationUnits() {
            testGenerationUnits = new List<Generation_Unit__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                testGenerationUnits.add(createGenerationUnit(i));
            }
            insert testGenerationUnits;
        }

        private Generation_Unit__c createGenerationUnit(Integer index) {
            Generation_Unit__c generationUnit = new Generation_Unit__c();
            generationUnit.Name = 'Test Generation Unit' + index;
            generationUnit.Annual_Production__c = 320;
            generationUnit.Portfolio_ID__c = 'test' + index;
            generationUnit.Country__c = 'Germany';
            generationUnit.GPS_Location__Latitude__s = DEFULT_LATITUDE + (index / 10);
            generationUnit.GPS_Location__Longitude__s = DEFAULT_LONGITUDE + (index / 10);
            return generationUnit;
        }

        private void createMeter2GenerationUnitRelationships() {
            testMeter2GenerationUnitRelationships = new List<Meter2GenerationUnitRelationship__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                testMeter2GenerationUnitRelationships.add(createMeter2GenerationUnitRelationship(i));
            }
            insert testMeter2GenerationUnitRelationships;
        }

        private Meter2GenerationUnitRelationship__c createMeter2GenerationUnitRelationship(Integer index) {
            Meter2GenerationUnitRelationship__c relationship = new Meter2GenerationUnitRelationship__c();
            relationship.Name = 'Test Relationship ' + index;
            relationship.Meter__c = testMeters[index].Id;
            relationship.Generator_Unit__c = testGenerationUnits[index].Id;
            relationship.Valid_from__c = Date.today().addMonths(-1);
            return relationship;
        }

        private void queryMeters() {
            testMeters = [SELECT Id, GPS_Location__Longitude__s, GPS_Location__Latitude__s FROM Meter__c];
        }
    }
}