/****************************************************************************************************
     	* Class msBatchExpireContractsTest
     	*
     	*   Create By	:   MandyBebenroth (mindsquare GmbH)
     	*   Create Date	:   02.07.2020
     	*   Description	:	---
     	*
     	*   Modification Log:
    	*   -------------------------------------------------------------------------------------------------
    	*   * Developer                        	Date             	Description
    	*   * -----------------------------------------------------------------------------------------------                 
    	*   * MandyBebenroth (mindsquare GmbH)		02.07.2020       	Init version.
    	*****************************************************************************************************/
@IsTest
private with sharing class msBatchExpireContractsTest {
    private static final Integer BATCH_SIZE = 50;
    private static final Id DE_C_RECORD_TYPE = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId();

    @TestSetup
    private static void setup() {

    }

    @IsTest
    private static void updateContractsAndMeterRegistrations() {
        disableTriggers();

        Meter__c meter = new Meter__c();
        meter.Name = 'Test Meter';
        meter.Alternative_Meter_ID__c = '12345678901';
        insert meter;
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        testAccount.BillingCountry = 'Germany';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        insert testAccount;
        List<Contract__c> contractList = new List<Contract__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = DE_C_RECORD_TYPE,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(-1),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'new Contract' + i,
                    RED_Contract_ID__c = 'new Contract'
            ));
        }
        insert contractList;

        List<MeterRegistration__c> meterRegListActive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListActive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Active Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(+10), //should be updated, expired
                    Active__c = true));
        }

        List<MeterRegistration__c> meterRegListInactive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListInactive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Inactive Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(-10), //should not be updated, expired
                    Active__c = true));
        }

        List<MeterRegistration__c> meterRegListNullDate = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListNullDate.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'NullDate Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = null, //should be updated, expired
                    Active__c = true));
        }

        insert meterRegListActive;
        insert meterRegListInactive;
        insert meterRegListNullDate;

        enableTriggers();
        Test.startTest();
        Test.enableChangeDataCapture();

        Database.executeBatch(new msBatchExpireContracts(), BATCH_SIZE);
        Test.stopTest();

        Set<Id> contractIdsSet = new Set<Id>();
        for (Contract__c contractItem : contractList) {
            contractIdsSet.add(contractItem.Id);
        }
        for (Contract__c contractItem : [SELECT Status__c FROM Contract__c WHERE Id IN :contractIdsSet]) {
            System.assertEquals('Expired', contractItem.Status__c);
        }

        Set <Id> meterRegListActiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListActive) {
            meterRegListActiveIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListActiveIdsSet]) {
            System.assertEquals(Date.today().addDays(-1), meterRegistrationItem.Valid_to__c);
        }

        Set <Id> meterRegListInactiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListInactive) {
            meterRegListInactiveIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListInactiveIdsSet]) {
            System.assertEquals(Date.today().addDays(-10), meterRegistrationItem.Valid_to__c);
        }

        Set<Id> meterRegListNullDateIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListNullDate) {
            meterRegListNullDateIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListNullDateIdsSet]) {
            System.assertEquals(Date.today().addDays(-1), meterRegistrationItem.Valid_to__c);
        }
    }

    @IsTest
    private static void notUpdateContractAndMeterRegistrations() {
        Meter__c meter = new Meter__c();
        meter.Name = 'Test Meter';
        meter.Alternative_Meter_ID__c = '12345678901';
        insert meter;
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        testAccount.BillingCountry = 'Germany';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        insert testAccount;
        List<Contract__c> contractList = new List<Contract__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = DE_C_RECORD_TYPE,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+1),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'new Contract' + i,
                    RED_Contract_ID__c = 'new Contract'
            ));
        }
        insert contractList;

        List<MeterRegistration__c> meterRegListActive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListActive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Active Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(+10), //should be updated, expired
                    Active__c = true));
        }

        List<MeterRegistration__c> meterRegListInactive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListInactive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Inactive Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(-10), //should not be updated, expired
                    Active__c = true));
        }

        List<MeterRegistration__c> meterRegListNullDate = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListNullDate.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'NullDate Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = null, //should be updated, expired
                    Active__c = true));
        }

        insert meterRegListActive;
        insert meterRegListInactive;
        insert meterRegListNullDate;

        Test.startTest();
        Test.enableChangeDataCapture();

        Database.executeBatch(new msBatchExpireContracts(), BATCH_SIZE);
        Test.stopTest();

        Set <Id> contractIdsSet = new Set<Id>();
        for (Contract__c contractItem : contractList) {
            contractIdsSet.add(contractItem.Id);
        }
        for (Contract__c contractItem : [SELECT Status__c FROM Contract__c WHERE Id IN :contractIdsSet]) {
            System.assertEquals('Active', contractItem.Status__c);
        }

        Set <Id> meterRegListActiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListActive) {
            meterRegListActiveIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListActiveIdsSet]) {
            System.assertEquals(Date.today().addDays(+10), meterRegistrationItem.Valid_to__c);
        }

        Set <Id> meterRegListInactiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListInactive) {
            meterRegListInactiveIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListInactiveIdsSet]) {
            System.assertEquals(Date.today().addDays(-10), meterRegistrationItem.Valid_to__c);
        }

        Set <Id> meterRegListNullDateIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListNullDate) {
            meterRegListNullDateIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListNullDateIdsSet]) {
            System.assertEquals(null, meterRegistrationItem.Valid_to__c);
        }

    }

    @IsTest
    private static void notUpdateTodayContractAndMeterRegistrations() {
        Meter__c meter = new Meter__c();
        meter.Name = 'Test Meter';
        meter.Alternative_Meter_ID__c = '12345678901';
        insert meter;
        Account testAccount = new Account();
        testAccount.BillingCountry = 'Germany';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        testAccount.Name = 'TestAccount';
        insert testAccount;
        List<Contract__c> contractList = new List<Contract__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = DE_C_RECORD_TYPE,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today(),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'new Contract' + i,
                    RED_Contract_ID__c = 'new Contract'
            ));
        }
        insert contractList;

        List<MeterRegistration__c> meterRegListActive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListActive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Active Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(+10), //should be updated, expired
                    Active__c = true));
        }

        List<MeterRegistration__c> meterRegListInactive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListInactive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Inactive Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(-10), //should not be updated, expired
                    Active__c = true));
        }

        List<MeterRegistration__c> meterRegListNullDate = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListNullDate.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'NullDate Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = null, //should be updated, expired
                    Active__c = true));
        }

        insert meterRegListActive;
        insert meterRegListInactive;
        insert meterRegListNullDate;

        Test.startTest();
        Test.enableChangeDataCapture();

        Database.executeBatch(new msBatchExpireContracts(), BATCH_SIZE);
        Test.stopTest();

        Set <Id> contractIdsSet = new Set<Id>();
        for (Contract__c contractItem : contractList) {
            contractIdsSet.add(contractItem.Id);
        }
        for (Contract__c contractItem : [SELECT Status__c FROM Contract__c WHERE Id IN :contractIdsSet]) {
            System.assertEquals('Active', contractItem.Status__c);
        }

        Set <Id> meterRegListActiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListActive) {
            meterRegListActiveIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListActiveIdsSet]) {
            System.assertEquals(Date.today().addDays(+10), meterRegistrationItem.Valid_to__c);
        }

        Set <Id> meterRegListInactiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListInactive) {
            meterRegListInactiveIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListInactiveIdsSet]) {
            System.assertEquals(Date.today().addDays(-10), meterRegistrationItem.Valid_to__c);
        }

        Set <Id> meterRegListNullDateIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListNullDate) {
            meterRegListNullDateIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [SELECT Valid_to__c FROM MeterRegistration__c WHERE Id IN :meterRegListNullDateIdsSet]) {
            System.assertEquals(null, meterRegistrationItem.Valid_to__c);
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Account.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
    }
}