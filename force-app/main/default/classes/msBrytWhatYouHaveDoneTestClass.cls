/****************************************************************************************************
* Class msBrytWhatYouHaveDoneTestClasss
*
*   Create By	:   Fabian Kramer (mindsquare GmbH)
*   Create Date	:   07.03.2019
*   Description	:	Test for msBrytWhatYouHaveDoneBackendController
* 	Coverage:       50%
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Kramer (mindsquare GmbH)		07.03.2019       	Init version.
*****************************************************************************************************/

@IsTest
public without sharing class msBrytWhatYouHaveDoneTestClass {

    public static Integer thisYear = Date.today().year();

    @TestSetup public static void createTestData() {
        msBrytTestDataFactory.createTestRecords();
    }
    @IsTest public static void testDates() {
        Test.startTest();
        msBrytWhatYouHaveDoneBackendController.getStartDate();
        msBrytWhatYouHaveDoneBackendController.getEndDate();
        Test.stopTest();
    }
    @IsTest public static void testQueryPricingComponent() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser) {
            Contract__c newC = msBrytUtility.getUserDetails().contracts[0];
            Test.startTest();
            msBrytWhatYouHaveDoneBackendController.queryPricingComponents(newC.Id);
            Test.stopTest();
        }
    }
    @IsTest public static void testSmallComponents() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser) {
            Test.startTest();
            msBrytWhatYouHaveDoneBackendController.getAccountName();
            msBrytWhatYouHaveDoneBackendController.getUsername();
            msBrytWhatYouHaveDoneBackendController.getSessionUser();
            msBrytWhatYouHaveDoneBackendController.getUserId();
            Test.stopTest();
        }
    }
    @IsTest public static void testgetformattedPricingComponents() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser) {
            Contract__c newC = msBrytUtility.getUserDetails().contracts[0];
            Test.startTest();
            List<Pricing_Component__c> pc = msBrytWhatYouHaveDoneBackendController.queryPricingComponents(newC.Id);
            msBrytWhatYouHaveDoneBackendController.getformattedPricingComponents(pc);
            Test.stopTest();
        }
    }
    @IsTest
    public static void testConstructor() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser) {
            Contract__c newC = msBrytUtility.getUserDetails().contracts[0];
            Test.startTest();
            ApexPages.currentPage().getParameters().put('selectedContract', newC.Id);
            msBrytWhatYouHaveDoneBackendController testController = new msBrytWhatYouHaveDoneBackendController();
            Test.stopTest();
        }
    }
}