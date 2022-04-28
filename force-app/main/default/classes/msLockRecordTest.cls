/**
 * Created by frank on 26.07.2018.
 */
@IsTest
public with sharing class msLockRecordTest {

    static testMethod void testLock() {
        msTestDataFactory.createTestPortalContext();
        String idString = '';
        List<List<String>> listList = new List<List<String>>();
        List<String> stringList = new List<String>();
        List<Id> idList = new List<Id>();
        List<Contract__c> contractList = new List<Contract__c>([SELECT Id FROM Contract__c]);
        List<Entity__c> entityList = new List<Entity__c>([SELECT Id FROM Entity__c]);

        for (Contract__c con : contractList){
            idList.add(con.Id);
        }
        for (Entity__c ent : entityList){
            idList.add(ent.Id);
        }
        system.debug(idList);
        System.Test.startTest();
        for ( Id recordId : idList){
            idString = (String) recordId;
            stringList.add(idString);
            listList.add(stringList);
            msLockRecord.lock(listList);
            stringList.clear();
            listList.clear();
        }
        System.Test.stopTest();
        for(Id recordId : idList){
            System.assertEquals(Approval.isLocked(recordId), True, 'Not all records was locked');
        }
    }
}