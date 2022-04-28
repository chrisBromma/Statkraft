@isTest
public with sharing class PortalAction_ReminderSubmeterTest {
    @testSetup static void setup(){
        msTestDataFactory.createTestPortalContext();
    }
    @isTest static void testEnqueueMonthlySubmeter(){
        msUtility.throwFakeException = false;

        Test.startTest();
        System.enqueueJob(new PortalAction_MonthlySubmeterReminder());
        Test.stopTest();
    }

    @isTest static void testEnqueueAnnualSubmeter(){
        msUtility.throwFakeException = false;

        Test.startTest();
        System.enqueueJob(new PortalAction_AnnualSubmeterReminder());
        Test.stopTest();
    }

    @isTest static void testThrowException(){

        Exception caughtException;

        Test.startTest();
        try{
            new PortalAction_AnnualSubmeterReminder().execute((QueueableContext) null);
        }catch(Exception e){
            caughtException = e;
        }
        Test.stopTest();

        System.assert(caughtException != null, 'No exception was thrown');
        System.assert(![SELECT Id FROM Log__c].isEmpty(), 'No Log was created');
    }
}