@isTest
public with sharing class FlowCreateDummySObjectsTest {
    private static final Id DE_ACC_RECORD_TYPE =
    Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId();

    @isTest static void  testFlowDummyCreation() {
        List <Account> listGrandParents = new List<Account>();
        List <Account> listParents = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            listGrandParents.add(new Account(
                    Name = 'Grand Parent' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
                    ));
        }
        insert listGrandParents;

        for (Integer i = 0; i < 100; i++) {
            listParents.add(new Account(
                    Name = 'Parent' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    ParentId = listGrandParents.get(i).Id,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
                    ));
        }
        insert listParents;  

        FlowCreateDummySObjects.Input input = new FlowCreateDummySObjects.Input();
        input.lookupIdField = 'ParentId';
        input.records = listParents;
        FlowCreateDummySObjects.Output[] flowOutput = FlowCreateDummySObjects.extractSObjects(new List<FlowCreateDummySObjects.Input>{input});
        System.assertEquals(100, flowOutput[0].records.size(), 'Size is not equal to number of Parent Accounts');
    }
}