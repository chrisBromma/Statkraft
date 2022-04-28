/****************************************************************************************************
* Class BatchUpdateMeterDetailsTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-08
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-08       	Init version.
*****************************************************************************************************/

@IsTest
private class BatchUpdateMeterDetailsTest {

    private static final Id Grid_Operator_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Grid_Operator_Details').Id;
    private static final Id Metering_Point_Operator_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Metering_Point_Operator_Details').Id;
    private static final Id MaLo_MeLo_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'MaLo_MeLo_Details').Id;
    private static final Id Merit_Order_Mode_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Merit_Order_Mode_Details').Id;


    @IsTest
    static void activateMeterDetails_batchTest() {
        TriggerHandlerExtension.disableObject(Meter_Details__c.SObjectType);

        List<String> meteringPointOperators = new List<String>();
        for (PicklistEntry entry : Meter_Details__c.Metering_Point_Operator__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                meteringPointOperators.add(entry.getValue());
            }
        }

        List<Account> distributors = new List<Account>();
        distributors.add(new Account(Name = 'DSO 1'));
        distributors.add(new Account(Name = 'DSO 2'));
        distributors.add(new Account(Name = 'DSO 3'));
        distributors.add(new Account(Name = 'TSO 1'));
        distributors.add(new Account(Name = 'TSO 2'));
        distributors.add(new Account(Name = 'TSO 3'));
        insert distributors;

        Integer BATCH_SIZE = 200;
        Date TODAY = Date.today();

        List<Meter__c> testMeters = new List<Meter__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            testMeters.add(new Meter__c(
                    Name = 'testMeter_' + i,
                    Status__c = 'Active',
                    Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                    Alternative_Meter_ID__c = 'TESTMALO11C',
                    Meter_ID__c = '0815',
                    DSO__c = distributors[0].Id,
                    TSO__c = distributors[3].Id,
                    Merit_Order_Mode__c = 'P51_2017',
                    VPP_Type__c = 'EMSYS_W16',
                    Metering_Point_Operator__c = meteringPointOperators[0]
            ));
        }
        insert testMeters;

        List<Meter_Details__c> meterDetailsOld = new List<Meter_Details__c>();
        List<Meter_Details__c> meterDetailsNew = new List<Meter_Details__c>();
        List<Meter_Details__c> meterDetailsFuture = new List<Meter_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = Metering_Point_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    Metering_Point_Operator__c = meteringPointOperators[0],
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsNew.add(new Meter_Details__c(
                    RecordTypeId = Metering_Point_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    Metering_Point_Operator__c = meteringPointOperators[1],
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Metering_Point_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    Metering_Point_Operator__c = meteringPointOperators[2],
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = MaLo_MeLo_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    MALO__c = 'TESTMALO11C',
                    MELO__c = '0815',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsNew.add(new Meter_Details__c(
                    RecordTypeId = MaLo_MeLo_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    MALO__c = 'TESTMALO11B',
                    MELO__c = '1350',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = MaLo_MeLo_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    MALO__c = 'TESTMALO11A',
                    MELO__c = '4711',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = Grid_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    DSO__c = distributors[0].Id,
                    TSO__c = distributors[3].Id,
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsNew.add(new Meter_Details__c(
                    RecordTypeId = Grid_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    DSO__c = distributors[1].Id,
                    TSO__c = distributors[4].Id,
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Grid_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    DSO__c = distributors[2].Id,
                    TSO__c = distributors[5].Id,
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = Merit_Order_Mode_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    Merit_Order_Mode__c = 'P51_2017',
                    VPP_Type__c = 'EMSYS_W16',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsNew.add(new Meter_Details__c(
                    RecordTypeId = Merit_Order_Mode_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    Merit_Order_Mode__c = 'P51_2017_RMW',
                    VPP_Type__c = 'EMSYS_S16_REF',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Merit_Order_Mode_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    Merit_Order_Mode__c = 'P51_2017',
                    VPP_Type__c = 'EMSYS_W16',
                    Meter__c = testMeters[i].Id
            ));
        }

        List<Meter_Details__c> insertList = new List<Meter_Details__c>();
        insertList.addAll(meterDetailsOld);
        insertList.addAll(meterDetailsNew);
        insertList.addAll(meterDetailsFuture);
        insert insertList;
        testMeters = [
                SELECT Metering_Point_Operator__c, Alternative_Meter_ID__c, Meter_ID__c, DSO__c,
                        TSO__c, Merit_Order_Mode__c, VPP_Type__c
                FROM Meter__c
                WHERE Id IN:testMeters
        ];

        for (Meter__c testMeter : testMeters) {
            System.assertEquals(meteringPointOperators[0], testMeter.Metering_Point_Operator__c);
            System.assertEquals('TESTMALO11C', testMeter.Alternative_Meter_ID__c);
            System.assertEquals('0815', testMeter.Meter_ID__c);
            System.assertEquals(distributors[0].Id, testMeter.DSO__c);
            System.assertEquals(distributors[3].Id, testMeter.TSO__c);
            System.assertEquals('P51_2017', testMeter.Merit_Order_Mode__c);
            System.assertEquals('EMSYS_W16', testMeter.VPP_Type__c);
        }

        TriggerHandlerExtension.enableObject(Meter_Details__c.SObjectType);
        Test.startTest();
        Database.executeBatch(new BatchUpdateMeterDetails(), 200);
        Test.stopTest();

        testMeters = [
                SELECT Metering_Point_Operator__c, Alternative_Meter_ID__c, Meter_ID__c, DSO__c,
                        TSO__c, Merit_Order_Mode__c, VPP_Type__c
                FROM Meter__c
                WHERE Id IN :testMeters
        ];

        for (Meter__c testMeter : testMeters) {
            System.assertEquals(meteringPointOperators[1], testMeter.Metering_Point_Operator__c);
            System.assertEquals('TESTMALO11B', testMeter.Alternative_Meter_ID__c);
            System.assertEquals('1350', testMeter.Meter_ID__c);
            System.assertEquals(distributors[1].Id, testMeter.DSO__c);
            System.assertEquals(distributors[4].Id, testMeter.TSO__c);
            System.assertEquals('P51_2017_RMW', testMeter.Merit_Order_Mode__c);
            System.assertEquals('EMSYS_S16_REF', testMeter.VPP_Type__c);
        }
    }
}