/****************************************************************************************************
* Class msForgotPasswordControllerTest
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2019-09-26
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2019-09-26       	Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msForgotPasswordControllerTest {
    @TestSetup
    private static void setup() {
        msTestDataFactory.createTestPortalContext();
    }
    @IsTest
    private static void testReset() {
        User random = [SELECT Username FROM User WHERE IsActive = true AND Profile.Name = 'Global Customer Community User' AND ContactId != NULL LIMIT 1];
        msForgotPasswordController.resetPassword(random.Username);
    }

    @IsTest
    private static void testResetWithInvalidUsername() {
        String invalidUsername = 'invalidUsername';
        try{
            msForgotPasswordController.resetPassword(invalidUsername);
        } catch (AuraHandledException ex){
            System.debug('An exception occurred: ' + ex.getMessage());
        }
    }
}