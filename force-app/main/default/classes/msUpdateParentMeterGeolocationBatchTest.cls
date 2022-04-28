/****************************************************************************************************
* Class msUpdateParentMeterGeolocationBatch
*
*   Create By	:   Maciej Dudek
*   Create Date	:   19.07.2019
*   Description	:	Updated GPS Location field on parent Meter based on one of its child Meters
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Maciej Dudek                  	               19.07.2019       	Init version.
*****************************************************************************************************/
@IsTest
private class msUpdateParentMeterGeolocationBatchTest {

    private static final Integer BULK_SIZE = 101;
    public static final Decimal DEFAULT_LONGITUDE = 6.9603;
    public static final Decimal DEFAULT_LATITUDE = 50.9375;

    @IsTest
    private static void testUpdateGPSOnParent() {
        SetupData setupData = new SetupData();
        setupData.createParentMeter();
        setupData.createMeter();

        Test.startTest();
        Database.executeBatch(new msUpdateParentMeterGeolocationBatch());
        Test.stopTest();

        setupData.queryParentMeter();

        System.assertEquals(DEFAULT_LATITUDE, setupData.parentMeter.GPS_Location__Latitude__s, 'Latitude not set');
        System.assertEquals(DEFAULT_LONGITUDE, setupData.parentMeter.GPS_Location__Longitude__s, 'Longitude not set');
    }


    private class SetupData {
        private Meter__c meter;
        private Meter__c parentMeter;

        private void createParentMeter() {
            parentMeter = new Meter__c();
            parentMeter.Name = 'Test parent meter';
            parentMeter.Status__c = 'Active';
            parentMeter.Country__c = 'Germany';
            parentMeter.Portfolio_ID__c = 'as_de2_parent';
            parentMeter.Alternative_Meter_ID__c = '10987654321';
            insert parentMeter;
        }

        private void createMeter() {
            meter = new Meter__c();
            meter.Name = 'Test meter';
            meter.Status__c = 'Active';
            meter.Country__c = 'Germany';
            meter.Portfolio_ID__c = 'as_de2_child';
            meter.Alternative_Meter_ID__c = '12345678901';
            meter.GPS_Location__Longitude__s = DEFAULT_LONGITUDE;
            meter.GPS_Location__Latitude__s = DEFAULT_LATITUDE;
            meter.Parent_Meter__c = parentMeter.Id;
            insert meter;
        }

        private void queryParentMeter() {
            parentMeter = [
                    SELECT Id, GPS_Location__Latitude__s, GPS_Location__Longitude__s
                    FROM Meter__c
                    WHERE Name = 'Test parent meter'
            ];
        }
    }

}