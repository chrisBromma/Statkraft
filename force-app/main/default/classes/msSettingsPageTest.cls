/****************************************************************************************************
* Class msSettingsPageTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   11.10.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   11.10.2018      	    Init version.
*****************************************************************************************************/


@isTest
public with sharing class msSettingsPageTest {

    static testMethod void testGetContracts() {
        msTestDataFactory.createTestPortalContext();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();
        System.runAs(testUser) {
            msSettingsPage.getContracts();
            System.Test.stopTest();
        }
    }
}