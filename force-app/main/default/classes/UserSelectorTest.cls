@isTest
private class UserSelectorTest {

    private static final Id profileId = msTestDataFactory.DE_EEG_PROFILE_ID;

    @testSetup static void setup() {
        insert msGranularTestDataFactory.createTestUsers(1,profileId,'en_GB', 'en_US');
    }

    @isTest
    private static void testGetSobjectType() {
        UserSelector UserSelector = (UserSelector) Application.Selector.newInstance(User.SObjectType);
        System.assertEquals('User', String.valueOf(UserSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        UserSelector UserSelector = (UserSelector) Application.Selector.newInstance(User.SObjectType);
        System.assertEquals(4, UserSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testGetUsersEmail() {
        User testUser = [SELECT Id, Email FROM User WHERE LastName = 'User0'];
        Set<Id> userIds = new Set<Id>();
        userIds.add(testUser.Id);
        UserSelector UserSelector = (UserSelector) Application.Selector.newInstance(User.SObjectType);
        System.assertEquals(testUser.Email, UserSelector.getUsersEmail(userIds).get(testUser.Id));
    }

    @isTest
    private static void testGetPixOSUser() {
        System.assertEquals('Pixos Service', UserSelector.getPixOSUser().Name);
    }
}