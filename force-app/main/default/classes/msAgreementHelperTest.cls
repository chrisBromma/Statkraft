/**
 * Created by Fabian on 18.01.2021.
 */
@IsTest
public with sharing class msAgreementHelperTest {
    public static final Date THIS_DAY = Date.today();
    public static final String CONTRACT_ROLE_CONTACT_RECORD_TYPE =
            Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Contract_Role_Contact').getRecordTypeId();
    public static final String PC_FIXED_RECORD_TYPE =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Fixed_Energy_Price').getRecordTypeId();
    public static final String PC_FLOATING_RECORD_TYPE =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Floating_Energy_Price').getRecordTypeId();
    @IsTest
    public static void testGenerateAgreementConnections(){

        List<Contract__c> testContracts = createTestData();

        Contact contact = new Contact(
                AccountId = testContracts[0].Contract_Holder__c,
                LastName = 'TestContact'
        );
        insert contact;

        List<Contract_Role__c>contractRoles = new List<Contract_Role__c>();
        Contract_Role__c contractRole = new Contract_Role__c(
                Start_Date__c = Date.newInstance(THIS_DAY.year()-1, 1, 1),
                Contact__c = contact.Id,
                Contract__c = testContracts[0].Id,
                Role__c = 'Contractual contact',
                RecordTypeId = CONTRACT_ROLE_CONTACT_RECORD_TYPE
        );
        contractRoles.add(contractRole);

        Contract_Role__c contractRole2 = new Contract_Role__c(
                Start_Date__c = Date.newInstance(THIS_DAY.year()-1, 1, 1),
                Contact__c = contact.Id,
                Contract__c = testContracts[1].Id,
                Role__c = 'Contractual contact',
                RecordTypeId = CONTRACT_ROLE_CONTACT_RECORD_TYPE
        );
        contractRoles.add(contractRole2);

        Contract_Role__c contractRole3 = new Contract_Role__c(
                Start_Date__c = Date.newInstance(THIS_DAY.year()-1, 1, 1),
                Contact__c = contact.Id,
                Contract__c = testContracts[1].Id,
                Role__c = 'Commercial Contact',
                RecordTypeId = CONTRACT_ROLE_CONTACT_RECORD_TYPE
        );
        contractRoles.add(contractRole3);

        Contract_Role__c contractRole4 = new Contract_Role__c(
                Start_Date__c = Date.newInstance(THIS_DAY.year()-1, 1, 1),
                Contact__c = contact.Id,
                Contract__c = testContracts[1].Id,
                Role__c = 'Technical Contact',
                RecordTypeId = CONTRACT_ROLE_CONTACT_RECORD_TYPE
        );
        contractRoles.add(contractRole4);

        insert contractRoles;

        List<Meter__c>meters = new List<Meter__c>();
        Meter__c meter = new Meter__c(
                Name = 'deMeter',
                Status__c = 'Active',
                Country__c = 'Germany',
                Asset_Owner_Account__c = testContracts[0].Contract_Holder__c,
                Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld',
                Current_Contract__c = testContracts[0].id,
                Alternative_Meter_ID__c = 'FRPORTALPLH'
        );
        meters.add(meter);
        Meter__c meter2 = new Meter__c(
                Name = 'deMeter2',
                Status__c = 'Active',
                Country__c = 'Germany',
                Asset_Owner_Account__c = testContracts[1].Contract_Holder__c,
                Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld2',
                Current_Contract__c = testContracts[1].id,
                Alternative_Meter_ID__c = 'FRPORTALPLH2'
        );
        meters.add(meter2);
        insert meters;

        List<MeterRegistration__c>meterRegistrations = new List<MeterRegistration__c>();
        MeterRegistration__c meterRegistration = new MeterRegistration__c(
                Meter__c = meter.Id,
                Contract__c = testContracts[0].Id,
                Valid_from__c = Date.newInstance(THIS_DAY.year()-1, 1, 1)
        );
        meterRegistrations.add(meterRegistration);
        MeterRegistration__c meterRegistration2 = new MeterRegistration__c(
                Meter__c = meter.Id,
                Contract__c = testContracts[1].Id,
                Valid_from__c = Date.newInstance(THIS_DAY.year()-1, 1, 1)
        );
        meterRegistrations.add(meterRegistration2);
        insert meterRegistrations;

        Generation_Unit__c generationUnit = new Generation_Unit__c(
                Name = 'DE Generation Unit',
                Annual_Production__c = 320,
                Portfolio_ID__c = 'DE_test',
                Country__c = 'Germany',
                Installed_Capacity__c=1000
        );
        insert generationUnit;

        List<Meter2GenerationUnitRelationship__c> m2GUnitRelationships = new List<Meter2GenerationUnitRelationship__c>();
        Meter2GenerationUnitRelationship__c m2GUnitRelationship = new Meter2GenerationUnitRelationship__c(
                Meter__c = meter.id,
                Generator_Unit__c = generationUnit.Id,
                Valid_from__c = Date.newInstance(THIS_DAY.year()-1, 1, 1)
        );
        m2GUnitRelationships.add(m2GUnitRelationship);
        Meter2GenerationUnitRelationship__c m2GUnitRelationship2 = new Meter2GenerationUnitRelationship__c(
                Meter__c = meter2.id,
                Generator_Unit__c = generationUnit.Id,
                Valid_from__c = Date.newInstance(THIS_DAY.year()-1, 1, 1)
        );
        m2GUnitRelationships.add(m2GUnitRelationship2);
        insert m2GUnitRelationships;

        Generation_Unit_Ownership__c generationUnitOwnership = new Generation_Unit_Ownership__c(
                Generation_Unit__c = generationUnit.Id,
                Asset_Owner__c = testContracts[0].Contract_Holder__c,
                Start_Date__c = Date.newInstance(THIS_DAY.year()-1, 1, 1)
        );
        insert generationUnitOwnership;

        List<Apttus__APTS_Agreement__c>agreements = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(
                Contract__c = testContracts[0].Id
        );
        agreements.add(agreement);
        Apttus__APTS_Agreement__c agreement2 = new Apttus__APTS_Agreement__c(
                Contract__c = testContracts[1].Id
        );
        agreements.add(agreement2);
        insert agreements;

        List<Agreement2Details__c>createdAgreement2Details = [SELECT Id, Meter__c FROM Agreement2Details__c];
        System.debug(createdAgreement2Details);

        List<Agreement_To_Details_GU__c>createdAgreement_to_Details_GU = [SELECT Id, Agreement2Details__c FROM Agreement_To_Details_GU__c];
        System.debug(createdAgreement_to_Details_GU);

        System.assertEquals(4, createdAgreement2Details.size());
        System.assertEquals(2, createdAgreement_to_Details_GU.size());

    }

    @IsTest
    public static void testPopulateAgreement() {
        List<Contract__c> testContracts = createTestData();

        Contract__c contractOld = [
                SELECT Id
                FROM Contract__c WHERE Id = :testContracts[0].Id];

        contractOld.Termination_Status__c = 'Automatic yearly extension';
        update contractOld;

        Contract__c contract = [
                SELECT Id, Status__c, Contract_Type_New__c, Product_Type_New__c, Contract_Holder__c, Contract_Date__c,
                        Start_Date__c, End_Date__c, Termination_Status__c, Third_Party_Contract__c, REMIT_Reporting_Relevant__c,
                        REMIT_delegated_reporting__c, Bank_Account_Owner__c, Bank_Name__c, IBAN__c, BIC_Code__c
                FROM Contract__c WHERE Id = :testContracts[0].Id];


        Pricing_Component__c pc = [
                SELECT RecordType.Name, Index_Price__c, Value__c, Risk_Premium__c
                FROM Pricing_Component__c WHERE Contract__c = :contract.Id AND Active__c = TRUE LIMIT 1];
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(
                Contract__c = contract.Id
        );
        insert agreement;

        Apttus__APTS_Agreement__c updatedAgreement = [
                SELECT Apttus__Subtype__c, Apttus__Account__c, APTS_Delivery_Start_Date__c, Apttus__Contract_End_Date__c,
                        Apttus__Auto_Renewal__c, Apttus__Auto_Renew_Term_Months__c, APTS_Price_Type__c, APTS_Index_Price__c,
                        APTS_Fixed_Price__c, APTS_Third_Party_Contract__c, APTS_REMIT_Reporting_Relevant__c,
                        APTS_REMIT_Delegated_Reporting__c, APTS_Bank_Account_Owner__c, APTS_Bank_Name__c,
                        APTS_IBAN__c, APTS_BIC__c
                FROM Apttus__APTS_Agreement__c WHERE Id = :agreement.Id];

        System.assert(updatedAgreement.Apttus__Subtype__c == 'Upstream - Ü20');
        System.assert(updatedAgreement.Apttus__Account__c == contract.Contract_Holder__c);
        System.assert(updatedAgreement.APTS_Delivery_Start_Date__c == contract.Start_Date__c);
        System.assert(updatedAgreement.Apttus__Contract_End_Date__c == contract.End_Date__c);
        System.assert(updatedAgreement.Apttus__Auto_Renewal__c == true);
        System.assert(updatedAgreement.Apttus__Auto_Renew_Term_Months__c == 12);
        System.assert(updatedAgreement.APTS_Price_Type__c == 'Index');
        System.assert(updatedAgreement.APTS_Index_Price__c == pc.Index_Price__c);
        System.assert(updatedAgreement.APTS_Third_Party_Contract__c == contract.Third_Party_Contract__c);
        System.assert(updatedAgreement.APTS_REMIT_Reporting_Relevant__c == contract.REMIT_Reporting_Relevant__c);
        System.assert(updatedAgreement.APTS_REMIT_Delegated_Reporting__c == contract.REMIT_delegated_reporting__c);
        System.assert(updatedAgreement.APTS_Bank_Account_Owner__c == contract.Bank_Account_Owner__c);
        System.assert(updatedAgreement.APTS_Bank_Name__c == contract.Bank_Name__c);
        System.assert(updatedAgreement.APTS_IBAN__c == contract.IBAN__c);
        System.assert(updatedAgreement.APTS_BIC__c == contract.BIC_Code__c);




    }

    @IsTest
    public static void testUpdateContract() {
        List<Contract__c> testContracts = createTestData();

        Contract__c contract = [
                SELECT Id, Status__c, Contract_Type_New__c, Product_Type_New__c, Contract_Holder__c, Contract_Date__c,
                        Start_Date__c, End_Date__c, Termination_Status__c, Third_Party_Contract__c, REMIT_Reporting_Relevant__c,
                        REMIT_delegated_reporting__c, Bank_Account_Owner__c, Bank_Name__c, IBAN__c, BIC_Code__c
                FROM Contract__c WHERE Id = :testContracts[0].Id];
        Pricing_Component__c pc = [
                SELECT RecordType.Name, Index_Price__c, Value__c, Risk_Premium__c
                FROM Pricing_Component__c WHERE Contract__c = :contract.Id];

        List<Apttus__APTS_Agreement__c>agreements = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(
                Contract__c = testContracts[0].Id
        );
        agreements.add(agreement);
        Apttus__APTS_Agreement__c agreement2 = new Apttus__APTS_Agreement__c(
                Contract__c = testContracts[0].Id
        );
        agreements.add(agreement2);
        insert agreements;


        contract.Status__c = 'Draft';
        update contract;


        Account newAccount = new Account(Name='NewAgreementAccount');
        insert newAccount;

        agreement.Apttus__Status_Category__c = 'In Effect';
        agreement.Apttus__Status__c = 'Activated';
        agreement.Apttus__Account__c = newAccount.Id;
        agreement.APTS_Delivery_Start_Date__c = Date.newInstance(THIS_DAY.year(), 1, 1);
        agreement.Apttus__Contract_End_Date__c = Date.newInstance(THIS_DAY.year()+1, 11, 30);
        agreement.Apttus__Auto_Renewal__c = true;
        agreement.APTS_Fixed_Price__c = 1.0;
        agreement.APTS_Risk_Premium__c = 2.0;
        update agreement;

        agreement2.Apttus__Status_Category__c = 'In Effect';
        agreement2.Apttus__Status__c = 'Activated';
        agreement2.Apttus__Account__c = newAccount.Id;
        agreement2.APTS_Delivery_Start_Date__c = Date.newInstance(THIS_DAY.year(), 1, 1);
        agreement2.Apttus__Contract_End_Date__c = Date.newInstance(THIS_DAY.year()+1, 11, 30);
        agreement2.Apttus__Auto_Renewal__c = true;
        agreement2.APTS_Fixed_Price__c = 1.0;
        agreement2.APTS_Risk_Premium__c = 2.0;
        agreement2.Contract__c = testContracts[1].Id;
        update agreement2;


        Contract__c updatedContract = [SELECT Status__c, Contract_Holder__c, Start_Date__c,End_Date__c,Termination_Status__c FROM Contract__c WHERE Id = :contract.Id];
        Pricing_Component__c updatedPC = [SELECT Value__c FROM Pricing_Component__c WHERE Id = :pc.Id];

        System.debug(agreement.Apttus__Contract_Start_Date__c);

        System.assert(updatedContract.Status__c == 'Active');
        System.assert(updatedContract.Contract_Holder__c == agreement.Apttus__Account__c);
        System.assert(updatedContract.Start_Date__c == Date.newInstance(THIS_DAY.year(), 1, 1));
        System.assert(updatedContract.End_Date__c == Date.newInstance(THIS_DAY.year()+1, 11, 30));
        System.assert(updatedContract.Termination_Status__c == 'Automatic yearly extension');
        System.assert(updatedPC.Value__c == 2.0);


    }

    public static List<Contract__c> createTestData() {


        APTS_integration_Allowed__c integrationallowed = new APTS_integration_Allowed__c(APTS_Allow_Callout__c=true, Name = 'Integration_Allowed');
        insert integrationallowed;

        Account acc = new Account(
                Name='testAcc'
        );
        insert acc;

        RecordType recordTypeContract = [SELECT Id, Name, DeveloperName FROM RecordType WHERE DeveloperName = 'Contract_PPA'];

        List<Contract__c> contracts = new List<Contract__c>();
        Contract__c contract = new Contract__c(
                RecordTypeId = recordTypeContract.Id,
                Contract_Type_New__c = 'Merchant PPA',
                Product_Type_New__c = 'Fixed Price w/GOO',
                Third_Party_Contract__c = true,
                REMIT_Reporting_Relevant__c = true,
                REMIT_delegated_reporting__c = false,
                Bank_Account_Owner__c = 'Test Bank Account Owner',
                Bank_Name__c = 'Test Bank',
                IBAN__c = 'DE12 3456 7890 1234 56',
                BIC_Code__c = '1234567',
                Start_Date__c = Date.newInstance(THIS_DAY.year()-1, 1, 1),
                End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                Contract_Holder__c = acc.Id,
                Status__c = 'Active',
                Country__c = 'Germany',
                Approved__c = true,
                //Meter_Billing_Type__c = 'Sub-Meter Yearly',
                Name = 'TestContract',
                Settlement_SubModel__c = null,
                Termination_Status__c = 'Limited Contract'
        );
        contracts.add(contract);

        Contract__c contract2 = new Contract__c(
                RecordTypeId = recordTypeContract.Id,
                Contract_Type_New__c = 'Merchant PPA',
                Product_Type_New__c = 'Fixed Price w/GOO',
                Third_Party_Contract__c = false,
                REMIT_Reporting_Relevant__c = true,
                REMIT_delegated_reporting__c = false,
                Bank_Account_Owner__c = 'Test Bank Account Owner',
                Bank_Name__c = 'Test Bank',
                IBAN__c = 'DE12 3456 7890 1234 56',
                BIC_Code__c = '1234567',
                Start_Date__c = Date.newInstance(THIS_DAY.year()-1, 1, 1),
                End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                Contract_Holder__c = acc.Id,
                Status__c = 'Active',
                Country__c = 'Germany',
                Approved__c = true,
                //Meter_Billing_Type__c = 'Sub-Meter Yearly',
                Name = 'TestContract',
                Settlement_SubModel__c = null,
                Termination_Status__c = 'Limited Contract'
        );
        contracts.add(contract2);

        insert contracts;

        RecordType recordType = [SELECT Name, DeveloperName FROM RecordType WHERE Name = 'Floating Energy Price'];

        List<Pricing_Component__c>pricingComponents = new List<Pricing_Component__c>();
        Pricing_Component__c pricingComponent = new Pricing_Component__c(
                RecordTypeId = PC_FLOATING_RECORD_TYPE,
                Index_Price__c = 'CfD Index',
                Value__c = 70.2,
                Risk_Premium__c = 123,
                Contract__c = contract.Id,
                Start_Date__c = Date.newInstance(THIS_DAY.year(), 1, 1),
                End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31)
        );
        pricingComponents.add(pricingComponent);
        Pricing_Component__c pricingComponent2 = new Pricing_Component__c(
                RecordTypeId = PC_FIXED_RECORD_TYPE,
                Index_Price__c = 'Fixed Price',
                Value__c = 70.2,
                Risk_Premium__c = 123,
                Contract__c = contract2.Id,
                Start_Date__c = Date.newInstance(THIS_DAY.year(), 1, 1),
                End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31)
        );
        pricingComponents.add(pricingComponent2);

        insert pricingComponents;
        return contracts;
    }

}