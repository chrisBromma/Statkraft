/****************************************************************************************************
* Class msSetPasswordControllerTest
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   13.03.2019
*   Description	:	Test class for the msSetPasswordController class
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)      13.03.2019       	    Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msSetPasswordControllerTest {
    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }
    @IsTest
    private static void testChangePwd() {
        String pwd = 'testPwd0087';
        User testUsr = [SELECT Id FROM User WHERE Username='DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Test.startTest();
        System.runAs(testUsr) {
            msSetPasswordController.setUserPassword(pwd);
        }
        Test.stopTest();
    }
    @IsTest
    private static void testChangePwdFails() {
        User testUsr = [SELECT Id FROM User WHERE Username='DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        Test.startTest();
        Boolean properBehaviour = false;
        try {
            System.runAs(testUsr) {
                msSetPasswordController.setUserPassword('');
            }
            System.assert(false, 'Should have failed');
        } catch (AuraHandledException ex) {
            properBehaviour = true;
        }
        Test.stopTest();
        System.assert(properBehaviour, 'The Password should have been illegal and throw an Exception');
    }
}