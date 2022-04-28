/****************************************************************************************************
* Class msCreateCommunityUserTest
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   09.08.2018
*   Description	:	Testclass for the class msCreateCommunityUser.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            09.08.2018          Init version.
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019          Updated to cover Portal User Reactivation
*****************************************************************************************************/
@isTest
private class msCreateCommunityUserTest {

    static testMethod void testCreateUser() {
        msTestDataFactory.createTestPortalContext();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Contract__c testContract = new Contract__c(
                RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId(),
                Start_Date__c = Date.today().addDays(-20),
                End_Date__c = Date.today().addDays(2),
                Contract_Holder__c = testAccount.Id,
                Status__c = 'Active',
                Country__c = 'Germany',
                Approved__c = true,
                Meter_Billing_Type__c = 'Sub-Meter Yearly',
                Name = 'New Contract 1'
        );
        insert testContract;

        Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact to Create',
                Email = 'decontact@mail.com.createbytest',
                AccountId = testAccount.Id,
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId(),
                MobilePhone = '+49123456789'
        );
        insert testContact;

        Contract_Role__c testContractRole = new Contract_Role__c(
                Contact__c = testContact.Id,
                Contract__c = testContract.Id,
                Start_Date__c = Date.today(),
                RecordTypeId = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Contract_Role_Contact').getRecordTypeId(),
                Role__c = 'Customer Portal'
        );
        insert testContractRole;

        List<User> usersBeforeRun = [SELECT Id, IsActive FROM User WHERE ContactId = :testContact.id];
        System.Test.startTest();
        msCreateCommunityUser.createUser(new List<Contract_Role__c>{
                testContractRole
        });
        System.Test.stopTest();

        List<User> usersAfterRun = [SELECT Id, IsActive FROM User WHERE ContactId = :testContact.id];
        System.assert(usersBeforeRun.size() + 1 == usersAfterRun.size(), 'Error, all users has not been created');
    }
}