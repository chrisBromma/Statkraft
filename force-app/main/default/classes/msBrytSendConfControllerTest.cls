/****************************************************************************************************
 * Class msBrytSendConfControllerTest
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 09.04.2019
 *   Description : Test class for the class msBrytSendConfController
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	09.04.2019	Init version.
 *****************************************************************************************************/
@IsTest
public with sharing class msBrytSendConfControllerTest {
    @TestSetup
    public static void testSetup() {
        msBrytTestDataFactory.createTestRecords();
    }
    @IsTest
    public static void msBrytSendConfControllerTest() {
        List<Pricing_Component__c> allPCs = [SELECT Id FROM Pricing_Component__c];
        String listOfIdsByConcatenation = '';
        for (Pricing_Component__c pcItem : allPCs) {
            listOfIdsByConcatenation += '.' + pcItem.Id;
        }
        ApexPages.currentPage().getParameters().put('listOfIdsByConcatenation', listOfIdsByConcatenation);
        msBrytSendConfController controllerTest = new msBrytSendConfController();
    }
    @IsTest
    public static void msBrytSendConfControllerTestException() {
        msBrytSendConfController controllerTest = new msBrytSendConfController();
    }
}