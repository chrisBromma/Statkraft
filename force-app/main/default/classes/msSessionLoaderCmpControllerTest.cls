/**
 * Created by u34153 on 25.02.2019.
 */
@IsTest
private with sharing class msSessionLoaderCmpControllerTest {
    @IsTest
    private static  void testGetUserDetailsGlobal() {
        msTestDataFactory.createTestPortalContext();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        msUtility.UserDetails details = null;
        System.Test.startTest();
        System.runAs(testUser) {
            details = (msUtility.UserDetails) msSessionLoaderCmpController.getUserDetails('Customer Portal');
        }
        System.Test.stopTest();
        System.assert(details != null , 'There should be test data for this Global Portal Test User');
    }

    @IsTest
    private static  void testGetUserDetailsBryt() {
        msBrytTestDataFactory.createTestRecords();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        msBrytUtility.UserDetails details = null;

        System.Test.startTest();
        System.runAs(testUser) {
            details = (msBrytUtility.UserDetails)  msSessionLoaderCmpController.getUserDetails('Bryt');
        }
        System.Test.stopTest();
        System.assert(details != null , 'There should be test data for this Bryt Portal Test User');
    }

    @IsTest
    private static  void testGetUserDetailsUndefined() {
        msBrytTestDataFactory.createTestRecords();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Object obj = null;
        System.Test.startTest();
        System.runAs(testUser) {
            obj = msSessionLoaderCmpController.getUserDetails('test');
        }
        System.Test.stopTest();
        System.assertEquals(null,obj , 'There should be no test Data for this Portal');
    }
}