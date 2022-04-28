/****************************************************************************************************
* Class msBrytWhatsGoingOnTestClass
*
*   Create By	:   Fabian Kramer (mindsquare GmbH)
*   Create Date	:   07.03.2019
*   Description	:	Test for msBrytWhatsGoingOnController
* 	Coverage:       100%
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Kramer (mindsquare GmbH)		07.03.2019       	Init version.
*****************************************************************************************************/

@IsTest
public with sharing class msBrytWhatsGoingOnTestClass {
    @IsTest
    public static void testBulletins() {
        msBrytTestDataFactory.createTestRecords();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Test.startTest();
        System.runAs(testUser) {
            msBrytWhatsGoingOnController.getBulletins();
        }
        Test.stopTest();
    }
}