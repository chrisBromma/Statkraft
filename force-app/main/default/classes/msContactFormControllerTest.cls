/****************************************************************************************************
* Class msContactFormControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   14.08.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)        14.08.2018      	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      20.02.2020              Commented out legacy code
*****************************************************************************************************/
@IsTest
private with sharing class msContactFormControllerTest {
    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    static void getContactDetailsForGuestUserTest() {
        System.assert(msContactFormController.getContactDetails().size() >= 3, 'There should be at least 3 markets defined at this point');
    }
    @IsTest
    static void testGetContactDetailsDE() {
        User testUsrDE = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.runAs(testUsrDE) {
            System.assert(msContactFormController.getContactDetails().size() == 1, 'The user is logged in and should only have one Market Contact');
        }
    }
    @IsTest
    static void testGetContactDetailsFR() {
        User testUsrFR = [SELECT Id FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        System.runAs(testUsrFR) {
            System.assert(msContactFormController.getContactDetails().size() == 1, 'The user is logged in and should only have one Market Contact');
        }

    }
    @IsTest
    static void testGetContactDetailsUK() {
        User testUsrUK = [SELECT Id FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.runAs(testUsrUK) {
            System.assert(msContactFormController.getContactDetails().size() == 1, 'The user is logged in and should only have one Market Contact');
        }
    }
    @IsTest
    static void testGetContactDetailsForGuestUser() {
        User testGuestUser = [SELECT Id FROM User WHERE Profile.Id ='00e1v000000ZV0WAAW'];

        System.runAs(testGuestUser) {
            System.assert(msContactFormController.getContactDetails().size() >= 2, 'The  guest user should have more than one Market Contact');
        }
    }
    
}