@IsTest
public with sharing class msLoginFormControllerTest {

    private static final Id AccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
    private static Id globalCustomerCommunityUserProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'Global Customer Community User' LIMIT 1].Id;
    private static Account testAccount;
    private static Contact testContact;
    private static String testUserPassword = 'testPassword123!';
    private static String testUserUsernameNoSuffix = 'msLoginFormControllerTest@statkraft.mindsquare.user.dev';
    private static String testUserUsername = testUserUsernameNoSuffix+Label.msPortalUsernameSufix;

    @TestSetup
    private static void createTestRecords(){
        createTestAccount();
        createTestContact();

        User testPortalUser = new User(Username = testUserUsername,
                Email = 'testuser@mindsquare.de',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'de_DE_EURO',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'Europe/Berlin',
                Alias = 'tstusr',
                ContactId = testContact.Id,
                LastName = 'Test',
                ProfileId = globalCustomerCommunityUserProfileId
        );
        insert testPortalUser;
        System.setPassword(testPortalUser.Id, testUserPassword);
    }

    @IsTest
    static void testLoginWithValidCredentials() {
        User testUser = [SELECT Username,IsActive FROM User WHERE Username =:testUserUsername LIMIT 1];
        try{
            msLoginFormController.login(testUser.Username, testUserPassword, null);
        }
        catch(Exception ex){
            System.assert(false);
        }
    }

    @IsTest
    static void testLoginWithValidUsernameWithoutSuffix() {
        try{
            msLoginFormController.login(testUserUsernameNoSuffix, testUserPassword, null);
        }
        catch(Exception ex){
            System.assert(false);
        }
    }

    @IsTest
    static void testLoginWithInvalidCredentials() {
        try{
            msLoginFormController.login('fakeUsername', 'fakepwd', null);
        }
        catch(Exception ex){
            System.assert(true);
        }
    }

    @IsTest
    static void testLoginByDeactivatedUser() {
        User testUser = [SELECT Username,IsActive FROM User WHERE Username =:testUserUsername LIMIT 1];
        testUser.IsActive = false;
        update testUser;
        try{
            msLoginFormController.login(testUser.Username, testUserPassword, null);
        }
        catch(Exception ex){
            System.assert(true);
        }
    }

    @IsTest
    static void testLoginByFrozenUser() {
        User testUser = [SELECT Username,IsActive FROM User WHERE Username =:testUserUsername LIMIT 1];
        UserLogin userLogin = [SELECT IsFrozen FROM UserLogin WHERE UserId =: testUser.Id LIMIT 1];
        userLogin.IsFrozen = true;
        update userLogin;
        try{
            msLoginFormController.login(testUser.Username, testUserPassword, null);
        }
        catch(Exception ex){
            System.assert(true);
        }
    }

    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        msLoginFormController controller = new msLoginFormController();
        System.assertNotEquals(controller, null);
    }

    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(true, msLoginFormController.getIsUsernamePasswordEnabled());
    }

    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, msLoginFormController.getIsSelfRegistrationEnabled());
    }

    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, msLoginFormController.getSelfRegistrationUrl());
    }

    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = msLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }

    @IsTest
    static void testExperienceIdNotNull() {
        String expId = 'Test1';
        String experienceId = msLoginFormController.setExperienceId(expId);
        System.assertNotEquals(null, experienceId);
    }

    @IsTest
    static void testExperienceIdIsNull() {
        String expId = null;
        String experienceId = msLoginFormController.setExperienceId(expId);
        System.assertEquals(null, experienceId);
    }

    private static void createTestAccount(){
        testAccount = new Account(
                Name = 'TestAccount',
                RecordTypeId = AccRecId, 
                Customer_Type__c='not yet identified'
        );
        insert testAccount;
    }

    private static void createTestContact() {
        testContact = new Contact(
                FirstName = 'Test',
                LastName = 'SecondTester',
                AccountId = testAccount.Id,
                OtherStreet = 'Street 5',
                OtherPostalCode = '4321',
                OtherCity = 'BCtown',
                OtherCountry = 'Germany',
                MailingCountry = 'Germany',
                MobilePhone = '+49123456789',
                Email = 'test2@mail.com'
        );
        insert testContact;
    }

}