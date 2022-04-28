/****************************************************************************************************
* Class Contract_ChangeEventHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-01
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-01       	Init version.
*****************************************************************************************************/

@IsTest
private class Contract_ChangeEventHandlerTest {
    private static final Date TODAY = Date.today();
    private static final Integer BATCH_SIZE = 50;
    private static final Id UK_RETAIL_CONTRACT_REC_TYPE_ID = msTestDataFactory.UK_RETAIL_CONTRACT_REC_TYPE_ID;
    private static final Id CONTRACT_PPA_REC_TYPE_ID = msTestDataFactory.CONTRACT_PPA_RECORD_TYPE_ID;

    /**
     * WARNING: If the run time is too high, the execution of the events will be skipped and the assertions will simply fail.
     *          This can be noticed by the code coverage not even showing the Trigger to have passed.
      */

    //Contract Expiration Logic tests
    @IsTest
    static void contractExpiration_notUpdateContractAndMeterRegistrations() {
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
        for (Integer i = 0; i < 50; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = UK_RETAIL_CONTRACT_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+1),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'new Contract' + i,
                    RED_Contract_ID__c = 'new Contract',
                    Negotiating_Party__c = testAccount.Id
            ));
        }
        insert contractList;
        List<MeterRegistration__c> meterRegListActive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
            meterRegListActive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Active Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(+10), //should be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListInactive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
            meterRegListInactive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Inactive Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(-10), //should not be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListNullDate = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
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

        List <Contract__c> updateList = new List<Contract__c>();
        for (Contract__c cItem : contractList) {
            cItem.End_Date__c = Date.today().addDays(+10);
            updateList.add(cItem);
        }
        update updateList;

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
    static void contractExpiration_notUpdateTodayContractAndMeterRegistrations() {
        List<Meter__c> meters = new List<Meter__c>();
        for (Integer i = 0; i < 50; i++) {
            meters.add(new Meter__c(
                    Name = 'Test Meter ' + i,
                    Alternative_Meter_ID__c = '12345678901'
            ));
        }
        insert meters;
        Account testAccount = new Account();
        testAccount.BillingCountry = 'Germany';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        testAccount.Name = 'TestAccount';
        insert testAccount;
        List<Contract__c> contractList = new List<Contract__c>();
        for (Integer i = 0; i < 50; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = CONTRACT_PPA_REC_TYPE_ID,
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
        for (Integer i = 0; i < 50; i++) {
            meterRegListActive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Active Registration ' + i,
                    Meter__c = meters[i].Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(+10), //should be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListInactive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
            meterRegListInactive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Inactive Registration ' + i,
                    Meter__c = meters[i].Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(-10), //should not be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListNullDate = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
            meterRegListNullDate.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'NullDate Registration ' + i,
                    Meter__c = meters[i].Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = null, //should be updated, expired
                    Active__c = true));
        }
        insert meterRegListActive;
        insert meterRegListInactive;
        insert meterRegListNullDate;

        Test.startTest();
        Test.enableChangeDataCapture();

        List <Contract__c> updateList = new List<Contract__c>();
        for (Contract__c cItem : contractList) {
            cItem.End_Date__c = Date.today();
            updateList.add(cItem);
        }
        update updateList;

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
    static void contractExpiration_updateContractAndAssociatedRecords_batchSizeTest() {

        Test.enableChangeDataCapture();

        Date today = Date.today();
        List<Meter__c> meters = new List<Meter__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meters.add(new Meter__c(
                    Name = 'Test Meter ' + i,
                    Alternative_Meter_ID__c = '12345678901'
            ));
        }
        insert meters;
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        testAccount.BillingCountry = 'Germany';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        insert testAccount;
        List<Contract__c> contractList = new List<Contract__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = CONTRACT_PPA_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+10),
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
                    Meter__c = meters[i].Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(+10), //should be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListInactive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListInactive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Inactive Registration ' + i,
                    Meter__c = meters[i].Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(-10), //should not be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListNullDate = new List<MeterRegistration__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            meterRegListNullDate.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'NullDate Registration ' + i,
                    Meter__c = meters[i].Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = null, //should be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> regInsertList = new List<MeterRegistration__c>();
        regInsertList.addAll(meterRegListActive);
        regInsertList.addAll(meterRegListInactive);
        regInsertList.addAll(meterRegListNullDate);
        insert regInsertList;

        List<Generation_Unit__c> generators = new List<Generation_Unit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            generators.add(new Generation_Unit__c(
                    Name = 'DE Generation Unit for closure' + i,
                    Annual_Production__c = 320,
                    Portfolio_ID__c = 'DE_test for closure' + i,
                    Country__c = 'Germany'
            ));
        }
        insert generators;
        List<Meter2GenerationUnitRelationship__c> m2gRelList = new List<Meter2GenerationUnitRelationship__c>();
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            m2gRelList.add(new Meter2GenerationUnitRelationship__c (
                    Name = 'DE Meter 2 Generation Unit Relationship' + i,
                    Meter__c = meters[i].Id,
                    Generator_Unit__c = generators[i].Id,
                    Valid_from__c = today.addDays(-1),
                    Valid_to__c = null,
                    Active__c = true));
            ownerships.add(new Generation_Unit_Ownership__c(
                    Name = ' Test ' + i,
                    Asset_Owner__c = testAccount.Id,
                    Generation_Unit__c = generators[i].Id,
                    Start_Date__c = today.addDays(-1),
                    End_Date__c = null
            ));
        }
        insert m2gRelList;
        insert ownerships;

        Test.startTest();


        List <Contract__c> updateList = new List<Contract__c>();
        for (Contract__c cItem : contractList) {
            cItem.End_Date__c = Date.today().addDays(-1);
            cItem.Status__c = 'Expired';
            updateList.add(cItem);
        }
        update updateList;

        Test.stopTest();

        Set <Id> contractIdsSet = new Set<Id>();
        for (Contract__c contractItem : contractList) {
            contractIdsSet.add(contractItem.Id);
        }
        for (Contract__c contractItem : [SELECT Status__c FROM Contract__c WHERE Id IN :contractIdsSet]) {
            System.assertEquals('Expired', contractItem.Status__c);
        }
        Set <Id> meterRegListInactiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListInactive) {
            meterRegListInactiveIdsSet.add(meterRegistrationItem.Id);
        }
        Set <Id> meterRegListActiveIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListActive) {
            meterRegListActiveIdsSet.add(meterRegistrationItem.Id);
        }
        Set <Id> meterRegListNullDateIdsSet = new Set<Id>();
        for (MeterRegistration__c meterRegistrationItem : meterRegListNullDate) {
            meterRegListNullDateIdsSet.add(meterRegistrationItem.Id);
        }
        for (MeterRegistration__c meterRegistrationItem : [
                SELECT Valid_to__c
                FROM MeterRegistration__c
                WHERE Id IN :meterRegListInactiveIdsSet
                OR Id IN :meterRegListActiveIdsSet
                OR Id IN :meterRegListNullDateIdsSet

        ]) {
            if (meterRegListInactiveIdsSet.contains(meterRegistrationItem.Id)) {
                System.assertEquals(Date.today().addDays(-10), meterRegistrationItem.Valid_to__c);
            } else if (meterRegListActiveIdsSet.contains(meterRegistrationItem.Id)) {
                System.assertEquals(Date.today().addDays(-1), meterRegistrationItem.Valid_to__c);
            } else if (meterRegListNullDateIdsSet.contains(meterRegistrationItem.Id)) {
                System.assertEquals(Date.today().addDays(-1), meterRegistrationItem.Valid_to__c);
            }
        }
        for (Meter2GenerationUnitRelationship__c m2GItem : [
                SELECT Valid_to__c FROM Meter2GenerationUnitRelationship__c WHERE Id IN :m2gRelList
        ]) {
            System.assertEquals(null, m2GItem.Valid_to__c);
        }

        for (Generation_Unit_Ownership__c ownershipItem : [
                SELECT End_Date__c FROM Generation_Unit_Ownership__c WHERE Id IN :ownerships
        ]) {
            System.assertEquals(Date.today().addDays(-1), ownershipItem.End_Date__c);
        }
    }

    @IsTest
    static void contractExpiration_noUpdateForWhiteLabelInGermanyForRelatedObjects() {
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
        for (Integer i = 0; i < 50; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = CONTRACT_PPA_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+1),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'new Contract' + i,
                    RED_Contract_ID__c = 'new Contract',
                    Negotiating_Party__c = testAccount.Id,
                    Contract_Type_New__c = 'Sub-Contract',
                    Product_Type_New__c = 'White Label'
            ));
        }
        insert contractList;
        List<MeterRegistration__c> meterRegListActive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
            meterRegListActive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Active Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(+10), //should be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListInactive = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
            meterRegListInactive.add(new MeterRegistration__c(
                    Contract__c = contractList[i].Id,
                    Name = 'Inactive Registration ' + i,
                    Meter__c = meter.Id,
                    Valid_from__c = Date.today().addDays(-10),
                    Valid_to__c = Date.today().addDays(-10), //should not be updated, expired
                    Active__c = true));
        }
        List<MeterRegistration__c> meterRegListNullDate = new List<MeterRegistration__c>();
        for (Integer i = 0; i < 50; i++) {
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

        Test.getEventBus().deliver();
        enableTriggers();

        Test.startTest();
        Test.enableChangeDataCapture();

        List <Contract__c> updateList = new List<Contract__c>();
        for (Contract__c cItem : contractList) {
            cItem.End_Date__c = Date.today().addDays(-1);
            cItem.Status__c = 'Expired';
            updateList.add(cItem);
        }

        update updateList;

        Test.stopTest();

        Set <Id> contractIdsSet = new Set<Id>();
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
    static void testCalculationViaAssignments_batch_update() {
        Test.enableChangeDataCapture();
        disableTriggers();
        AssignmentTestData testData = createTestDataAssignments(BATCH_SIZE);
        Test.getEventBus().deliver();
        enableTriggers();

        Test.startTest();
        for(Contract__c contractItem : testData.Contracts) {
            contractItem.Start_for_Conga_Context__c = TODAY;
            contractItem.End_for_Conga_Context__c = contractItem.End_Date__c.addDays(1);
        }
        update testData.Contracts;
        Test.stopTest();

        testData.updateContracts();

        for(Contract__c contractItem : testData.Contracts) {
            System.assertEquals(0, contractItem.Active_Installed_Capacity__c);
            System.assertEquals(1, contractItem.Active_Installed_Capacity_Conga__c);
            System.assertEquals(0, contractItem.Active_Installed_Annual_Production__c);
            System.assertEquals(12, contractItem.Active_Installed_Production_Conga__c);
        }
    }


    private static AssignmentTestData createTestDataAssignments(Integer batchSize) {
        AssignmentTestData testData = new AssignmentTestData();

        testData.Owner = createAccount('earliest Owner');
        insert testData.Owner;

        List<Generation_Unit__c> gUnitsPast = new List<Generation_Unit__c>();
        List<Generation_Unit__c> gUnitsFuture = new List<Generation_Unit__c>();
        for (Integer i = 0; i < batchSize; i++) {
            gUnitsPast.add(createGenerationUnit('Unit Name ' + i));
            gUnitsFuture.add(createGenerationUnit('Unit Name Else ' + i));
            testData.Contracts.add(createContract(TODAY.addYears(-1), TODAY.addYears(1), testData.Owner.Id, 'Name' + i));
        }
        List<Generation_Unit__c> gUnits = new List<Generation_Unit__c>();
        gUnits.addAll(gUnitsPast);
        gUnits.addAll(gUnitsFuture);
        insert gUnits;
        insert testData.Contracts;

        for (Integer i = 0; i < batchSize; i++) {
            testData.Assignments.add(createAssignment(
                    testData.Contracts[i].Id,
                    gUnitsPast[i].Id,
                    testData.Contracts[i].Start_Date__c,
                    TODAY.addDays(-1)
            ));
            testData.Assignments.add(createAssignment(
                    testData.Contracts[i].Id,
                    gUnitsFuture[i].Id,
                    TODAY.addDays(1),
                    testData.Contracts[i].End_Date__c
            ));
        }
        insert testData.Assignments;
        return testData;
    }

    private static Account createAccount(String nameEntry) {
        return new Account (
                Name = nameEntry,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
    }

    private static Generation_Unit__c createGenerationUnit(String nameEntry) {
        return new Generation_Unit__c(
                Name = nameEntry,
                Annual_Production__c = 12,
                Installed_Capacity__c = 1,
                Country__c = 'Germany'
        );
    }

    private static Contract__c createContract(Date startDate, Date endDate, Id contractHolder, String nameString) {
        String status = 'Active';
        if (endDate < TODAY) {
            status = 'Expired';
        } else if (TODAY < startDate) {
            status = 'Draft';
        }
        return new Contract__c(
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Status__c = status,
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Name = nameString,
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = 'Germany',
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Start_for_Conga_Context__c = null,
                End_for_Conga_Context__c = null
        );
    }

    private static Generation_Unit_Assignment__c createAssignment(Id contractId, Id genUnitId, Date startDate, Date endDate) {
        return new Generation_Unit_Assignment__c(
                Contract__c = contractId,
                Generation_Unit__c = genUnitId,
                Start_Date__c = startDate,
                End_Date__c = endDate
        );
    }
    private class AssignmentTestData {
        public Account Owner { get; set; }
        public List<Contract__c> Contracts { get; set; }
        public List<Generation_Unit_Assignment__c> Assignments { get; set; }

        public AssignmentTestData() {
            Contracts = new List<Contract__c>();
            Assignments = new List<Generation_Unit_Assignment__c>();
        }

        public void updateContracts() {
            Contracts = [
                    SELECT Id,
                    Installed_Capacity__c,
                    Active_Installed_Capacity__c,
                    Active_Installed_Capacity_Conga__c,
                    Installed_Annual_Production__c,
                    Active_Installed_Annual_Production__c,
                    Active_Installed_Production_Conga__c,
                    Contracted_Annual_Production__c,
                    Contracted_Capacity__c
            FROM Contract__c
            WHERE Id IN :this.Contracts];
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        TriggerHandlerExtension.disableObject(Ammendment__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Assignment__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Account.SObjectType);
        TriggerHandlerExtension.enableObject(Ammendment__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit_Assignment__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Meter__c.SObjectType);
    }
}