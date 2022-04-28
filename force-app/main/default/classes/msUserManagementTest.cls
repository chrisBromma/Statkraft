/****************************************************************************************************
* Class msUserManagementTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   15.11.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   15.11.2019      	    Init version.
*****************************************************************************************************/

@IsTest
public class msUserManagementTest {
    public static final String MARKET = 'Germany';

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
        Contact testContact = [SELECT Id, Name FROM Contact WHERE Id IN (SELECT ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal')];
        Contract_Role__c testContractRole = [SELECT Id, Contract__c FROM Contract_Role__c WHERE Role__c = 'Contractual contact' AND Contact__c = :testContact.Id LIMIT 1];

        Contact subContact = new Contact(
                LastName = 'SubContact1',
                Email = 'test@test.com',
                msPortalRequestBy__c = testContact.Id
        );
        insert subContact;

        Contract_Role__c subContractRole = new Contract_Role__c(
                Contact__c = subContact.Id,
                Start_Date__c = Date.today().addMonths(-5),
                Role__c = 'Customer Portal',
                Contract__c = testContractRole.Contract__c,
                RecordTypeId = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Contract_Role_Contact').getRecordTypeId()
        );
        insert subContractRole;
    }

    @IsTest
    public static void testGetUserDetails() {
        User user = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        msUserManagementController.UserManagementWrapper result = new msUserManagementController.UserManagementWrapper();
        Test.startTest();
        System.runAs(user) {
            result = msUserManagementController.getUserDetails();
        }
        Test.stopTest();
        String userWrappers = System.JSON.serialize(result.userWrappers);
        String contracts = System.JSON.serialize(result.contracts);
        String contractSchema = System.JSON.serialize(result.contractSchema);

        System.assert(userWrappers.contains('contractWrappers'));
        System.assert(contracts.contains('Contract__c'));
        System.assert(contractSchema.contains('requestedRole'));

    }

    @IsTest
    public static void testInsertContact() {

        Test.startTest();
        insertContactHelper();
        Test.stopTest();

        Contact testContactId = [SELECT Id FROM Contact WHERE Sandbox_Migration_Id__c = 'testBruno'];
        List<Contract_Role__c> insertedContractRequests = [SELECT Id, Contact__c FROM Contract_Role__c WHERE Contact__c = :testContactId.Id];
        List<Site_Role__c> insertedPlantRequests = [SELECT Id, Contact__c FROM Site_Role__c WHERE Contact__c = :testContactId.Id];

        for (Contract_Role__c contractRequest : insertedContractRequests) {
            System.assertEquals(testContactId.Id, contractRequest.Contact__c);
        }
        for (Site_Role__c plantRequest : insertedPlantRequests) {
            System.assertEquals(testContactId.Id, plantRequest.Contact__c);
        }
    }
    @IsTest
    public static void testChangeUserStatus() {
        User user = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Test.startTest();
        System.runAs(user) {
            msUserManagementController.changeUserStatus(testUser.Id, false);
        }
        Test.stopTest();
        UserLogin frozenUser = [SELECT Id, IsFrozen FROM UserLogin WHERE UserId = :testUser.Id];

        System.assertEquals(true, frozenUser.IsFrozen);
    }
    @IsTest
    public static void testHideUser() {
        Contact testContact = [SELECT Id, msHideFromUserManagement__c FROM Contact LIMIT 1];

        Test.startTest();
        msUserManagementApprovalController.hideUserRequest(testContact.Id, MARKET);
        Test.stopTest();
        Contact hiddenContact = [SELECT msHideFromUserManagement__c FROM Contact WHERE Id = :testContact.Id];

        System.assertEquals(!testContact.msHideFromUserManagement__c, hiddenContact.msHideFromUserManagement__c);
    }
    @IsTest
    public static void testDeclineRequest() {
        Test.startTest();
        insertContactHelper();
        msUserManagementApprovalController.getApprovalRequests(MARKET);
        List<Contract_Role__c> contractRoles = [SELECT Id FROM Contract_Role__c WHERE Role__c INCLUDES ('Customer Portal')];
        List<Site_Role__c> siteRoles = [SELECT Id FROM Site_Role__c WHERE Role__c INCLUDES ('Customer Portal')];

        List<Id> ids = new List<Id>();
        for (Site_Role__c tempSiteRole : siteRoles) {
            ids.add(tempSiteRole.Id);
        }
        for (Contract_Role__c tempSiteRole : contractRoles) {
            ids.add(tempSiteRole.Id);
        }


        msUserManagementApprovalController.declineRequest(ids, MARKET);
        List<Contract_Role__c> deletedContractRoles = [SELECT Id FROM Contract_Role__c WHERE Id IN :ids];
        List<Site_Role__c> deletedSiteRoles = [SELECT Id FROM Site_Role__c WHERE Id IN :ids];
        Test.stopTest();
        System.assert(deletedContractRoles.isEmpty());
        System.assert(deletedSiteRoles.isEmpty());
    }
    @IsTest
    public static void testApproveRequest() {
        insertContactHelper();

        List<Contract_Role__c> contractRoles = [SELECT Id FROM Contract_Role__c WHERE Role__c INCLUDES ('Customer Portal')];
        List<Site_Role__c> siteRoles = [SELECT Id FROM Site_Role__c WHERE Role__c INCLUDES ('Customer Portal')];

        List<Id> ids = new List<Id>();
        for (Site_Role__c tempSiteRole : siteRoles) {
            ids.add(tempSiteRole.Id);
        }
        for (Contract_Role__c tempSiteRole : contractRoles) {
            ids.add(tempSiteRole.Id);
        }

        Test.startTest();
        msUserManagementApprovalController.approveRequest(ids, MARKET);
        Test.stopTest();

        Contact testContact = [SELECT Id, Name FROM Contact WHERE Sandbox_Migration_Id__c = 'testBruno'];
        List<Contract_Role__c>contractRolesAfter = [SELECT Id, End_Date__c, msAwaitingPortalActivation__c FROM Contract_Role__c WHERE Contact__c = :testContact.Id AND Role__c INCLUDES ('Customer Portal')];
        List<Site_Role__c>siteRolesAfter = [SELECT Id, End_Date__c, msAwaitingPortalActivation__c FROM Site_Role__c WHERE Contact__c = :testContact.Id AND Role__c INCLUDES ('Customer Portal')];

        for (Site_Role__c siteRole : siteRolesAfter) {
            System.assert(!siteRole.msAwaitingPortalActivation__c);
        }
        for (Contract_Role__c contractRole : contractRolesAfter) {
            System.assert(!contractRole.msAwaitingPortalActivation__c);
        }
    }
    @IsTest
    public static void testSaveSettings() {
        Test.startTest();
        insertContactHelper();
        User user = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        List<Contract_Role__c>contractRoles = [SELECT Id, Contract__c, Contact__c, Active__c FROM Contract_Role__c WHERE Role__c INCLUDES ('Customer Portal') AND Contact__r.Sandbox_Migration_Id__c = 'testBruno'];
        List<Site_Role__c>siteRoles = [SELECT Id, Meter__c, Meter__r.Name, Contact__c, Active__c FROM Site_Role__c WHERE Role__c INCLUDES ('Customer Portal') AND Contact__r.Sandbox_Migration_Id__c = 'testBruno'];
        Site_Role__c activeSiteRole = new Site_Role__c(
                Contact__c = siteRoles[0].Contact__c,
                Role__c = 'Customer Portal',
                Meter__c = siteRoles[0].Meter__c,
                Start_Date__c = Date.today() - 1,
                End_Date__c = Date.today() + 1
        );
        insert activeSiteRole;
        activeSiteRole = [SELECT Id, Meter__c, Meter__r.Name, Contact__c, Active__c FROM Site_Role__c WHERE Id = :activeSiteRole.Id];
        siteRoles.add(activeSiteRole);

        System.runAs(user) {
            msUserManagementController.saveSettings(JSON.serialize(contractRoles), JSON.serialize(siteRoles));
        }
        System.runAs(user) {
            msUserManagementController.saveSettings(JSON.serialize(contractRoles), JSON.serialize(siteRoles));
        }
        List<Contract_Role__c> savedContractRoles = [SELECT Id, Contact__r.Name FROM Contract_Role__c WHERE Contact__c = :user.ContactId];
        List<Site_Role__c> savedSiteRoles = [SELECT Id, Contact__r.Name FROM Site_Role__c WHERE Contact__c = :user.ContactId];
        Test.stopTest();
        System.assert((JSON.serialize(savedContractRoles)).contains('Contract_Role__c') || (JSON.serialize(savedSiteRoles)).contains('Site_Role__c'));
    }
    @IsTest
    public static void testDeclineUserRequest() {
        Test.startTest();
        insertContactHelper();
        msUserManagementApprovalController.ApprovalWrapper approvalWrapper = msUserManagementApprovalController.getApprovalRequests(MARKET);
        msUserManagementApprovalController.declineUserRequest(approvalWrapper.userWrappers[0].contact.Id, MARKET);
        List<Site_Role__c> siteRolesToDelete = [SELECT Id FROM Site_Role__c WHERE Contact__c = :approvalWrapper.userWrappers[0].contact.Id AND msAwaitingPortalActivation__c = TRUE];
        List<Contract_Role__c> contractRolesToDelete = [SELECT Id FROM Contract_Role__c WHERE Contact__c = :approvalWrapper.userWrappers[0].contact.Id AND msAwaitingPortalActivation__c = TRUE];
        Test.stopTest();
        System.assert(siteRolesToDelete.isEmpty());
        System.assert(contractRolesToDelete.isEmpty());
    }
    @IsTest
    public static void testApproveUserRequest() {
        Test.startTest();
        insertContactHelper();
        msUserManagementApprovalController.ApprovalWrapper approvalWrapper = msUserManagementApprovalController.getApprovalRequests(MARKET);
        msUserManagementApprovalController.UserWrapper finalWrapper = null;
        for (msUserManagementApprovalController.UserWrapper tempWrapper : approvalWrapper.userWrappers) {
            if (tempWrapper.user == null) {
                msUserManagementApprovalController.approveUserRequest(tempWrapper.contact.Id, 'testApproveUserRequest@msUsermanagementTest.de', MARKET);
                finalWrapper = tempWrapper;
                break;
            }
        }
        Contact newContact = [
                SELECT Id, Name, FirstName, LastName, Email, MailingCountry, msAwaitingPortalActivation__c, msPortalRequestBy__c
                FROM Contact
                WHERE Id = :finalWrapper.contact.Id
        ];
        List<User> createdUsers = [SELECT Id FROM User WHERE Contact.Id = :newContact.Id];
        Test.stopTest();
        System.assert(!createdUsers.isEmpty());
    }

    @IsTest
    public static void testDeleteAccess() {
        User user = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];


        Test.startTest();
        System.runAs(user) {
            msUserManagementController.deleteRelationshipToContact(JSON.serialize(new Contact(Id = testUser.ContactId)));
        }
        Test.stopTest();
        Contact contactToRemove = [SELECT msAwaitingPortalActivation__c, msPortalRequestBy__c FROM Contact WHERE Id = :testUser.ContactId];

        System.assert(!contactToRemove.msAwaitingPortalActivation__c && contactToRemove.msPortalRequestBy__c == null);
    }

    @IsTest
    public static void testReassignContact() {
        User user = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Contact testContact = new Contact();
        testContact.FirstName = 'Bruno';
        testContact.LastName = 'Brown';
        testContact.Salutation = 'Mr.';
        testContact.AccountId = [SELECT Id FROM Account LIMIT 1].Id;
        testContact.Email = 'test@example.de';
        insert testContact;

        Contract_Role__c testContractRole = [SELECT Id, Start_Date__c, End_Date__c, Contact__c, Contact__r.AccountId, Contract__c FROM Contract_Role__c WHERE Contact__c != :user.ContactId LIMIT 1];
        Contract_Role__c testContractRole2 = new Contract_Role__c();
        testContractRole2.Start_Date__c = testContractRole.Start_Date__c;
        testContractRole2.Contract__c = testContractRole.Contract__c;
        testContractRole2.Contact__c = testContact.Id;
        testContractRole2.msAwaitingPortalActivation__c = true;
        insert testContractRole2;

        Site_Role__c testSiteRole = [SELECT Id, Start_Date__c, End_Date__c, Contact__c, Meter__c FROM Site_Role__c WHERE Contact__c != :user.ContactId LIMIT 1];
        Site_Role__c testSiteRole2 = new Site_Role__c();
        testSiteRole2.Start_Date__c = testSiteRole.Start_Date__c;
        testSiteRole2.Meter__c = testSiteRole.Meter__c;
        testSiteRole2.Contact__c = testContact.Id;
        testSiteRole2.msAwaitingPortalActivation__c = true;
        insert testSiteRole2;

        Test.startTest();
        msUserManagementApprovalController.reassignContactToRoles(testContact.Id, user.ContactId, MARKET);
        Test.stopTest();
        List<Contract_Role__c> oldContactContractRoles = [SELECT Id FROM Contract_Role__c WHERE Contact__c = :testContact.Id];
        List<Site_Role__c> oldContactSiteRoles = [SELECT Id FROM Site_Role__c WHERE Contact__c = :testContact.Id];

        System.assert(oldContactContractRoles.isEmpty() && oldContactSiteRoles.isEmpty());

        List<Contract_Role__c> newContactContractRoles = [SELECT Id FROM Contract_Role__c WHERE Contact__c = :user.ContactId];
        List<Site_Role__c> newContactSiteRoles = [SELECT Id FROM Site_Role__c WHERE Contact__c = :user.ContactId];

        System.assert(!newContactContractRoles.isEmpty() && !newContactSiteRoles.isEmpty());
    }

    @IsTest
    public static void testDeactivateUsers() {
        Map<Id, User> users = new Map<Id, User>([SELECT Id, IsActive FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal']);
        List<Id> userIdList = new List<Id>(users.keySet());
        String userIds = System.JSON.serialize(userIdList);
        Test.startTest();
        msUserManagementApprovalController.deactivateUsers(userIds, MARKET);
        Test.stopTest();
        List<User> deactivatedUsers = [SELECT Id, IsActive FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        for (User deactivatedUser : deactivatedUsers) {
            System.assertEquals(false, deactivatedUser.IsActive);
        }

    }

    @IsTest
    private static void testUserManagementApprovalInitial() {
        Test.startTest();
        String market = msUserManagementApprovalController.getInitialApprovalRequests();
        Test.stopTest();
        System.assertEquals('Germany', market, 'We expect Admins to be defaulted to Germany');
    }

    private static void insertContactHelper() {
        User user = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        List<Contract_Role__c> testContractRoles = new List<Contract_Role__c>();
        List<Site_Role__c> testSiteRoles = new List<Site_Role__c>();


        Contract_Role__c testContractRole = [SELECT Id, Start_Date__c, End_Date__c, Contact__c, Contact__r.AccountId, Contract__c FROM Contract_Role__c WHERE Contact__c = :user.ContactId LIMIT 1];
        Contract_Role__c testContractRole2 = new Contract_Role__c();
        testContractRole2.Start_Date__c = testContractRole.Start_Date__c;
        testContractRole2.End_Date__c = testContractRole.End_Date__c;
        testContractRole2.Contract__c = testContractRole.Contract__c;
        testContractRoles.add(testContractRole2);

        Site_Role__c testSiteRole = [SELECT Id, Start_Date__c, End_Date__c, Contact__c, Meter__c FROM Site_Role__c WHERE Contact__c = :user.ContactId LIMIT 1];
        Site_Role__c testSiteRole2 = new Site_Role__c();
        testSiteRole2.Start_Date__c = testSiteRole.Start_Date__c;
        testSiteRole2.End_Date__c = testSiteRole.End_Date__c;
        testSiteRole2.Meter__c = testSiteRole.Meter__c;
        testSiteRoles.add(testSiteRole2);

        Contact testContact = new Contact();
        testContact.FirstName = 'Brauno';
        testContact.LastName = 'Bruhn';
        testContact.Salutation = 'Mr.';
        testContact.AccountId = testContractRole.Contact__r.AccountId;
        testContact.Email = 'test@example.de';
        testContact.Sandbox_Migration_Id__c = 'testBrauno';

        Contact duplicateContact = new Contact();
        duplicateContact.FirstName = 'Bruno';
        duplicateContact.LastName = 'Brown';
        duplicateContact.Salutation = 'Mr.';
        duplicateContact.Email = 'test@example.de';
        testContact.Sandbox_Migration_Id__c = 'testBruno';


        System.runAs(user) {
            System.debug(msUserManagementController.insertContact(JSON.serialize(testContact), JSON.serialize(testContractRoles), JSON.serialize(testSiteRoles)));
            System.debug(msUserManagementController.insertContact(JSON.serialize(duplicateContact), JSON.serialize(testContractRoles), JSON.serialize(testSiteRoles)));
        }

    }

}