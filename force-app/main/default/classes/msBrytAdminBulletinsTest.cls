@IsTest
public with sharing class msBrytAdminBulletinsTest {

    @TestSetup
    private static void setupData() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    private static void testGetBulletins() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Bryt_Portal_Bulletin__c bulletin = new Bryt_Portal_Bulletin__c();
            bulletin.Publication_Date__c = Datetime.now().addDays(1);
            bulletin.End_Date__c = Date.today().addDays(2);
            bulletin.isSticky__c = true;
            bulletin.is_Active__c = true;
            bulletin.Text__c = 'Test';

            insert bulletin;

            Test.startTest();
            List<Bryt_Portal_Bulletin__c> bulletins = msBrytAdminBulletins.getBulletins();
            Test.stopTest();

            System.assertNotEquals(0, bulletins.size(), 'List of Portal Bulletins should be retrieved');
        }
    }

    @IsTest
    private static void getColorPicklistValues() {
        User testUser = [SELECT Id,Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        System.runAs(testUser){
            Test.startTest();
            String values = msBrytAdminBulletins.getColorPicklistValues();
            Test.stopTest();

            System.assertNotEquals(null, values, 'values should be retrieved');
        }
    }
}