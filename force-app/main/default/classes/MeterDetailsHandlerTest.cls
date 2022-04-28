/****************************************************************************************************
* Class MeterDetailsHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-16
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-16       	Init version.
*****************************************************************************************************/

@IsTest
private class MeterDetailsHandlerTest {

    private static final Id Grid_Operator_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Grid_Operator_Details').Id;
    private static final Id Metering_Point_Operator_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Metering_Point_Operator_Details').Id;
    private static final Id MaLo_MeLo_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'MaLo_MeLo_Details').Id;
    private static final Id Merit_Order_Mode_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Merit_Order_Mode_Details').Id;
    private static final Id Redispatch_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Redispatch_Details').Id;

    @IsTest
    static void insert_PositiveTest() {
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
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsNew.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    Balancing_Model_Redispatch__c = 'Planwertmodell',
                    Signal_Routing_Redispatch__c = 'Duldungsfall',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Meter__c = testMeters[i].Id
            ));
        }

        List<Meter_Details__c> insertList = new List<Meter_Details__c>();
        insertList.addAll(meterDetailsOld);
        insertList.addAll(meterDetailsNew);
        insertList.addAll(meterDetailsFuture);

        Test.startTest();

        insert insertList;

        Test.stopTest();

        testMeters = [
                SELECT Metering_Point_Operator__c, Alternative_Meter_ID__c, Meter_ID__c, DSO__c,
                        TSO__c, Merit_Order_Mode__c, VPP_Type__c,
                        Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
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
            System.assertEquals('Planwertmodell', testMeter.Balancing_Model_Redispatch__c);
            System.assertEquals('Duldungsfall', testMeter.Signal_Routing_Redispatch__c);
        }
    }

    @IsTest
    static void insert_NegativeFutureTest() {
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
                    Merit_Order_Mode__c = 'P51_2017_RMW',
                    VPP_Type__c = 'EMSYS_S16_REF',
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Metering_Point_Operator__c = meteringPointOperators[0]
            ));
        }
        insert testMeters;

        List<Meter_Details__c> meterDetailsOld = new List<Meter_Details__c>();
        List<Meter_Details__c> meterDetailsNew = new List<Meter_Details__c>();
        List<Meter_Details__c> meterDetailsFuture = new List<Meter_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Metering_Point_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    Metering_Point_Operator__c = meteringPointOperators[2],
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
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Grid_Operator_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    DSO__c = distributors[2].Id,
                    TSO__c = distributors[5].Id,
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
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Meter__c = testMeters[i].Id
            ));
        }

        List<Meter_Details__c> insertList = new List<Meter_Details__c>();
        insertList.addAll(meterDetailsOld);
        insertList.addAll(meterDetailsNew);
        insertList.addAll(meterDetailsFuture);

        Test.startTest();

        insert insertList;

        Test.stopTest();

        testMeters = [
                SELECT Metering_Point_Operator__c, Alternative_Meter_ID__c, Meter_ID__c, DSO__c,
                        TSO__c, Merit_Order_Mode__c, VPP_Type__c,
                        Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
                FROM Meter__c
                WHERE Id IN :testMeters
        ];

        for (Meter__c testMeter : testMeters) {
            System.assertEquals(meteringPointOperators[0], testMeter.Metering_Point_Operator__c);
            System.assertEquals('TESTMALO11C', testMeter.Alternative_Meter_ID__c);
            System.assertEquals('0815', testMeter.Meter_ID__c);
            System.assertEquals(distributors[0].Id, testMeter.DSO__c);
            System.assertEquals(distributors[3].Id, testMeter.TSO__c);
            System.assertEquals('P51_2017_RMW', testMeter.Merit_Order_Mode__c);
            System.assertEquals('EMSYS_S16_REF', testMeter.VPP_Type__c);
            System.assertEquals('Prognosemodell', testMeter.Balancing_Model_Redispatch__c);
            System.assertEquals('Aufforderungsfall', testMeter.Signal_Routing_Redispatch__c);
        }
    }

    @IsTest
    static void insert_NegativePastTest() {
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
                    Alternative_Meter_ID__c = 'TESTMALO11B',
                    Meter_ID__c = '1350',
                    DSO__c = distributors[1].Id,
                    TSO__c = distributors[4].Id,
                    Merit_Order_Mode__c = 'P51_2017',
                    VPP_Type__c = 'EMSYS_W16',
                    Balancing_Model_Redispatch__c = 'Planwertmodell',
                    Signal_Routing_Redispatch__c = 'Duldungsfall',
                    Metering_Point_Operator__c = meteringPointOperators[1]
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
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = MaLo_MeLo_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    MALO__c = 'TESTMALO11C',
                    MELO__c = '0815',
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
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = Merit_Order_Mode_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    Merit_Order_Mode__c = 'P51_2017_RMW',
                    VPP_Type__c = 'EMSYS_S16_REF',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Meter__c = testMeters[i].Id
            ));
        }

        List<Meter_Details__c> insertList = new List<Meter_Details__c>();
        insertList.addAll(meterDetailsOld);
        insertList.addAll(meterDetailsNew);
        insertList.addAll(meterDetailsFuture);

        Test.startTest();

        insert insertList;

        Test.stopTest();

        testMeters = [
                SELECT Metering_Point_Operator__c, Alternative_Meter_ID__c, Meter_ID__c, DSO__c,
                        TSO__c, Merit_Order_Mode__c, VPP_Type__c,
                        Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
                FROM Meter__c
                WHERE Id IN :testMeters
        ];

        for (Meter__c testMeter : testMeters) {
            System.assertEquals(meteringPointOperators[1], testMeter.Metering_Point_Operator__c);
            System.assertEquals('TESTMALO11B', testMeter.Alternative_Meter_ID__c);
            System.assertEquals('1350', testMeter.Meter_ID__c);
            System.assertEquals(distributors[1].Id, testMeter.DSO__c);
            System.assertEquals(distributors[4].Id, testMeter.TSO__c);
            System.assertEquals('P51_2017', testMeter.Merit_Order_Mode__c);
            System.assertEquals('EMSYS_W16', testMeter.VPP_Type__c);
            System.assertEquals('Planwertmodell', testMeter.Balancing_Model_Redispatch__c);
            System.assertEquals('Duldungsfall', testMeter.Signal_Routing_Redispatch__c);
        }
    }

    @IsTest
    static void update_PositivePastTest() {
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
                    Alternative_Meter_ID__c = 'TESTMALO11B',
                    Meter_ID__c = '1350',
                    DSO__c = distributors[1].Id,
                    TSO__c = distributors[4].Id,
                    Merit_Order_Mode__c = 'P51_2017_RMW',
                    VPP_Type__c = 'EMSYS_S16_REF',
                    Metering_Point_Operator__c = meteringPointOperators[1]
            ));
        }
        insert testMeters;

        List<Meter_Details__c> meterDetailsOld = new List<Meter_Details__c>();
        List<Meter_Details__c> meterDetailsNew = new List<Meter_Details__c>();
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
            meterDetailsOld.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsNew.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    Balancing_Model_Redispatch__c = 'Planwertmodell',
                    Signal_Routing_Redispatch__c = 'Duldungsfall',
                    Meter__c = testMeters[i].Id
            ));
        }

        List<Meter_Details__c> insertList = new List<Meter_Details__c>();
        insertList.addAll(meterDetailsOld);
        insertList.addAll(meterDetailsNew);
        insert insertList;

        Test.startTest();

        for (Meter_Details__c detailsItem : meterDetailsNew) {
            detailsItem.Start_Date__c = TODAY.addDays(1);
        }
        for (Meter_Details__c detailsItem : meterDetailsOld) {
            detailsItem.End_Date__c = TODAY;
        }
        List<Meter_Details__c> updateList = new List<Meter_Details__c>();
        updateList.addAll(meterDetailsNew);
        updateList.addAll(meterDetailsOld);

        update updateList;

        Test.stopTest();

        testMeters = [
                SELECT Metering_Point_Operator__c, Alternative_Meter_ID__c, Meter_ID__c, DSO__c,
                        TSO__c, Merit_Order_Mode__c, VPP_Type__c,
                        Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
                FROM Meter__c
                WHERE Id IN :testMeters
        ];

        for (Meter__c testMeter : testMeters) {
            System.assertEquals(meteringPointOperators[0], testMeter.Metering_Point_Operator__c);
            System.assertEquals('TESTMALO11C', testMeter.Alternative_Meter_ID__c);
            System.assertEquals('0815', testMeter.Meter_ID__c);
            System.assertEquals(distributors[0].Id, testMeter.DSO__c);
            System.assertEquals(distributors[3].Id, testMeter.TSO__c);
            System.assertEquals('P51_2017', testMeter.Merit_Order_Mode__c);
            System.assertEquals('EMSYS_W16', testMeter.VPP_Type__c);
            System.assertEquals('Prognosemodell', testMeter.Balancing_Model_Redispatch__c);
            System.assertEquals('Aufforderungsfall', testMeter.Signal_Routing_Redispatch__c);
        }
    }

    @IsTest
    static void update_PositiveFutureTest() {
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
                    Alternative_Meter_ID__c = 'TESTMALO11B',
                    Meter_ID__c = '1350',
                    DSO__c = distributors[1].Id,
                    TSO__c = distributors[4].Id,
                    Merit_Order_Mode__c = 'P51_2017_RMW',
                    VPP_Type__c = 'EMSYS_S16_REF',
                    Metering_Point_Operator__c = meteringPointOperators[1]
            ));
        }
        insert testMeters;

        List<Meter_Details__c> meterDetailsNew = new List<Meter_Details__c>();
        List<Meter_Details__c> meterDetailsFuture = new List<Meter_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
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
            meterDetailsNew.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Meter__c = testMeters[i].Id
            ));
            meterDetailsFuture.add(new Meter_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    Balancing_Model_Redispatch__c = 'Planwertmodell',
                    Signal_Routing_Redispatch__c = 'Duldungsfall',
                    Meter__c = testMeters[i].Id
            ));
        }

        List<Meter_Details__c> insertList = new List<Meter_Details__c>();
        insertList.addAll(meterDetailsNew);
        insertList.addAll(meterDetailsFuture);
        insert insertList;

        Test.startTest();

        for (Meter_Details__c detailsItem : meterDetailsNew) {
            detailsItem.Start_Date__c = TODAY.addDays(-2);
            detailsItem.End_Date__c = TODAY.addDays(-1);
        }
        for (Meter_Details__c detailsItem : meterDetailsFuture) {
            detailsItem.Start_Date__c = TODAY;
        }
        List<Meter_Details__c> updateList = new List<Meter_Details__c>();
        updateList.addAll(meterDetailsNew);
        updateList.addAll(meterDetailsFuture);

        update updateList;

        Test.stopTest();

        testMeters = [
                SELECT Metering_Point_Operator__c, Alternative_Meter_ID__c, Meter_ID__c, DSO__c,
                        TSO__c, Merit_Order_Mode__c, VPP_Type__c,
                        Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
                FROM Meter__c
                WHERE Id IN :testMeters
        ];

        for (Meter__c testMeter : testMeters) {
            System.assertEquals(meteringPointOperators[2], testMeter.Metering_Point_Operator__c);
            System.assertEquals('TESTMALO11A', testMeter.Alternative_Meter_ID__c);
            System.assertEquals('4711', testMeter.Meter_ID__c);
            System.assertEquals(distributors[2].Id, testMeter.DSO__c);
            System.assertEquals(distributors[5].Id, testMeter.TSO__c);
            System.assertEquals('P51_2017', testMeter.Merit_Order_Mode__c);
            System.assertEquals('EMSYS_W16', testMeter.VPP_Type__c);
            System.assertEquals('Planwertmodell', testMeter.Balancing_Model_Redispatch__c);
            System.assertEquals('Duldungsfall', testMeter.Signal_Routing_Redispatch__c);
        }
    }

    @IsTest
    static void blockTimeOverlaps_insertTest() {
        Meter__c testMeter = new Meter__c(
                Name = 'testMeter_',
                Status__c = 'Active'
        );
        insert testMeter;

        List<Meter_Details__c> detailsToInsert = new List<Meter_Details__c>();
        Meter_Details__c firstDetails = new Meter_Details__c(
                Meter__c = testMeter.Id,
                Start_Date__c = Date.today().addDays(-1),
                End_Date__c = Date.today()
        );
        Meter_Details__c overlappingDetails = new Meter_Details__c(
                Meter__c = testMeter.Id,
                Start_Date__c = Date.today(),
                End_Date__c = null
        );

        detailsToInsert.add(firstDetails);
        detailsToInsert.add(overlappingDetails);

        Test.startTest();

        Boolean error = false;
        try {
            insert detailsToInsert;
            System.assert(false, 'An Error should have happened');
        } catch (Exception e) {
            error = true;
            System.assert(e.getMessage().contains(Label.Validation_Meter_Details_Timeline), 'An unexpected error happened: ' + e.getMessage());
        }

        Test.stopTest();

        System.assert(error, 'An error should have been caught');
    }

    @IsTest
    static void blockTimeOverlaps_updateTest() {
        Meter__c testMeter = new Meter__c(
                Name = 'testMeter_',
                Status__c = 'Active'
        );
        insert testMeter;

        List<Meter_Details__c> detailsToInsert = new List<Meter_Details__c>();
        Meter_Details__c firstDetails = new Meter_Details__c(
                Meter__c = testMeter.Id,
                Start_Date__c = Date.today().addDays(-1),
                End_Date__c = Date.today().addDays(1)
        );
        Meter_Details__c overlappingDetails = new Meter_Details__c(
                Meter__c = testMeter.Id,
                Start_Date__c = Date.today().addDays(2),
                End_Date__c = null
        );
        detailsToInsert.add(firstDetails);
        detailsToInsert.add(overlappingDetails);
        insert detailsToInsert;

        Test.startTest();

        firstDetails.End_Date__c = Date.today().addDays(-1);
        overlappingDetails.Start_Date__c = Date.today().addDays(-1);
        Boolean error = false;

        try {
            update detailsToInsert;
            System.assert(false, 'An Error should have happened');
        } catch (Exception e) {
            error = true;
            System.assert(e.getMessage().contains(Label.Validation_Meter_Details_Timeline), 'An unexpected error happened: ' + e.getMessage());
        }

        Test.stopTest();

        System.assert(error, 'An error should have been caught');
    }

    @IsTest
    static void blockTimeOverlaps_undeleteTest() {
        Meter__c testMeter = new Meter__c(
                Name = 'testMeter_',
                Status__c = 'Active'
        );
        insert testMeter;

        List<Meter_Details__c> details = new List<Meter_Details__c>();
        Meter_Details__c firstDetails = new Meter_Details__c(
                Meter__c = testMeter.Id,
                Start_Date__c = Date.today().addDays(-1),
                End_Date__c = Date.today().addDays(1)
        );
        Meter_Details__c overlappingDetails = new Meter_Details__c(
                Meter__c = testMeter.Id,
                Start_Date__c = Date.today().addDays(1),
                End_Date__c = null
        );
        details.add(firstDetails);
        details.add(overlappingDetails);
        insert firstDetails;
        delete firstDetails;
        insert overlappingDetails;
        delete overlappingDetails;

        Test.startTest();

        Boolean error = false;
        try {
            undelete details;
            System.assert(false, 'An Error should have happened');
        } catch (Exception e) {
            error = true;
            System.assert(e.getMessage().contains(Label.Validation_Meter_Details_Timeline), 'An unexpected error happened: ' + e.getMessage());
        }

        Test.stopTest();

        System.assert(error, 'An error should have been caught');
    }
}