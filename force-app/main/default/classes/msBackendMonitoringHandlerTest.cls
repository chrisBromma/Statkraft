/****************************************************************************************************
* Class msBackendMonitoringHandlerTest
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2020-04-27
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2020-04-27       	Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msBackendMonitoringHandlerTest {
    @IsTest
    private static void testEventEneration() {
        BackendMonitoring__e logEvent = msUtility.getEvent('Test Event');

        Test.startTest();
        msUtility.publishEvent(logEvent);
        Test.stopTest();
    }
}