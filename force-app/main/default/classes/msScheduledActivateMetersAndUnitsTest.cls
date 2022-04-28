/****************************************************************************************************
* Class msScheduledActivateMetersAndUnitsTest
*
*   Create By	:   Maciej Dudek
*   Create Date	:   2019-07-15
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Maciej Dudek                     	            2019-07-15       	Init version.
*****************************************************************************************************/

@IsTest
private class msScheduledActivateMetersAndUnitsTest {

    private static final String CRON_EXP = '0 0 * * * ?';

    @IsTest
    private static void testScheduleCurtailmentUnlock() {

        Test.startTest();
        System.schedule('msScheduledActivateMetersAndUnits', CRON_EXP, new msScheduledActivateMetersAndUnits());
        Test.stopTest();

        System.assertNotEquals(0, [SELECT count() FROM CronTrigger], 'A job should be scheduled');
    }
}