@IsTest
public with sharing class msBrytAdminSectionControllerTest {

    @TestSetup public static void createTestData() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest public static void testGetPricingComponents() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        System.runAs(testUser) {
            Test.startTest();
            msBrytAdminSectionController.getPricingComponentsWrapper();
            Test.stopTest();
        }
    }

    @IsTest
    public static void testConstructor(){
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Contract__c newC = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'TestContract6' LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            ApexPages.currentPage().getParameters().put('selectedContract',newC.Id);
            msBrytAdminSectionController testController = new msBrytAdminSectionController();
            Test.stopTest();
        }
    }
}