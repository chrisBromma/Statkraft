/**
 * Created by Steffen Naundorf on 23.09.2021.
 */

@IsTest
public with sharing class MeterFlowTest {


    @IsTest
    static void test_SetBalancingCircle() {
        fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();

        List<String>tsoNames = new List<String>{
                'Amprion GmbH', 'TenneT TSO GmbH', 'TransnetBW GmbH', '50Hertz Transmission GmbH'
        };
        for (String tsoName : tsoNames) {
            Account tso = createAccount(tsoName, 'Germany');
            uow.registerNew(tso);

            Meter__c meter = createMeter('Meter: ' + tsoName, null, 'Germany');
            uow.registerNew(meter, Meter__c.TSO__c, tso);
        }

        Test.startTest();
        uow.commitWork();
        Test.stopTest();

        List<Meter__c>testMeter = [SELECT Id, Name, TSO__r.Name, Balancing_Area__c FROM Meter__c WHERE TSO__c != null];
        for (Meter__c meter : testMeter) {
            switch on meter.TSO__r.Name {
                when 'Amprion GmbH' {
                    System.assertEquals('Amprion', meter.Balancing_Area__c);
                }
                when 'TenneT TSO GmbH' {
                    System.assertEquals('Tennet TSO', meter.Balancing_Area__c);
                }
                when 'TransnetBW GmbH' {
                    System.assertEquals('TransnetBW', meter.Balancing_Area__c);
                }
                when '50Hertz Transmission GmbH' {
                    System.assertEquals('50Hertz Transmission', meter.Balancing_Area__c);
                }
                when else {
                    System.assert(false, 'Meter should have Balancing Circle');
                }
            }
        }
    }

    @IsTest
    static void test_UpdateParentMetertechnology() {
        Meter__c parentMeter = createMeter('Parent Meter', null, 'Germany');
        insert parentMeter;

        Meter__c childMeter = createMeter('Child Meter', null, 'Germany');
        childMeter.RecordTypeId = Application.RecordTypes.byDeveloperName('Meter__c', 'Sub_Meter').Id;
        childMeter.Parent_Meter__c = parentMeter.Id;
        insert childMeter;

        Test.startTest();
        childMeter.Main_Technology__c = 'Wind Offshore';
        update childMeter;
        Test.stopTest();

        Meter__c testMeter = [SELECT Id, Name, Main_Technology__c, Country__c FROM Meter__c WHERE Id = :parentMeter.Id];
        System.assertEquals('Wind Offshore', testMeter.Main_Technology__c);
    }
    
    @IsTest
    static void test_UpdateParentMetertechnologyFail() {
        Meter__c parentMeter = createMeter('Parent Meter', null, 'France');
        insert parentMeter;

        Meter__c childMeter = createMeter('Child Meter', null, 'France');
        childMeter.RecordTypeId = Application.RecordTypes.byDeveloperName('Meter__c', 'Sub_Meter').Id;
        childMeter.Parent_Meter__c = parentMeter.Id;
        insert childMeter;

        Test.startTest();
        childMeter.Main_Technology__c = 'Wind Offshore';
        update childMeter;
        Test.stopTest();

        Meter__c testMeter = [SELECT Id, Name, Main_Technology__c, Country__c FROM Meter__c WHERE Id = :parentMeter.Id];
        System.assertNotEquals('Wind Offshore', testMeter.Main_Technology__c);
    }

    @IsTest
    static void test_ChangeDSODate() {
        Meter__c testMeter = createMeter('Test Meter', null, 'France');
        testMeter.RecordTypeId = Application.RecordTypes.byDeveloperName('Meter__c', 'Export_Meter').Id;
        insert testMeter;

        List<Case>cases = [SELECT Id FROM Case WHERE Meter__c = :testMeter.Id];
        System.assertEquals(0, cases.size());

        Test.startTest();
        testMeter.DSO_Commissioning_Date__c = Date.today();
        update testMeter;
        Test.stopTest();


        cases = [SELECT Id FROM Case WHERE Meter__c = :testMeter.Id];
        System.assertEquals(1, cases.size());
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

}