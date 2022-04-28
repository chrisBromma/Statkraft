public without sharing class msBrytForgotPasswordController {

    private static final String DEFAULT_SUFFIX = Label.msBrytFlexUsernameSuffix;
    public static final String COMMUNITY_USER_PROFILE_NAME = 'Bryt Customer Community User';

    @AuraEnabled
    public static void resetPassword(String emailAddress) {
        List<User> users = [
                SELECT Username
                FROM User
                WHERE (Username = :emailAddress OR Username = :emailAddress + DEFAULT_SUFFIX OR Email = :emailAddress)
                AND ContactId != NULL
                AND IsActive = TRUE
                AND Profile.Name = :COMMUNITY_USER_PROFILE_NAME
                LIMIT 1
        ];
        if (!users.isEmpty()) {
            Site.forgotPassword(users[0].Username);
        }
    }
}