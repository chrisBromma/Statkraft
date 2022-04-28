/**
 * Created by Steffen Naundorf on 23.09.2021.
 */

@IsTest
public with sharing class CaseFlowTest {
    @IsTest
    private static void testCSROwnerChangeBvD() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        testAccount.BvD_Catalyst_Status__c = 'Red';
        testAccount.Extended_CSR__c = true;
        insert testAccount;
        enableTrigger();

        Test.startTest();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'Middle_Office_Case').Id;
        testCase.AccountId = testAccount.Id;
        testCase.Status = 'New';
        insert testCase;

        Test.stopTest();

        testCase = [SELECT Id, Owner.Name, Subject FROM Case];
        System.assertEquals('0050Y000003CMeK', [SELECT Id, OwnerId, Subject FROM Case WHERE Id = :testCase.Id].OwnerId);
    }

    @IsTest
    private static void testCSROwnerChangeMO() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;
        enableTrigger();

        Test.startTest();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'Middle_Office_Case').Id;
        testCase.AccountId = testAccount.Id;
        testCase.Status = 'New';
        insert testCase;

        Test.stopTest();

        testCase = [SELECT Id, Owner.Name, Subject FROM Case];
        System.assertEquals('00G0Y000003N2EH', [SELECT Id, OwnerId, Subject FROM Case WHERE Id = :testCase.Id].OwnerId);
    }

    @IsTest
    private static void testCSROwnerChangeIndia() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'India');
        insert testAccount;
        enableTrigger();

        Test.startTest();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'Middle_Office_Case').Id;
        testCase.AccountId = testAccount.Id;
        testCase.Status = 'New';
        insert testCase;

        Test.stopTest();

        testCase = [SELECT Id, Owner.Name, Subject FROM Case];
        System.assertEquals('00G1v000006WpoDEAS', [SELECT Id, OwnerId, Subject FROM Case WHERE Id = :testCase.Id].OwnerId);
    }

    @IsTest
    private static void testVppTaskCreation() {
        System.assertEquals(0, [SELECT Id FROM Task].size());

        Test.startTest();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'VPP_Setup_Case').Id;
        testCase.Status = 'New';
        testCase.Case_Creator__c = [SELECT ID FROM User WHERE IsActive = true AND Profile.Name = 'UK PPA' LIMIT 1].Id;
        insert testCase;

        Test.stopTest();

        testCase = [SELECT Id, Owner.Name, Subject FROM Case];
        System.assertEquals(3, [SELECT Id FROM Task].size());
    }

    @IsTest
    private static void testSetCSRCheck() {
        User testUser=[SELECT ID FROM User WHERE UserRole.Name='Middle Office' LIMIT 1];
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;
        enableTrigger();

        System.assertEquals(false, [SELECT Id, CSR_Check__c FROM Account WHERE Id = :testAccount.Id].CSR_Check__c);

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'Middle_Office_Case').Id;
        testCase.OwnerId = '00G0Y000003N2EH'; //Middle Office Queue
        testCase.Status = 'New';
        testCase.AccountId = testAccount.Id;

        Test.startTest();
        System.runAs(testUser){
            insert testCase;
            System.assertEquals(false, [SELECT Id, CSR_Check__c FROM Account WHERE Id = :testAccount.Id].CSR_Check__c);

            testCase.Status = 'Closed (Passed)';
            update testCase;
        }
        Test.stopTest();

        System.assertEquals(true, [SELECT Id, CSR_Check__c FROM Account WHERE Id = :testAccount.Id].CSR_Check__c);
    }

    @IsTest
    private static void testSetCSRCheckFail() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;
        enableTrigger();

        System.assertEquals(false, [SELECT Id, CSR_Check__c FROM Account WHERE Id = :testAccount.Id].CSR_Check__c);

        Test.startTest();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'Middle_Office_Case').Id;
        testCase.OwnerId = '00G0Y000003O4ji'; //VPP Setup Queue
        testCase.Status = 'New';
        testCase.AccountId = testAccount.Id;
        insert testCase;

        System.assertEquals(false, [SELECT Id, CSR_Check__c FROM Account WHERE Id = :testAccount.Id].CSR_Check__c);

        testCase.Status = 'Closed (Passed)';
        update testCase;
        Test.stopTest();

        System.assertEquals(false, [SELECT Id, CSR_Check__c FROM Account WHERE Id = :testAccount.Id].CSR_Check__c);
    }

    @IsTest
    private static void testUpdateMeterReg_MeterDeregistration() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;

        Contract__c testContract = createContract(testAccount.Id);
        insert testContract;

        Meter__c testMeter = createMeter('Test Meter');
        insert testMeter;

        MeterRegistration__c testRegistration = createRegistration(testContract.Id, testMeter.Id, Date.today().addDays(-5), null, true);
        insert testRegistration;
        enableTrigger();

        System.assertNotEquals('Deregistration not sent', [SELECT Id, Status__c FROM MeterRegistration__c WHERE Id = :testRegistration.Id].Status__c);

        Test.startTest();

        Case testCase = new Case();
        testCase.Country__c = 'Germany';
        testCase.Contract__c = testContract.Id;
        testCase.Reason = 'Meter deregistration';
        insert testCase;

        Test.stopTest();

        System.assertEquals('Deregistration not sent', [SELECT Id, Status__c FROM MeterRegistration__c WHERE Id = :testRegistration.Id].Status__c);
    }

    @IsTest
    private static void testUpdateMeterReg_ChangeOfBillingType() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;

        Contract__c testContract = createContract(testAccount.Id);
        insert testContract;

        Meter__c testMeter = createMeter('Test Meter');
        insert testMeter;

        MeterRegistration__c testRegistration = createRegistration(testContract.Id, testMeter.Id, Date.today().addDays(-5), null, true);
        insert testRegistration;
        enableTrigger();

        System.assertNotEquals('Request not sent', [SELECT Id, Status_Change_of_New_Billing_Type__c FROM MeterRegistration__c WHERE Id = :testRegistration.Id].Status_Change_of_New_Billing_Type__c);

        Test.startTest();

        Case testCase = new Case();
        testCase.Country__c = 'Germany';
        testCase.Contract__c = testContract.Id;
        testCase.Reason = 'Change of billing type';
        insert testCase;

        Test.stopTest();

        System.assertEquals('Request not sent', [SELECT Id, Status_Change_of_New_Billing_Type__c FROM MeterRegistration__c WHERE Id = :testRegistration.Id].Status_Change_of_New_Billing_Type__c);
    }

    @IsTest
    private static void testESalesSetupCheck() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;

        Contract__c testContract = createContract(testAccount.Id);
        insert testContract;
        enableTrigger();

        System.assertEquals(false, [SELECT Id, eSales_Setup_Check__c FROM Contract__c WHERE Id = :testContract.Id].eSales_Setup_Check__c);

        Test.startTest();

        Case testCase = new Case();
        testCase.Contract__c = testContract.Id;
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'ESales_Setup_Case').Id;
        insert testCase;

        System.assertEquals(false, [SELECT Id, eSales_Setup_Check__c FROM Contract__c WHERE Id = :testContract.Id].eSales_Setup_Check__c);

        testCase.Status = 'Closed (Passed)';
        update testCase;
        Test.stopTest();

        System.assertEquals(true, [SELECT Id, eSales_Setup_Check__c FROM Contract__c WHERE Id = :testContract.Id].eSales_Setup_Check__c);
    }
    @IsTest
    private static void testSAPSetupCheckFail() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;

        Contract__c testContract = createContract(testAccount.Id);
        insert testContract;
        enableTrigger();

        System.assertEquals(false, [SELECT Id, SAP_Setup_Check__c FROM Contract__c WHERE Id = :testContract.Id].SAP_Setup_Check__c);

        Test.startTest();

        Case testCase = new Case();
        testCase.Contract__c = testContract.Id;
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'SAP_Setup_Case').Id;
        insert testCase;

        System.assertEquals(false, [SELECT Id, SAP_Setup_Check__c FROM Contract__c WHERE Id = :testContract.Id].SAP_Setup_Check__c);

        testCase.Status = 'Closed (Passed)';
        update testCase;
        Test.stopTest();

        System.assertEquals(true, [SELECT Id, SAP_Setup_Check__c FROM Contract__c WHERE Id = :testContract.Id].SAP_Setup_Check__c);
    }

    @IsTest
    private static void testPopulateSubjectGuaranteeAmendment() {
        Test.startTest();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'Guarantee_Amendment_Request').Id;
        insert testCase;

        Test.stopTest();

        System.assertEquals('Guarantee Amendment Request', [SELECT Id, Subject FROM Case WHERE Id = :testCase.Id].Subject);
    }
    @IsTest
    private static void testPopulateSubjectNewGuaranteeRequest() {
        Test.startTest();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'New_Guarantee_Request').Id;
        testCase.Reason = 'Termination confirmation';
        insert testCase;

        Test.stopTest();

        System.assertEquals('New Guarantee Request', [SELECT Id, Subject FROM Case WHERE Id = :testCase.Id].Subject);
    }

    @IsTest
    private static void testTreasuryCaseOwnerChange() {
        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'New_Guarantee_Request').Id;
        insert testCase;

        System.assertEquals('New', [SELECT Id, Status FROM Case WHERE Id = :testCase.Id].Status);

        Test.startTest();
        testCase.OwnerId = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId() LIMIT 1].Id;
        update testCase;
        Test.stopTest();

        System.assertEquals('In Progress', [SELECT Id, Status FROM Case WHERE Id = :testCase.Id].Status);
    }

    @IsTest
    private static void testTerminationCaseClosed() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;

        Contract__c testContract = createContract(testAccount.Id);
        insert testContract;
        enableTrigger();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'New_Guarantee_Request').Id;
        testCase.Reason = 'Termination confirmation';
        testCase.Contract__c = testContract.Id;
        insert testCase;
        System.assertEquals(1, [SELECT Id FROM Case].size());

        Test.startTest();
        testCase.Status = 'Closed (Passed)';
        update testCase;
        Test.stopTest();

        System.assertEquals(3, [SELECT Id FROM Case].size());
    }

    @IsTest
    private static void testTerminationCaseClosedRemit() {
        disableTrigger();
        Account testAccount = createAccount('testAccount', 'Germany');
        insert testAccount;

        Contract__c testContract = createContract(testAccount.Id);
        testContract.REMIT_Reporting_Relevant__c = true;
        insert testContract;
        enableTrigger();

        Case testCase = new Case();
        testCase.RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'New_Guarantee_Request').Id;
        testCase.Reason = 'Termination confirmation';
        testCase.Contract__c = testContract.Id;
        insert testCase;
        System.assertEquals(1, [SELECT Id FROM Case].size());

        Test.startTest();
        testCase.Status = 'Closed (Passed)';
        update testCase;
        Test.stopTest();

        System.assertEquals(4, [SELECT Id FROM Case].size());
    }


    private static Account createAccount(
            String name,
            String country) {

        Account newAccount = new Account(
                Name = name,
                BillingCountry = country,
                Country__c=country,
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'

        );
        return newAccount;
    }
    private static Contract__c createContract(Id contractHolder) {
        return new Contract__c(
                Start_Date__c = Date.today().addYears(-1),
                End_Date__c = Date.today().addYears(1),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Name = 'Will be overwritten',
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = 'Germany',
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0
        );
    }

    private static Meter__c createMeter(String nameEntry) {
        return new Meter__c(
                Name = nameEntry,
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'Germany'
        );
    }

    private static MeterRegistration__c createRegistration(Id contractId, Id meterId, Date startDate, Date endDate, Boolean active) {
        return new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contractId,
                Meter__c = meterId,
                Volume_Share__c = 100,
                Valid_from__c = startDate,
                Valid_to__c = endDate,
                Active__c = active,
                Country__c = 'Germany');
    }
    private static void disableTrigger() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
    }
    private static void enableTrigger() {
        TriggerHandlerExtension.enableObject(Account.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
    }
}