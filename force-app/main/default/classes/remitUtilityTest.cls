/****************************************************************************************************
 * Class remitUtilityTest
 *
 *   Create By	:   ChristianGottlieb (mindsquare AG)
 *   Create Date	:   2022-01-20
 *   Description	:	This test is basic, for full test also run all tests for Handlers from Account to Meter
 *                      both synchronous and asynchronous
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	            Date             	Description
 *   * -----------------------------------------------------------------------------------------------                 
 *   * ChristianGottlieb (mindsquare AG)	            2022-01-20       	Init version.
*****************************************************************************************************/

@IsTest
private class remitUtilityTest {
    @IsTest
    private static void testREMITThirdPartyContractToTrue() {
        disableTriggers();

        Account contractHolder = createAccount('myAcc', 'Germany');
        insert contractHolder;
        Contract__c contractUnder10 = createContract(
                'TestCon',
                'Germany',
                contractHolder.Id,
                9,
                9,
                false,
                'Active'
        );
        insert contractUnder10;
        Meter__c meter = createMeter('myMet', 'Under Construction', 'Germany');
        insert meter;
        MeterRegistration__c meterRegistration = createMeterReg(
                'MyMeterReg',
                contractUnder10.Id,
                meter.Id,
                'Germany',
                true
        );
        insert meterRegistration;

        Test.startTest();
        Set<Id> contractIds = new Set<Id>();
        contractIds.add(contractUnder10.Id);
        remitUtility.determineRemitRelevancyAndUpdateContracts(contractIds);
        Test.stopTest();
        Contract__c contractUpdated = [
                SELECT REMIT_Reporting_Relevant__c
                FROM Contract__c
                WHERE Id = :contractUnder10.Id
        ];
        System.assert(!contractUpdated.REMIT_Reporting_Relevant__c);
    }

    private static Contract__c createContract(
            String name,
            String country,
            Id contractHolder,
            Integer activeCapacity,
            Integer legalCapacity,
            Boolean thirdParty,
            String status
    ) {
        Contract__c newContract = new Contract__c(
                Start_Date__c = Date.today().addYears(-2),
                End_Date__c = Date.today().addYears(2),
                Status__c = status,
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Contracted_Capacity__c = activeCapacity,
                Active_Installed_Capacity__c = activeCapacity,
                Legal_Capacity__c = legalCapacity,
                Contracted_Annual_Production__c = 0,
                Name = name,
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = country,
                Third_Party_Contract__c = thirdParty
        );

        return newContract;
    }

    private static Account createAccount(String name, String country) {
        Account newAccount = new Account(
                Name = name,
                BillingCountry = country,
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        return newAccount;
    }
    private static Meter__c createMeter(String name, String Status, String country) {
        Meter__c newMeter = new Meter__c(
                Name = name,
                Status__c = Status,
                Alternative_Meter_ID__c = '12345678901',
                Country__c = country
        );
        return newMeter;
    }

    private static MeterRegistration__c createMeterReg(
            String name,
            Id contract,
            Id meter,
            String country,
            Boolean active
    ) {
        MeterRegistration__c newMeterReg = new MeterRegistration__c(
                Name = name,
                Contract__c = contract,
                Meter__c = meter,
                Country__c = country,
                Active__c = active,
                Volume_Share__c = 100,
                Valid_from__c = Date.today().addYears(-2),
                Valid_to__c = Date.today().addYears(2)
        );
        return newMeterReg;
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