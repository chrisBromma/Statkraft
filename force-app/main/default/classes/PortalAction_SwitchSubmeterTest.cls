@isTest
public with sharing class PortalAction_SwitchSubmeterTest {
    
    @isTest static void testMonthlyEnable(){
        PortalSettings__c monthlySubmeter = new PortalSettings__c(Name = 'Monthly Submeter - Allow Update', Checkbox__c = false);
        insert monthlySubmeter;
        msUtility.throwFakeException = false;

        Test.startTest();
        PortalAction_SwitchSubmeterEditing portalAction = new PortalAction_MonthlySubmeterEnable();
        portalAction.portalSystemSettings.debug_submeter_enabled__c = false;
        System.enqueueJob(portalAction);
        Test.stopTest();

        System.assert(getPortalSetting('Monthly Submeter - Allow Update').Checkbox__c, 'Monthly Submeter editing was not enabled');
    }

    @isTest static void testMonthlyDisable(){
        PortalSettings__c monthlySubmeter = new PortalSettings__c(Name = 'Monthly Submeter - Allow Update', Checkbox__c = true);
        insert monthlySubmeter;
        msUtility.throwFakeException = false;


        Test.startTest();
        PortalAction_SwitchSubmeterEditing portalAction = new PortalAction_MonthlySubmeterDisable();
        portalAction.portalSystemSettings.debug_submeter_enabled__c = false;
        System.enqueueJob(portalAction);
        Test.stopTest();

        System.assert(!getPortalSetting('Monthly Submeter - Allow Update').Checkbox__c, 'Monthly Submeter editing was not disabled');
    }

    @isTest static void testAnnualEnable(){
        PortalSettings__c annualSubmeter = new PortalSettings__c(Name = 'Annual Submeter - Allow Update', Checkbox__c = false);
        insert annualSubmeter;
        msUtility.throwFakeException = false;

        Test.startTest();
        PortalAction_SwitchSubmeterEditing portalAction = new PortalAction_AnnualSubmeterEnable();
        portalAction.portalSystemSettings.debug_submeter_enabled__c = false;
        System.enqueueJob(portalAction);
        Test.stopTest();

        System.assert(getPortalSetting('Annual Submeter - Allow Update').Checkbox__c, 'Annual Submeter editing was not enabled');
    }

    @isTest static void testAnnualDisable(){
        PortalSettings__c annualSubmeter = new PortalSettings__c(Name = 'Annual Submeter - Allow Update', Checkbox__c = true);
        insert annualSubmeter;
        msUtility.throwFakeException = false;


        Test.startTest();
        PortalAction_SwitchSubmeterEditing portalAction = new PortalAction_AnnualSubmeterDisable();
        portalAction.portalSystemSettings.debug_submeter_enabled__c = false;
        System.enqueueJob(portalAction);
        Test.stopTest();

        System.assert(!getPortalSetting('Annual Submeter - Allow Update').Checkbox__c, 'Annual Submeter editing was not disabled');
    }

    //This Test method runs without Queueable Context in order to simulate how there would be an exception thrown for the Apex Batch Scheduler - It would then create a Log for it.
    @isTest static void testLogIsSavedAfterException(){
        PortalSettings__c annualSubmeter = new PortalSettings__c(Name = 'Annual Submeter - Allow Update', Checkbox__c = true);
        insert annualSubmeter;

        Exception caughtException;
        Test.startTest();
        try{
            PortalAction_SwitchSubmeterEditing portalAction = new PortalAction_MonthlySubmeterEnable();
            portalAction.portalSystemSettings.debug_submeter_enabled__c = false;
            portalAction.execute((QueueableContext) null);
        }catch(Exception e){
            caughtException = e;
        }
        Test.stopTest();

        System.assert(caughtException != null, 'There was no Exception to catch');
        System.assert(![SELECT Id FROM Log__c].isEmpty());

    }



    public static PortalSettings__c getPortalSetting(String name){
        return [SELECT Id, CHeckbox__c FROM PortalSettings__c WHERE Name = :name LIMIT 1];
    }

    

}