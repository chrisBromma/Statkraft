/**
 * Created by georgluch on 29.11.21.
 */

@IsTest
public with sharing class msBrytAdminSettingsTest {

    @TestSetup
    private static void setupData() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    private static void getRecordsAboutDisabledTrades_Test() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Bryt_Portal_Bulletin_TradeDeactivation__c bulletin = new Bryt_Portal_Bulletin_TradeDeactivation__c();
            bulletin.Publication_Date__c = Datetime.now().addDays(1);
            bulletin.End_Date__c = Date.today().addDays(2);
            bulletin.is_Active__c = true;
            bulletin.Text__c = 'Test';

            insert bulletin;

            Test.startTest();
            List<Bryt_Portal_Bulletin_TradeDeactivation__c> bulletins = msBrytAdminSettings.getRecordsAboutDisabledTrades();
            Test.stopTest();

            System.assertNotEquals(0, bulletins.size(), 'List of Portal Bulletins for trade deactivation should be retrieved');
        }
    }

    @IsTest
    private static void getColorPicklistValues() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();
            String values = msBrytAdminSettings.getColorPicklistValues();
            Test.stopTest();

            System.assertNotEquals(null, values, 'values should be retrieved');
        }
    }

    @IsTest
    private static void testRemoveMessage() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Bryt_Portal_Bulletin_TradeDeactivation__c bulletin = new Bryt_Portal_Bulletin_TradeDeactivation__c();
            bulletin.Publication_Date__c = Datetime.now().addDays(1);
            bulletin.End_Date__c = Date.today().addDays(2);
            bulletin.is_Active__c = true;
            bulletin.Text__c = 'Test';

            insert bulletin;
            Test.startTest();
            msBrytAdminSettings.removeMessage(bulletin.Id);
            Integer count = [SELECT COUNT() FROM Bryt_Portal_Bulletin_TradeDeactivation__c WHERE Id = :bulletin.Id];
            System.assertEquals(0, count);
            Test.stopTest();
        }
    }
}