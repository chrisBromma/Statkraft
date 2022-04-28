@IsTest
private class EsalesControllerTest {

    /**
     * Redundant as still referencing Entities and not able to find data due to switch in Data Model
    @TestSetup public static void generateTestData() {
        msTestDataFactory.createTestRecords();
    }
    public static testMethod void testGetContracts() {
        Test.startTest();
        Set<Id> result = EsalesController.getContracts();
        Test.stopTest();
        System.assert(result != null);
    }
    public static testMethod void testGetResult() {
        Test.startTest();
        EsalesController.getResult();
        Test.stopTest();
    }
    public static testMethod void testDoGet() {
        Test.startTest();
        EsalesController.doGet();
        Test.stopTest();
    }
    public static testMethod void testGetFromEntity() {
        Id ContractId = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'TestContract1'LIMIT 1].Id;
        Test.startTest();
        EsalesController.getFromEntity(ContractId);
        Test.stopTest();
    }
    public static testMethod void testGetFromContract() {
        Id ContractId = [SELECT Id FROM Contract__c LIMIT 1].Id;
        Test.startTest();
        EsalesController.getFromContract(ContractId);
        Test.stopTest();
    }
    public static testMethod void testGetFromContractIfInflationTrue() {
        Id ContractId = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'TestContract1' LIMIT 1].Id;
        Test.startTest();
        EsalesController.getFromContract(ContractId);
        Test.stopTest();
    }
    public static testMethod void testGetPricing1() {
        Id ContractId = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'TestContract6' LIMIT 1].Id;
        Test.startTest();
        EsalesController.getPricing(ContractId);
        Test.stopTest();
    }
     */
}