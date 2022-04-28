/****************************************************************************************************
* Class msLanguageSelectorControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   14.08.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   14.08.2018      	    Init version.
*****************************************************************************************************/

@isTest
public with sharing class msLanguageSelectorControllerTest {

    static testMethod void testChangeLanguage() {
        msTestDataFactory.createTestPortalContext();
        User testUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();
        System.runAs(testUser) {
            msLanguageSelectorController.setLanguage('de');
            testUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
            System.assert(testUser.LanguageLocaleKey=='de');

            msLanguageSelectorController.setLanguage('en_GB');
            testUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
            System.assert(testUser.LanguageLocaleKey=='en_US');

            msLanguageSelectorController.setLanguage('fr');
            testUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
            System.assert(testUser.LanguageLocaleKey=='fr');

            System.Test.stopTest();
        }
    }
}