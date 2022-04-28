/****************************************************************************************************
* Class msUserHandlerTest
*
*   Create By	:   Lukasz Bak (mindsquare GmbH)
*   Create Date	:   -
*   Description	:	-
*
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Lukasz Bak                                -                   Init version.
*****************************************************************************************************/

@IsTest
private class msUserHandlerTest {
    private static Account testAccount;
    private static final Set<String> SUBSCRIPTIONS_AUTO = new Set<String>{
            'downreg_notification', 'submeter_enabled'
    };

    @TestSetup
    private static void testSetup() {
        createTestAccount();
        createTestContact();
    }

    @IsTest
    private static void regularUserCreationUnaffected() {
        Id AdminProfileId = '00e0Y0000012epc';
        User newUser = new User(
                Username = 'msuserhandlertest@statkraft.mindsquare.user.dev',
                Email = 'testuser@mindsquare.de',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'de_DE_EURO',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'Europe/Berlin',
                Alias = 'testusr',
                LastName = 'User',
                ProfileId = AdminProfileId,
                MobilePhone = '+49123456789');

        Test.startTest();
        insert newUser;
        newUser.MobilePhone = '';
        update newUser;
        Test.stopTest();
        List<User> newUsers = [SELECT Id, Username, Email FROM User WHERE Username = :newUser.Username];
        System.assertEquals(1, newUsers.size(), 'There should be exactly one user');
        System.assertEquals('testuser@mindsquare.de', newUsers[0].Email, 'The User has a wrong Email');
        System.assertEquals('msuserhandlertest@statkraft.mindsquare.user.dev', newUsers[0].Username, 'The User has a wrong Username');
    }

    @IsTest
    private static void testNewGlobalCustomerCommunityUserAfterInsert() {
        Id testContactId = [SELECT Id FROM Contact LIMIT 1].Id;
        Id globalCustomerCommunityUserProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'Global Customer Community User' LIMIT 1].Id;
        User newGCCUser = new User(
                Username = 'msUserHandlerTest@statkraft.mindsquare.user.dev',
                Email = 'testuser@mindsquare.de',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'de_DE_EURO',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'Europe/Berlin',
                Alias = 'testusr',
                ContactId = testContactId,
                LastName = 'User',
                ProfileId = globalCustomerCommunityUserProfileId,
                MobilePhone = '+49123456789');

        Test.startTest();
        insert newGCCUser;
        Test.stopTest();

        newGCCUser = [SELECT Id, UserPreferencesDisableAllFeedsEmail, ContactId FROM User WHERE Username = 'msUserHandlerTest@statkraft.mindsquare.user.dev'];
        NetworkMember nm = [SELECT Id,MemberId,PreferencesDisableAllFeedsEmail FROM NetworkMember WHERE MemberId = :newGCCUser.Id];
        System.assert(newGCCUser.UserPreferencesDisableAllFeedsEmail, 'Global Customer Community User should have All Feeds Email disabled');
        System.assert(nm.PreferencesDisableAllFeedsEmail, 'Network Member record for new inserted Portal User should have All Feeds Emails disabled');
        List<msUserNotificationSetting__c> usersSubscriptions = [SELECT Id, msNotificationType__c, msIsEmail__c FROM msUserNotificationSetting__c WHERE msContact__c = :newGCCUser.ContactId];
        Set<String> generatedSubscriptions = new Set<String>();
        for (msUserNotificationSetting__c subscriptionItem : usersSubscriptions) {
            if (SUBSCRIPTIONS_AUTO.contains(subscriptionItem.msNotificationType__c)) {
                System.assert(subscriptionItem.msIsEmail__c, 'The subscription for ' + subscriptionItem.msNotificationType__c + ' should have been active for Email');
                generatedSubscriptions.add(subscriptionItem.msNotificationType__c);
            }
        }
        System.assert(generatedSubscriptions.containsAll(SUBSCRIPTIONS_AUTO), 'Not all subscriptions have been generated');
        System.assert(SUBSCRIPTIONS_AUTO.containsAll(generatedSubscriptions), 'Too many subscriptions have been generated');

    }
    /*@IsTest
    private static void testNewGlobalCustomerCommunityUserAfterUpdate() {
        Id testContactId = [SELECT Id FROM Contact LIMIT 1].Id;
        Id globalCustomerCommunityUserProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'Global Customer Community User' LIMIT 1].Id;
        User newGCCUser = new User(
                Username = 'msUserHandlerTest@statkraft.mindsquare.user.dev',
                Email = 'testuser@mindsquare.de',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'de_DE_EURO',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'Europe/Berlin',
                Alias = 'testusr',
                ContactId = testContactId,
                LastName = 'User',
                ProfileId = globalCustomerCommunityUserProfileId,
                MobilePhone = '+49123456789');
        insert newGCCUser;
        User runningUser = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];

        newGCCUser = [SELECT Id, UserPreferencesDisableAllFeedsEmail, ContactId FROM User WHERE Id = :newGCCUser.Id];
        NetworkMember nm = [SELECT Id,MemberId,PreferencesDisableAllFeedsEmail FROM NetworkMember WHERE MemberId = :newGCCUser.Id];
        System.assert(newGCCUser.UserPreferencesDisableAllFeedsEmail, 'Global Customer Community User should have All Feeds Email disabled');
        System.assert(nm.PreferencesDisableAllFeedsEmail, 'Network Member record for new inserted Portal User should have All Feeds Emails disabled');
        List<msUserNotificationSetting__c> usersSubscriptions = [
                SELECT Id, msNotificationType__c, msIsEmail__c
                FROM msUserNotificationSetting__c WHERE msContact__c = :newGCCUser.ContactId
        ];

        Set<String> generatedSubscriptions = new Set<String>();
        for(msUserNotificationSetting__c subscriptionItem : usersSubscriptions) {
            if(SUBSCRIPTIONS_AUTO.contains(subscriptionItem.msNotificationType__c) ) {
                System.assert(subscriptionItem.msIsEmail__c, 'The subscription for ' + subscriptionItem.msNotificationType__c + ' should have been active for Email');
                generatedSubscriptions.add(subscriptionItem.msNotificationType__c);
            }
        }
        System.assert(generatedSubscriptions.containsAll(SUBSCRIPTIONS_AUTO), 'Not all subscriptions have been generated');
        System.assert(SUBSCRIPTIONS_AUTO.containsAll(generatedSubscriptions), 'Too many subscriptions have been generated');
    }

    @IsTest
    private static void testThatEstablishedSubscriptionsDoNotGetOverwrittenOnUpdate(){
        Id testContactId = [SELECT Id FROM Contact LIMIT 1].Id;
        Id globalCustomerCommunityUserProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'Global Customer Community User' LIMIT 1].Id;
        User newGCCUser = new User(
                Username = 'msUserHandlerTest@statkraft.mindsquare.user.dev',
                Email = 'testuser@mindsquare.de',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'de_DE_EURO',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'Europe/Berlin',
                Alias = 'testusr',
                ContactId = testContactId,
                LastName = 'User',
                ProfileId = globalCustomerCommunityUserProfileId,
                MobilePhone = '+49123456789');
        insert newGCCUser;
        List<msUserNotificationSetting__c> defaultSubscriptions = new List<msUserNotificationSetting__c>();
        msUserNotificationSetting__c signUpDownreg = new msUserNotificationSetting__c();
        signUpDownreg.msContact__c = newGCCUser.ContactId;
        signUpDownreg.msNotificationType__c = 'downreg_notification';
        signUpDownreg.msIsEmail__c = false;
        defaultSubscriptions.add(signUpDownreg);
        msUserNotificationSetting__c signUpSubmeter = new msUserNotificationSetting__c();
        signUpSubmeter.msContact__c = newGCCUser.ContactId;
        signUpSubmeter.msNotificationType__c = 'submeter_enabled';
        signUpSubmeter.msIsEmail__c = false;
        defaultSubscriptions.add(signUpSubmeter);
        insert defaultSubscriptions;
        User runningUser = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];


        List<msUserNotificationSetting__c> usersSubscriptions = [
                SELECT Id, msNotificationType__c, msIsEmail__c
                FROM msUserNotificationSetting__c WHERE msContact__c = :newGCCUser.ContactId
        ];
        Set<String> generatedSubscriptions = new Set<String>();
        for(msUserNotificationSetting__c subscriptionItem : usersSubscriptions) {
            if(SUBSCRIPTIONS_AUTO.contains(subscriptionItem.msNotificationType__c) ) {
                System.assert(!subscriptionItem.msIsEmail__c, 'The subscription for ' + subscriptionItem.msNotificationType__c + ' should have been inactive for Email');
                generatedSubscriptions.add(subscriptionItem.msNotificationType__c);
            }
        }
        System.assert(generatedSubscriptions.containsAll(SUBSCRIPTIONS_AUTO), 'Not all subscriptions are present');

    }*/

    private static void createTestAccount() {
        testAccount = msGranularTestDataFactory.createTestAccounts(1, 'Germany', Application.RecordTypes.byDeveloperName('Account', 'Account').Id)[0];
        insert testAccount;
    }

    private static void createTestContact() {
        Contact testContact = msGranularTestDataFactory.createTestContacts(1)[0];
        testContact.AccountId = testAccount.Id;
        insert testContact;
    }
}