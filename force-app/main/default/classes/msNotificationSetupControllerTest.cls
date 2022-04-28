/****************************************************************************************************
* Class msNotificationSetupControllerTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	Testclass for the class msNotificationSetupController.
*
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019      	Init version.
*****************************************************************************************************/
@IsTest public with sharing class msNotificationSetupControllerTest {

    @TestSetup public static void generateTestData() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest public static void getOptionsTest() {
        User testUser = [SELECT Id, ContactId, IsActive FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.runAs(new User(Id = UserInfo.getUserId())) {
            testUser.IsActive = true;
            update testUser;
        }
        Boolean needToCreateData = false;
        System.runAs(testUser) {
            List<msNotificationSetupController.option> optionsList = msNotificationSetupController.getOptions();
            if (optionsList.size() == 0) {
                needToCreateData = true;
            }
        }
        if (needToCreateData) {
            msUserNotificationSetting__c newSetting = new msUserNotificationSetting__c();
            List<String> booleanEntries = msNotificationSetupController.getBooleanFieldsForMarketOptions();
            Schema.DescribeSObjectResult objectDescribe = msPortalMarketNotificationOption__mdt.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
            newSetting.msNotificationType__c = objectFields.get(booleanEntries[0]).getDescribe().getLabel();
            newSetting.msIsEmail__c = true;
            newSetting.msContact__c = testUser.ContactId;
            insert newSetting;
        }

        System.runAs(testUser) {
            Test.startTest();
            List<msNotificationSetupController.option> optionsList = msNotificationSetupController.getOptions();
            Test.stopTest();
            System.assert(optionsList != null);
        }
    }

    @IsTest public static void saveOptionsTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        List<String> booleanEntries = msNotificationSetupController.getBooleanFieldsForMarketOptions();
        msNotificationSetupController.option newOption = new msNotificationSetupController.option();
        Schema.DescribeSObjectResult objectDescribe = msPortalMarketNotificationOption__mdt.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
        newOption.APIName = objectFields.get(booleanEntries[0]).getDescribe().getLabel();
        newOption.isEmail = true;

        System.runAs(testUser) {
            Test.startTest();
            List<msNotificationSetupController.option> optionsList = msNotificationSetupController.getOptions();
            Boolean matchFound = false;
            for (msNotificationSetupController.option option : optionsList) {
                if (newOption.APIName == option.APIName) {
                    matchFound = true;
                    option.isEmail = !option.isEmail;
                }
            }
            if (!matchFound) {
                optionsList.add(newOption);
            }
            Boolean success = msNotificationSetupController.saveOptions(optionsList);
            Test.stopTest();
            System.assert(success);
        }
    }

    @IsTest public static void getValidUserOptionsTest() {
        Set<String> markets = new Set<String>();
        markets.add('France');
        Test.startTest();
        Map<String, Map<String, Boolean>> validUserOptions = msNotificationSetupController.getValidUserOptions(markets);
        Test.stopTest();
        System.assert(validUserOptions != null);
    }
}