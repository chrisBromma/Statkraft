/****************************************************************************************************
 * Class msBrytMailConf
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 09.04.2019
 *   Description :  Test class for the class msBrytMailConf
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	09.04.2019	Init version.
 *****************************************************************************************************/
@IsTest
public with sharing class msBrytMailConfTest {
    @TestSetup
    public static void testSetup() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    public static void msSendConfirmationMailsTest() {
        Id brytCustomerProfileId = [
                SELECT Id
                FROM Profile
                WHERE Profile.Name = 'Bryt Customer Community User'
                LIMIT 1
        ].Id;
        Contract__c testContract = [
                SELECT Id, Name, BrytNotificationEmails__c
                FROM Contract__c
                WHERE RED_Contract_ID__c = 'TestContract6'
        ];
        Map<Id,Pricing_Component__c> allPCs = new Map<Id,Pricing_Component__c> ([
                SELECT Id
                FROM Pricing_Component__c
        ]);
        Map<Id,User> randomUsers = new Map<Id, User>([
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND ProfileId = : brytCustomerProfileId
                LIMIT 5
        ]);

        List<String> notificationTargetEmails = msBrytUtility.getMetadata().Trade_Notification_Recipients__c.split(';');
        Set<String> vettedNotificationTargets = new Set<String>();
        for (String emailToCheck : notificationTargetEmails) {
            if (msBrytNotificationLogic.checkEmailPattern(emailToCheck)) {
                vettedNotificationTargets.add(emailToCheck);
            } else {
                System.debug('Bryt Portal Setting has an failing Email address: ' + emailToCheck);
            }
        }

        List<msBrytNotificationLogic.notificationWrapper> testWrappers = new List<msBrytNotificationLogic.notificationWrapper>();
        msBrytNotificationLogic.notificationWrapper wrapper = new msBrytNotificationLogic.notificationWrapper();
        wrapper.pcIds = allPCs.keySet();
        wrapper.contract = testContract;
        wrapper.targetUserIds = randomUsers.keySet();
        wrapper.targetEmailsList = vettedNotificationTargets;

        testWrappers.add(wrapper);

        msBrytNotificationLogic.notificationWrapper wrapperDebugWithTarget = new msBrytNotificationLogic.notificationWrapper();
        wrapperDebugWithTarget.pcIds = allPCs.keySet();
        wrapperDebugWithTarget.contract = testContract;
        wrapperDebugWithTarget.targetUserIds = randomUsers.keySet();
        wrapperDebugWithTarget.debugTarget = UserInfo.getUserId();
        wrapperDebugWithTarget.isDebug = true;
        wrapperDebugWithTarget.targetEmailsList = vettedNotificationTargets;

        testWrappers.add(wrapperDebugWithTarget);

        msBrytNotificationLogic.notificationWrapper wrapperDebugWithoutTarget = new msBrytNotificationLogic.notificationWrapper();
        wrapperDebugWithoutTarget.pcIds = allPCs.keySet();
        wrapperDebugWithoutTarget.contract = testContract;
        wrapperDebugWithoutTarget.targetUserIds = randomUsers.keySet();
        wrapperDebugWithoutTarget.debugTarget = UserInfo.getUserId();
        wrapperDebugWithoutTarget.isDebug = true;
        wrapperDebugWithoutTarget.targetEmailsList = vettedNotificationTargets;

        testWrappers.add(wrapperDebugWithoutTarget);

        msBrytMailConf.msSendConfirmationMails(testWrappers);
    }

    @IsTest
    public static void msSendDeactNotifTest() {
        Pricing_Component__c randomPC = [SELECT Id FROM Pricing_Component__c WHERE Contract__r.RED_Contract_ID__c = 'TestContract6' LIMIT 1];
        msBrytMailConf.msSendDeactNotif(randomPC.Id);
    }
}