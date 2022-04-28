@IsTest
private class msBrytForgotPasswordControllerTest {

    @TestSetup
    private static void setup() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    private static void testResetByUsername() {
        User brytUser = [SELECT Username FROM User WHERE IsActive = true AND Profile.Name = 'Bryt Customer Community User' AND ContactId != NULL LIMIT 1];
        String usernameToReset = brytUser.Username;
        msBrytForgotPasswordController.resetPassword(usernameToReset);
    }

    @IsTest
    private static void testResetByEmail() {
        User brytUser = [SELECT Email FROM User WHERE IsActive = true AND Profile.Name = 'Bryt Customer Community User' AND ContactId != NULL LIMIT 1];
        String emailToReset = brytUser.Email;
        msBrytForgotPasswordController.resetPassword(emailToReset);
    }

    @IsTest
    private static void testResetWrongUser() {
        String usernameToReset = String.valueOf(Crypto.generateAesKey(128));
        msBrytForgotPasswordController.resetPassword(usernameToReset);
    }
}