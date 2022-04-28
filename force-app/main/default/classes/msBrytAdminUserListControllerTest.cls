/****************************************************************************************************
* Class msBrytAdminUserListControllerTest
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2020-01-16
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2020-01-16       	Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msBrytAdminUserListControllerTest {
    @TestSetup
    public static void testSetup(){
        msBrytTestDataFactory.createTestRecords();
        List<Contract__c> allContracts = [SELECT Id, Start_Date__c, End_Date__c FROM Contract__c];
        List<Contract_Role__c> allContractRoles = [SELECT Id, Start_Date__c, End_Date__c, Bryt_isUserAdmin__c FROM Contract_Role__c];
        for(Contract__c contractItem : allContracts){
            contractItem.Start_Date__c = Date.today();
            contractItem.End_Date__c = Date.today();
        }
        update allContracts;
        for(Contract_Role__c roleItem : allContractRoles){
            roleItem.Start_Date__c = Date.today();
            roleItem.End_Date__c = Date.today();
            roleItem.Bryt_isUserAdmin__c = true;
        }
        update allContractRoles;
    }
    @IsTest
    public static void freezeCommunityUserTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        User subjectUser = [SELECT Id, Name FROM User WHERE Username = 'testuser2@statkraft.mindsquare.user.dev' LIMIT 1];
        UserLogin subjectUserLogin = [SELECT Id, UserId FROM UserLogin WHERE UserId =:subjectUser.Id LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.freezeCommunityUser(subjectUserLogin.UserId);
            Test.stopTest();
        }
    }
    @IsTest
    public static void unfreezeCommunityUserTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        User subjectUser = [SELECT Id, Name FROM User WHERE Username = 'testuser2@statkraft.mindsquare.user.dev' LIMIT 1];
        UserLogin subjectUserLogin= [SELECT Id, UserId FROM UserLogin WHERE UserId =:subjectUser.Id LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.unfreezeCommunityUser(subjectUserLogin.UserId);
            Test.stopTest();
        }
    }
    @IsTest
    public static void getContactsTest(){
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.getNewContact();
            Test.stopTest();
        }
    }
    @IsTest
    public static void insertCommunityContactTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        Id ContractRecId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
        Contract__c testContract = [SELECT Id FROM Contract__c WHERE RecordTypeId = :ContractRecId LIMIT 1];
        System.runAs(testUser){
            Contact testContact = new Contact();
            testContact.LastName = 'mindsquaretestusercereatedinunit';
            testContact.Email = 'fake@email.testcreation';
            Contract_Role__c role = new Contract_Role__c();
            role.Contract__c = testContract.Id;
            Test.startTest();
            msBrytAdminUserListController.insertCommunityContact(testContact, role);
            Test.stopTest();
        }
    }
    @IsTest
    public static void resetCommunityUserPasswordTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        User subjectUser = [SELECT Id, Name FROM User WHERE Username = 'testuser2@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.resetCommunityUserPassword(subjectUser.Id);
            Test.stopTest();
        }
    }
    @IsTest
    public static void updateContractRoleTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        Id contractRoleRecordTypeId = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
        Contract_Role__c contractRole = [SELECT Id,Bryt_isTradingEnabled__c,Bryt_isTPI__c FROM Contract_Role__c WHERE Role__c = 'Customer Portal' AND RecordTypeId =:contractRoleRecordTypeId LIMIT 1];
        String role_as_string = '{"Id":"'+contractRole.Id+'","Bryt_isTradingEnabled__c":true,"Bryt_isTPI__c":false}';
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.updateContractRole(role_as_string);
            Test.stopTest();
            Contract_Role__c role = [SELECT Id, Bryt_isTradingEnabled__c, Bryt_isTPI__c FROM Contract_Role__c WHERE Id =:contractRole.Id ];
            System.assertEquals(true, role.Bryt_isTradingEnabled__c);
        }

    }

    @IsTest
    public static void getBrytAccountsTest(){
        User testUser = [SELECT Id, Contact.AccountId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.getBrytAccounts();
            Test.stopTest();
        }
    }

    @IsTest
    public static void updateDuplicatedContractRoleTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        Id contractRoleRecordTypeId = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
        Contract_Role__c contractRole = [SELECT Id,Bryt_isTradingEnabled__c,Bryt_isTPI__c,Contract__c,Contact__c FROM Contract_Role__c WHERE Role__c = 'Customer Portal' AND RecordTypeId =:contractRoleRecordTypeId LIMIT 1];
        String role_as_string = '{"Bryt_isTradingEnabled__c":true,"Bryt_isTPI__c":false,"Contact__c":"'+contractRole.Contact__c +'", "Contract__c":"'+contractRole.Contract__c+'" }';
        System.runAs(testUser){
            Test.startTest();
            try{
                msBrytAdminUserListController.updateContractRole(role_as_string);
            } catch (AuraHandledException e){
                System.assertNotEquals(null, e.getMessage(), 'Error message should be thrown');
            }
            Test.stopTest();
        }
    }

    @IsTest
    public static void updateUserTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        String changedFirstName = 'NewFirstName';
        String changedLastName = 'NewLastName';
        User user_to_update = new User(Id = testUser.Id, FirstName = changedFirstName, LastName = changedLastName);
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.updateUser(user_to_update);
            Test.stopTest();
            User updatedUser = [SELECT Id, FirstName,LastName FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
            System.assertEquals(changedFirstName, updatedUser.FirstName);
            System.assertEquals(changedLastName, updatedUser.LastName);
        }
    }

    @IsTest
    public static void removeContractRoleTest(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev' LIMIT 1];
        Id contractRoleRecordTypeId = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
        Contract_Role__c contractRole = [SELECT Id,Bryt_isTradingEnabled__c,Bryt_isTPI__c FROM Contract_Role__c WHERE Role__c = 'Customer Portal' AND RecordTypeId =:contractRoleRecordTypeId LIMIT 1];
        String role_as_string = '{"Id":"'+contractRole.Id+'","Bryt_isTradingEnabled__c":true,"Bryt_isTPI__c":false}';
        System.runAs(testUser){
            Test.startTest();
            msBrytAdminUserListController.removeContractRole(contractRole.Id);
            Test.stopTest();
            List<Contract_Role__c> role = [SELECT Id FROM Contract_Role__c WHERE Id =:contractRole.Id ];
            System.assertEquals(0, role.size());
        }

    }



}