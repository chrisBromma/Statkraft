/****************************************************************************************************
* Class dynamicEmailAlertTemplateControllerTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-02-11
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-02-11       	Init version.
*****************************************************************************************************/

@IsTest
private class dynamicEmailAlertTemplateControllerTest {

    static String PLAIN_TEST_TEXT = 'test1{Contract.Name} ' +
            'test2{ContractRole.Contact__r.Name} ' +
            'test3{Contract.BrokenLink.Name} ' +
            'test4{Contract.FieldNameBroken} ' +
            'test5{Contract..DoublePoints} ' +
            'test6{BrokenMergeHead.Name} ' +
            'test7{Contract.} ' +
            'test8{Contract.Approval_Waiver__c}';

    @IsTest
    static void checkForSupportTest() {
        dynamicEmailAlertTemplateController controller = new dynamicEmailAlertTemplateController();
        controller.sObjectName = 'gibberish';
        String message = null;
        try {
            controller.getMergedEmailPlainTextBody();
        } catch (AuraHandledException e) {
            message = e.getMessage();
        }
        System.assert(message != null);
    }

    @IsTest
    static void generateEmailForContractCase() {
        Case testCase = [
                SELECT Id
                FROM Case
                WHERE Subject = 'dynamicEmailAlertTemplateController_generateEmailForContractCase'
                LIMIT 1
        ];


        dynamicEmailAlertTemplateController controller = new dynamicEmailAlertTemplateController();
        controller.caseId = testCase.Id;
        controller.contractRoleType = 'Mail recipient';
        controller.isHTML = true;
        controller.templateName = 'unique_name_for_test_of_dynamicEmailAlertTemplateController';
        controller.sObjectName = 'Case';
        controller.recipientId = UserInfo.getUserId();


        dynamicEmailAlertTemplateController controller2 = new dynamicEmailAlertTemplateController();
        controller2.caseId = testCase.Id;
        controller2.contractRoleType = 'Mail recipient';
        controller2.isHTML = false;
        controller2.templateName = 'unique_name_for_test_of_dynamicEmailAlertTemplateController';
        controller2.sObjectName = 'Case';
        controller2.recipientId = UserInfo.getUserId();
        Test.startTest();
        String htmlBody = controller.getMergedEmailHtmlBody();
        String plainBody = controller2.getMergedEmailPlainTextBody();
        Test.stopTest();
        System.debug(plainBody);
        System.assert(htmlBody != null);
        System.assert(htmlBody.contains('test1'));
        System.assert(htmlBody.contains('test2'));
        System.assert(!htmlBody.contains('test1N/A'));
        System.assert(!htmlBody.contains('test2N/A'));
        System.assert(!htmlBody.contains('test1{'));
        System.assert(!htmlBody.contains('test2{'));
        System.assert(plainBody != null);
        System.assert(!plainBody.contains('test1{'));
        System.assert(!plainBody.contains('test2{'));
        System.assert(plainBody.contains('test3N/A'));
        System.assert(plainBody.contains('test4N/A'));
        System.assert(plainBody.contains('test5N/A'));
        System.assert(plainBody.contains('test6{BrokenMergeHead.Name}'));
        System.assert(plainBody.contains('test7N/A'));
        System.assert(plainBody.contains('test8true'));
    }
    @IsTest
    static void generateEmailForContractCase_IdsMissing() {


        dynamicEmailAlertTemplateController controller = new dynamicEmailAlertTemplateController();
        controller.contractRoleType = 'Mail recipient';
        controller.isHTML = true;
        controller.templateName = 'unique_name_for_test_of_dynamicEmailAlertTemplateController';
        controller.sObjectName = 'Case';
        controller.recipientId = UserInfo.getUserId();

        Test.startTest();
        String htmlBody = controller.getMergedEmailHtmlBody();
        Test.stopTest();
        System.assert(htmlBody.contains('test1N/A'));
        System.assert(htmlBody.contains('test2N/A'));
    }

    @TestSetup
    static void setup() {
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.IsActive = true;
        validEmailTemplate.Name = 'name';
        validEmailTemplate.DeveloperName = 'unique_name_for_test_of_dynamicEmailAlertTemplateController';
        validEmailTemplate.TemplateType = 'Custom';
        validEmailTemplate.Body = PLAIN_TEST_TEXT;
        validEmailTemplate.HtmlValue = PLAIN_TEST_TEXT;
        validEmailTemplate.FolderId = UserInfo.getUserId();

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            insert validEmailTemplate;
        }

        Account testAccount = new Account(
                Name = 'test'
        );
        insert testAccount;
        Contract__c testContract = new Contract__c(
                Name = 'testContract_for_dynamicEmailAlertTemplateController',
                Contract_Holder__c = testAccount.Id,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addDays(1),
                Approval_Waiver__c = true
        );
        insert testContract;
        Contact testContact = new Contact(
                LastName = 'test'
        );
        insert testContact;
        Contract_Role__c testRole = new Contract_Role__c(
                Contract__c = testContract.Id,
                Contact__c = testContact.Id,
                Role__c = 'Mail recipient',
                Start_Date__c = Date.today(),
                RecordTypeId = msTestDataFactory.CONTRACT_ROLE_RECORD_TYPE
        );
        insert testRole;
        Case testCase = new Case(
                Contract__c = testContract.Id,
                Subject = 'dynamicEmailAlertTemplateController_generateEmailForContractCase'
        );
        insert testCase;
    }
}