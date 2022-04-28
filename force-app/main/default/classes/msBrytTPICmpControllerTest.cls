/****************************************************************************************************
 * Class msBrytTPICmpControllerTest
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 09.04.2019
 *   Description :  Test class for the msBrytTPICmpController
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	09.04.2019	Init version.
 *****************************************************************************************************/
@IsTest
public without sharing class msBrytTPICmpControllerTest {
    @TestSetup
    public static void testSetup() {
        msBrytTestDataFactory.createTestRecords();
        List<Contract__c> allContracts = [SELECT Id, Start_Date__c, End_Date__c FROM Contract__c];
        List<Contract_Role__c> allContractRoles = [SELECT Id, Start_Date__c, End_Date__c, Bryt_isUserAdmin__c FROM Contract_Role__c];
        for (Contract__c contractItem : allContracts) {
            contractItem.Start_Date__c = Date.today();
            contractItem.End_Date__c = Date.today();
        }
        update allContracts;
        for (Contract_Role__c roleItem : allContractRoles) {
            roleItem.Start_Date__c = Date.today();
            roleItem.End_Date__c = Date.today();
            roleItem.Bryt_isUserAdmin__c = true;
        }
        update allContractRoles;
    }
    @IsTest
    public static void getContactsTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.getContacts();
            Test.stopTest();
        }
    }
    @IsTest
    public static void getUsersTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.getUsers();
            Test.stopTest();
        }
    }
    @IsTest
    public static void getUserLoginsTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.getUserLogins();
            Test.stopTest();
        }
    }
    @IsTest
    public static void getContractRolesTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.getContractRoles();
            Test.stopTest();
        }
    }
    @IsTest
    public static void getChangelogsTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.getChangelogs();
            Test.stopTest();
        }
    }
    @IsTest
    public static void insertContractRoleTest() {
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Contact testContact = msBrytTPICmpController.getContacts()[0];
            Contract__c testContract = msBrytUtility.getUserDetails().tpiContracts[0];
            Test.startTest();
            msBrytTPICmpController.insertContractRole(testContact, testContract, String.valueOf(Date.today()), String.valueOf(Date.today()));
            Test.stopTest();
        }
    }
    @IsTest
    public static void deleteContractRoleTest() {
        User testUser = [SELECT Id, Contact.AccountId, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Contract_Role__c toDelete = msBrytTPICmpController.getContractRoles()[0];
            Test.startTest();
            msBrytTPICmpController.deleteContractRole(toDelete);
            Test.stopTest();
        }
    }
    @IsTest
    public static void updateUserDetailsTest() {
        User testUser = [SELECT Id, Name, Email, Username FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        User subjectUser = [SELECT Id, Name, Email, Username FROM User WHERE Username = 'testuser2@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.updateUserDetails(subjectUser);
            Test.stopTest();

        }
    }
    @IsTest
    public static void insertCommunityContactTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Contact testContact = new Contact();
            testContact.LastName = 'mindsquaretestusercereatedinunit';
            testContact.Email = 'fake@email.testcreation';
            Test.startTest();
            msBrytTPICmpController.insertCommunityContact(testContact);
            Test.stopTest();
        }
    }
    @IsTest
    public static void getNewContactTest() {
        Test.startTest();
        msBrytTPICmpController.getNewContact();
        Test.stopTest();
    }
    @IsTest
    public static void freezeCommunityUserTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        User subjectUser = [SELECT Id, Name FROM User WHERE Username = 'testuser2@statkraft.mindsquare.user.dev' LIMIT 1];
        UserLogin subjectUserLogin = [SELECT Id, UserId FROM UserLogin WHERE UserId = :subjectUser.Id LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.freezeCommunityUser(subjectUserLogin);
            Test.stopTest();
        }
    }
    @IsTest
    public static void unfreezeCommunityUserTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        User subjectUser = [SELECT Id, Name FROM User WHERE Username = 'testuser2@statkraft.mindsquare.user.dev' LIMIT 1];
        UserLogin subjectUserLogin = [SELECT Id, UserId FROM UserLogin WHERE UserId = :subjectUser.Id LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.unfreezeCommunityUser(subjectUserLogin);
            Test.stopTest();
        }
    }
    @IsTest
    public static void resetCommunityUserPasswordTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        User subjectUser = [SELECT Id, Name FROM User WHERE Username = 'testuser2@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            msBrytTPICmpController.resetCommunityUserPassword(subjectUser);
            Test.stopTest();
        }
    }
    @IsTest
    public static void createUserEditChangelogTest() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];

        System.runAs(testUser) {
            msBrytUtility.UserDetails userDetails=msBrytUtility.getUserDetails();
            Test.startTest();
            msBrytTPICmpController.createUserEditChangelog(userDetails.portalUserWrappers[0].user);
            Test.stopTest();
        }
    }
}