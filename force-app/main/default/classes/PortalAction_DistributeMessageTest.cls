@isTest
public with sharing class PortalAction_DistributeMessageTest {
    @testSetup static void setup(){
        msTestDataFactory.createTestPortalContext();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        msUserNotificationSetting__c setting = new msUserNotificationSetting__c(msContact__c = con.Id, msNotificationType__c = 'monthly_production_data', msIsEmail__c = true);
        insert setting;
    }
    @isTest static void testEnqueue(){
        msUtility.throwFakeException = false;

        //Email Invocations are sent within a Batch Job for monthly production data, making them not-assertable even when synchronously calling the execute method.
        Test.startTest();
        System.enqueueJob(new PortalAction_MessageMonthlyProduction());
        Test.stopTest();
    }

    @isTest static void testCatchException(){
        Exception caughtException;

        Test.startTest();
        try{
            new PortalAction_MessageMonthlyProduction().execute((QueueableContext) null);
        }catch(Exception ex){
            caughtException = ex;
        }
        Test.stopTest();

        System.assert(caughtException != null, 'No exception was thrown');
        System.assert(![SELECT Id FROM Log__c].isEmpty(), 'No Log was created');
    }
}