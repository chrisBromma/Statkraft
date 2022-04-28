/****************************************************************************************************
 * Class msBrytTradeConfPDFControllerTest
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 09.04.2019
 *   Description : Test class for the msBrytTradeConfPDF Visualforce page Controller
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	09.04.2019	Init version.
 *****************************************************************************************************/
@IsTest
public with sharing class msBrytTradeConfPDFControllerTest {
    @TestSetup
    public static void testSetup() {
        msBrytTestDataFactory.createTestRecords();
    }
    @IsTest
    public static void msBrytTradeConfPDFControllerTest() {
        ApexPages.currentPage().getParameters().put('userid', UserInfo.getUserId());
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        msBrytTradeConfPDFController testController = new msBrytTradeConfPDFController();
    }
    @IsTest
    public static void testGetUserIdException() {
        Test.startTest();
        msBrytTradeConfPDFController.getUserId();
        Test.stopTest();
    }
    @IsTest
    public static void testGetUserNameException() {
        Test.startTest();
        msBrytTradeConfPDFController.getUserName();
        Test.stopTest();
    }
    @IsTest
    public static void testGetAccountNameException() {
        Test.startTest();
        msBrytTradeConfPDFController.getAccountName();
        Test.stopTest();
    }
    @IsTest
    public static void testGetPricingComponents() {
        Test.startTest();
        msBrytTradeConfPDFController.getPricingComponents();
        Test.stopTest();
    }
}