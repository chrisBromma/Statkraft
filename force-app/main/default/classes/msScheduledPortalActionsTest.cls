/****************************************************************************************************
* Class msScheduledPortalActionsTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   23.05.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   23.05.2019      	    Init version.
*****************************************************************************************************/

@IsTest
private without sharing class msScheduledPortalActionsTest {
    @TestSetup public static void generateTestData(){

    }
    @IsTest
    static void testBehavior() {
        List<PortalSettings__c> portalSettings = new List<PortalSettings__c>();
        portalSettings.add(new PortalSettings__c(Name = 'Annual Submeter - Allow Update', Checkbox__c = true));
        portalSettings.add(new PortalSettings__c(Name = 'Monthly Submeter - Allow Update', Checkbox__c = true));
        insert portalSettings;
        Test.startTest();
        System.schedule('ScheduledApexTest', '0 0 0 2 2 ? 2050', new msScheduledPortalActions());
        Test.stopTest();
    }
}