@isTest
public with sharing class PortalAction_SwitchCurtailmentsTest {
    @isTest static void checkCurtailmentsUnlocked(){
        msUtility.throwFakeException = false;
        Test.startTest();
        System.enqueueJob(new PortalAction_CurtailmentsUnlock());
        Test.stopTest();

        PortalSettings__c testCurtailmentSetting = queryCurtailmentSetting();
        System.assert(testCurtailmentSetting.Checkbox__c, 'Curtailments - Allow Update should be enabled');
    }

    @isTest static void checkCurtailmentsLocked(){
        msUtility.throwFakeException = false;
        Test.startTest();
        System.enqueueJob(new PortalAction_CurtailmentsLock());
        Test.stopTest();
        
        PortalSettings__c testCurtailmentSetting = queryCurtailmentSetting();
        System.assert(!testCurtailmentSetting.Checkbox__c, 'Curtailments - Allow Update should be disabled');
    }

    @isTest static void checkExceptionHandling(){
        Exception caughtException;

        Test.startTest();
        try{
            PortalAction_SwitchCurtailments portalAction = new PortalAction_CurtailmentsUnlock();
            portalAction.execute((QueueableContext) null);
        }catch(Exception e){
            caughtException = e;
        }
        Test.stopTest();

        System.assert(caughtException != null, 'There was no Exception to catch');
        System.assert(![SELECT Id FROM Log__c].isEmpty());        
    
    }

    private static PortalSettings__c queryCurtailmentSetting() {
        List<PortalSettings__c> settings = [
            SELECT Id, Checkbox__c
            FROM PortalSettings__c
            WHERE Name = :msCurtailmentLockHandler.CURTAILMENT_ALLOW_UPDATE
            LIMIT 1
        ];
        if (!settings.isEmpty()) {
            return settings[0];
        }
        return null;
    }

}