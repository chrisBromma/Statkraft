/****************************************************************************************************
* Class MeterRegistration_ChangeEventHandlerTest
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
private class MeterRegistration_ChangeEventHandlerTest {
    private static final Id PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;

    /**
     * WARNING: If the run time is too high, the execution of the events will be skipped and the assertions will simply fail.
     *          This can be noticed by the code coverage not even showing the Trigger to have passed.
      */

    @IsTest
    private static void testActivateRegistration_Insert() {
        Test.enableChangeDataCapture();
        disableTriggers();
        TestSetupData setupData = new TestSetupData();

        TriggerHandlerExtension.enableObject(MeterRegistration__ChangeEvent.SObjectType);
        Test.startTest();
        setupData.createFirstRegistration(Date.today().addMonths(1), null, false);
        setupData.createSecondRegistration(Date.today().addMonths(2), null, false);
        Test.stopTest();

        setupData.queryFirstRegistration();
        setupData.querySecondRegistration();

        System.assertEquals(true, setupData.firstRegistration.Active__c, 'First to start registration should be active');
        System.assertEquals(false, setupData.secondRegistration.Active__c, 'Second to start registration should be inactive');
    }

    @IsTest
    private static void testActivateRegistration_Update() {
        Test.enableChangeDataCapture();
        disableTriggers();
        TestSetupData setupData = new TestSetupData();
        setupData.createFirstRegistration(Date.today().addMonths(1), null, false);
        setupData.createSecondRegistration(Date.today().addMonths(2), null, false);
        Test.getEventBus().deliver();
        TriggerHandlerExtension.enableObject(MeterRegistration__ChangeEvent.SObjectType);

        Test.startTest();
        setupData.firstRegistration.Valid_from__c = Date.today().addMonths(2);
        setupData.secondRegistration.Valid_from__c = Date.today().addMonths(1);
        update setupData.firstRegistration;
        update setupData.secondRegistration;
        Test.stopTest();

        setupData.queryFirstRegistration();
        setupData.querySecondRegistration();

        System.assertEquals(true, setupData.secondRegistration.Active__c, 'First to start registration should be active');
        System.assertEquals(false, setupData.firstRegistration.Active__c, 'Second to start registration should be inactive');
    }

    @IsTest
    private static void testActivateRegistration_Delete() {
        Test.enableChangeDataCapture();
        disableTriggers();
        TestSetupData setupData = new TestSetupData();
        setupData.createFirstRegistration(Date.today().addMonths(1), null, false);
        setupData.createSecondRegistration(Date.today().addMonths(2), null, false);
        TriggerHandlerExtension.enableObject(MeterRegistration__ChangeEvent.SObjectType);
        Test.startTest();
        delete setupData.firstRegistration;
        Test.stopTest();

        setupData.querySecondRegistration();
        System.assertEquals(true, setupData.secondRegistration.Active__c, 'Second to start registration should be inactive');
    }

    @IsTest
    private static void testActivateRegistration_Undelete() {
        Test.enableChangeDataCapture();
        disableTriggers();
        TestSetupData setupData = new TestSetupData();
        setupData.createFirstRegistration(Date.today().addMonths(1), null, false);
        setupData.createSecondRegistration(Date.today().addMonths(2), null, false);
        delete setupData.firstRegistration;
        TriggerHandlerExtension.enableObject(MeterRegistration__ChangeEvent.SObjectType);
        Test.startTest();
        undelete setupData.firstRegistration;
        Test.stopTest();

        setupData.queryFirstRegistration();
        setupData.querySecondRegistration();

        System.assertEquals(true, setupData.firstRegistration.Active__c, 'First to start registration should be active');
        System.assertEquals(false, setupData.secondRegistration.Active__c, 'Second to start registration should be inactive');
    }

    private class TestSetupData {
        private Meter__c meter;
        private Contract__c contract;
        private MeterRegistration__c firstRegistration { get; set; }
        private MeterRegistration__c secondRegistration { get; set; }

        private TestSetupData() {
            createMeter();
            createContract();
        }

        private void createMeter() {
            meter = new Meter__c();
            meter.Name = 'Test Meter';
            meter.Alternative_Meter_ID__c = '12345678901';
            insert meter;
        }

        private void createContract() {
            Account testAccount = new Account();
            testAccount.BillingCountry = 'Germany';
            testAccount.Customer_Type__c = 'not yet identified';
            testAccount.Customer_Segment_industry__c = 'Large industrials';
            testAccount.Name = 'TestAccount';
            insert testAccount;

            contract = new Contract__c(
                    RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract1',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'DETestContract1',
                    Settlement_SubModel__c = null
            );
            insert contract;
        }

        private void createFirstRegistration(Date validFrom, Date validTo, Boolean isActive) {
            firstRegistration = new MeterRegistration__c();
            firstRegistration.Name = 'First Registration';
            firstRegistration.Meter__c = meter.Id;
            firstRegistration.Contract__c = contract.Id;
            firstRegistration.Valid_from__c = validFrom;
            firstRegistration.Valid_to__c = validTo;
            firstRegistration.Active__c = isActive;
            insert firstRegistration;
        }

        private void createSecondRegistration(Date validFrom, Date validTo, Boolean isActive) {
            secondRegistration = new MeterRegistration__c();
            secondRegistration.Name = 'Second Registration';
            secondRegistration.Meter__c = meter.Id;
            secondRegistration.Contract__c = contract.Id;
            secondRegistration.Valid_from__c = validFrom;
            secondRegistration.Valid_to__c = validTo;
            secondRegistration.Active__c = isActive;
            insert secondRegistration;
        }

        private void queryFirstRegistration() {
            firstRegistration = [SELECT Id, Active__c FROM MeterRegistration__c WHERE Name = 'First Registration'];
        }

        private void querySecondRegistration() {
            secondRegistration = [SELECT Id, Active__c FROM MeterRegistration__c WHERE Name = 'Second Registration'];
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);
    }
}