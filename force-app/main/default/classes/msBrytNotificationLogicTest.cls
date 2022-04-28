/****************************************************************************************************
 * Class msBrytNotificationLogicTest
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 09.04.2019
 *   Description : Test class for the class msBrytNotificationLogic
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	09.04.2019	Init version.
 *****************************************************************************************************/
@IsTest
public with sharing class msBrytNotificationLogicTest {
    @TestSetup
    public static void testSetup() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    public static void notifyForTradesTest() {
        Pricing_Component__c testPC = [SELECT Id FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];
        List<Id> testList = new List<Id>();
        testList.add(testPC.Id);
        msBrytNotificationLogic.notifyForTrades(testList);
    }

    @IsTest
    public static void emailPatternTest() {
        String notEmail = 'adsfdsafdaf';
        System.assert(!msBrytNotificationLogic.checkEmailPattern(notEmail), 'Pattern should have not been fulfilled');
        String email = 'test@test.com';
        System.assert(msBrytNotificationLogic.checkEmailPattern(email), 'Pattern should have been fulfilled');
    }
}