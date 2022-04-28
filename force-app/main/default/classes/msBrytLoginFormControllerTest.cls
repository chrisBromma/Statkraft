/****************************************************************************************************
* Class msBrytLoginFormControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   20.11.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   20.11.2018      	    Init version.
*****************************************************************************************************/

@IsTest
public with sharing class msBrytLoginFormControllerTest {
    @IsTest
    static void testValidLogin(){
        msBrytTestDataFactory.createTestRecords();
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser){
            try{
                msBrytLoginFormController.login('testuser@statkraft.mindsquare.user.dev', '1234abcd', null);
            }
            catch(Exception ex){
                System.assert(false);
            }
        }
    }

    @IsTest
    static void testLoginWithInvalidCredentials() {
        try{
            msBrytLoginFormController.login('testUser', 'fakepwd', null);
        }
        catch(Exception ex){
            System.assert(true);
        }
    }

    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(true, msBrytLoginFormController.getIsUsernamePasswordEnabled());
    }

    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, msBrytLoginFormController.getIsSelfRegistrationEnabled());
    }

    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, msBrytLoginFormController.getSelfRegistrationUrl());
    }

    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = msBrytLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }

    @IsTest
    static void testExperienceIdNotNull() {
        String expId = 'Test1';
        String experienceId = msBrytLoginFormController.setExperienceId(expId);
        System.assertNotEquals(null, experienceId);
    }

    @IsTest
    static void testExperienceIdIsNull() {
        String expId = null;
        String experienceId = msBrytLoginFormController.setExperienceId(expId);
        System.assertEquals(null, experienceId);
    }
}