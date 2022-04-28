@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

    @IsTest
    static void testLoginWithInvalidCredentials() {
        LightningLoginFormController.login('testUser', 'fakepwd', null);
    }

    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        LightningLoginFormController controller = new LightningLoginFormController();
        System.assertNotEquals(controller, null);
    }

    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
    }

    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
    }

    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
    }

    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }

    /*@IsTest
    static void testForgotPasswordUrl() {
     String url = LightningLoginFormController.getForgotPasswordUrl();
     System.assertNotEquals(null, url);
    }*/


    @IsTest
    static void testExperienceIdNotNull() {
        String expId = 'Test1';
        String experienceId = LightningLoginFormController.setExperienceId(expId);
        System.assertNotEquals(null, experienceId);
    }

    @IsTest
    static void testExperienceIdIsNull() {
        String expId = null;
        String experienceId = LightningLoginFormController.setExperienceId(expId);
        System.assertEquals(null, experienceId);
    }
}