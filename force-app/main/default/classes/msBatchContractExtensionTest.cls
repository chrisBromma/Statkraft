/****************************************************************************************************
* Class msBatchContractExtensionTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-10-28
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-10-28       	Init version.
*****************************************************************************************************/
@IsTest
private without sharing class msBatchContractExtensionTest {
    private static final Id PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;
    private static final Id DE_ACC_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Account', 'Account').Id;
    private static final String BANK_ACC_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Account', 'SK_Bank').Id;
    private static final Id SK_BANK_GUARANTEE_LOCKED_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('SK_Security__c', 'SK_Bank_Guarantee_Locked').Id;
    private static final Id CONTRACT_ROLE_CONTACT_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Contract_Role__c', 'Contract_Role_Contact').Id;
    private static final Id OFFER_PPA_EXTENSION_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Extension').Id;

    @TestSetup
    private static void setup() {
        disableTriggers();
        Core_Batch_Settings__mdt settings = msContractAutoExtensionHandling.getBatchJobsSettings();

        Integer batchSize = (Integer) settings.Contract_Extension_Batch_Size__c;
        Integer batchSizeHalf = Math.abs(batchSize / 2);


        Meter__c meter = new Meter__c();
        meter.Name = 'Test Meter';
        meter.Alternative_Meter_ID__c = '12345678901';
        insert meter;

        List<Account> accountsToInsert = new List<Account>();

        Account deAccount = new Account();
        deAccount.Name = 'Test Account DE';
        deAccount.RecordTypeId = DE_ACC_RECORD_TYPE;
        deAccount.BillingCountry = 'Germany';
        deAccount.Customer_Type__c = 'not yet identified';
        deAccount.Customer_Segment_industry__c = 'Large industrials';
        accountsToInsert.add(deAccount);

        Account bank = new Account();
        bank.Name = 'Test BANK Account DE';
        bank.RecordTypeId = BANK_ACC_RECORD_TYPE;
        bank.BillingCountry = 'Germany';
        bank.Customer_Type__c = 'not yet identified';
        bank.Customer_Segment_industry__c = 'Large industrials';
        accountsToInsert.add(bank);

        insert accountsToInsert;

        Contact testContact = new Contact();
        testContact.LastName = 'mindsquaretestusercereatedinunit';
        testContact.Email = 'fake@email.testcreation';
        testContact.AccountId = deAccount.Id;
        insert testContact;

        List <Contract__c> dummyContracts = new List<Contract__c>();
        for (Integer i = 0; i < batchSize - 1; i++) {
            dummyContracts.add(new Contract__c(
                    Name = 'Test ' + i,
                    Contract_Holder__c = deAccount.Id,
                    RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = Date.newInstance(Date.today().year(), 01, 01),
                    End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract ' + i,
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Settlement_SubModel__c = null
            ));
        }
        dummyContracts.add(new Contract__c(
                Name = 'Test ',
                Contract_Holder__c = deAccount.Id,
                RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                Start_Date__c = Date.newInstance(Date.today().year(), 01, 01),
                End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                Status__c = 'Active',
                Country__c = 'Germany',
                RED_Contract_ID__c = 'GermanTestContract ',
                Approved__c = true,
                Meter_Billing_Type__c = 'Sub-Meter Yearly',
                Settlement_SubModel__c = null
        ));
        insert dummyContracts;

        Opportunity opp = new Opportunity(
                Name = 'test',
                Start_Date__c = Date.today().addDays(-20),
                End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                Contract_Type_New__c = 'Feed in Tariff PPA',
                Product_Type_New__c = 'Direct Marketing',
                Country__c = 'Germany',
                StageName = 'New',
                CloseDate = Date.today(),
                AccountId = deAccount.Id
        );
        insert opp;

        List<Offer__c> offers = new List<Offer__c>();
        for (Contract__c dummyContract : dummyContracts) {
            offers.add(new Offer__c(
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Country__c = 'Germany',
                    Status__c = 'Document Generation',
                    Base_Contract__c = dummyContract.Id,
                    RecordTypeId = OFFER_PPA_EXTENSION_REC_TYPE_ID,
                    Workflow_Type__c = 'Amendment',
                    Contract_Start_Date_Offer__c = Date.today(),
                    Contract_End_Date_Offer__c = Date.today(),
                    Resulting_Termination_Status__c = 'Automatic yearly extension',
                    Opportunity__c = opp.Id,
                    Meter_Billing_Type__c = 'Regular',
                    Billing_Model_Redispatch__c = 'Spitz',
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Facility_Description__c = 'Anaerobic Digestion',
                    Technology__c = 'Biofuel',
                    Offer_Installed_Capacity__c = 10,
                    BTR_Role__c = false,
                    BTR__c = deAccount.Id,
                    EIV__c = deAccount.Id,
                    Risk_Premium_DE__c = 0
            ));
        }
        insert offers;

        List <Contract_Role__c> dummyContractRoles = new List<Contract_Role__c>();
        List <Pricing_Component__c> dummyPricingComponents = new List<Pricing_Component__c>();
        List <SK_Security__c> dummyGuarantees = new List<SK_Security__c>();
        Id pcRecTypeId = Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Floating_Energy_Price').getRecordTypeId();
        for (Integer i = 0; i < batchSize; i++) {
            if (i >= batchSizeHalf) {
                dummyGuarantees.add(new SK_Security__c(
                        SK_Contract__c = dummyContracts[i].Id,
                        SK_Notional_Amount__c = 20000,
                        SK_No_End_Date__c = true,
                        SK_Status__c = 'Guarantee Issued',
                        RecordTypeId = SK_BANK_GUARANTEE_LOCKED_REC_TYPE_ID,
                        SK_Approved__c = true,
                        SK_Bank__c = bank.Id,
                        SK_Direction__c = ''
                ));
            }
            if (i < batchSizeHalf) {
                dummyGuarantees.add(new SK_Security__c(
                        SK_Contract__c = dummyContracts[i].Id,
                        SK_End_Date__c = dummyContracts[i].End_Date__c.addMonths(1),
                        SK_Notional_Amount__c = 10000,
                        SK_No_End_Date__c = false,
                        RecordTypeId = SK_BANK_GUARANTEE_LOCKED_REC_TYPE_ID,
                        SK_Status__c = 'Expiring',
                        SK_Approved__c = true,
                        SK_Bank__c = bank.Id,
                        SK_Direction__c = ''
                ));
                dummyPricingComponents.add(new Pricing_Component__c (Name = 'Test',
                        Contract__c = dummyContracts[i].Id,
                        Index_Price__c = 'SSP',
                        RecordTypeId = pcRecTypeId,
                        Start_Date__c = Date.today(),
                        End_Date__c = dummyContracts[i].End_Date__c
                ));
                dummyContractRoles.add(new Contract_Role__c(
                        Contact__c = testContact.Id,
                        Contract__c = dummyContracts[i].Id,
                        Role__c = 'Contractual contact',
                        End_Date__c = dummyContracts[i].End_Date__c,
                        RecordTypeId = CONTRACT_ROLE_CONTACT_REC_TYPE_ID
                ));
            }
        }

        insert dummyContractRoles;
        insert dummyPricingComponents;
        insert dummyGuarantees;
        enableTriggers();
    }

    @IsTest
    private static void testAutoExtension() {

        List<Contract__c> dummyContracts = [SELECT Id, End_Date__c FROM Contract__c];
        List<Pricing_Component__c> dummyPricingComponents = [SELECT Id, End_Date__c FROM Pricing_Component__c];
        Core_Batch_Settings__mdt settings = msContractAutoExtensionHandling.getBatchJobsSettings();

        Set<Id> contractIds = new Set<Id>();
        for (Contract__c contractItem : dummyContracts) {
            contractIds.add(contractItem.Id);
        }

        Test.startTest();
        Database.executeBatch(new msBatchContractExtension(contractIds), (Integer) settings.Contract_Extension_Batch_Size__c);
        Test.stopTest();

        Set<Id> pcIds = new Set<Id>();
        for (Pricing_Component__c pcItem : dummyPricingComponents) {
            pcIds.add(pcItem.Id);
        }
        Map<Id, Contract__c> newContractMap = new Map<Id, Contract__c> ([
                SELECT Id, End_Date__c
                FROM Contract__c
                WHERE Id IN :contractIds
        ]);
        Map<Id, Pricing_Component__c> newPCMap = new Map<Id, Pricing_Component__c>([
                SELECT Id, End_Date__c
                FROM Pricing_Component__c
                WHERE Id IN:pcIds
        ]);
        for (Contract__c oldContract : dummyContracts) {
            System.assertEquals(oldContract.End_Date__c.addYears(1), newContractMap.get(oldContract.Id).End_Date__c, 'Contract was not successfully extended');
        }
        for (Pricing_Component__c oldPC : dummyPricingComponents) {
            System.assertEquals(oldPC.End_Date__c.addYears(1), newPCMap.get(oldPC.Id).End_Date__c, 'Pricing Component was not successfully extended');
        }
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        TriggerHandlerExtension.disableObject(Offer__c.SObjectType);
        TriggerHandlerExtension.disableObject(Opportunity.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract_Role__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(Pricing_Component__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Account.SObjectType);
        TriggerHandlerExtension.enableObject(Offer__c.SObjectType);
        TriggerHandlerExtension.enableObject(Opportunity.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract_Role__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.enableObject(Pricing_Component__c.SObjectType);
    }
}