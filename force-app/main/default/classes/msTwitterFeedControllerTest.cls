/****************************************************************************************************
* Class msTwitterFeedControllerTest
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

@IsTest
public with sharing class msTwitterFeedControllerTest {

    @TestSetup static void setup() {
        msTestDataFactory.createTestPortalContext();
        PortalSettings__c pSettings1 = new PortalSettings__c();
        pSettings1.Name = 'Twitter - Account Name - en_US';
        pSettings1.String__c = 'Twitter - Account Name - en_US';
        insert pSettings1;
    }

    @isTest
    private static void testGetRSSFeed() {
        User testUkUser = [SELECT Id FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        User testOtherUser = [SELECT Id,LanguageLocaleKey FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        update testOtherUser;

        System.Test.startTest();
        System.runAs(testUkUser){
            String twitterAccountName = msTwitterFeedController.getTwitterFeed();
            System.assertEquals('Twitter - Account Name - en_US', twitterAccountName, 'Failed to receive Twitter Account Name from Portal Settings');
        }
        System.runAs(testOtherUser){
            String defaultTwitterAccountName = msTwitterFeedController.getTwitterFeed();
            System.assertEquals('Statkraft', defaultTwitterAccountName, 'Failed to receive default Twitter Account Name');
        }
        System.Test.stopTest();
    }
}