/**
 * @TestClassFor SandboxMigrationIdGenerator 
 * @author            : Dennis Grzyb
 * @group             : 
 * @last modified on  : 2021-04-14
 * @last modified by  : Dennis Grzyb
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   2021-04-14   Dennis Grzyb   Initial Version
**/

@IsTest
public with sharing class SandboxMigrationIdGeneratorTest {

    @IsTest
    static void runTestWithNoSettingInserted() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        List<Account> accounts = msGranularTestDataFactory.createTestAccounts(1, 'Germany', Application.RecordTypes.byDeveloperName('Account', 'Account').Id);
        Account singleAcc = accounts[0];
        insert singleAcc;

        Test.startTest();
        SandboxMigrationIdGenerator.populate(new List<Account>{
                singleAcc
        }, true);
        Test.stopTest();

        System.assert(SandboxMigrationSettings__c.getInstance('Account') != null);
        System.assertEquals('ACC_', SandboxMigrationSettings__c.getInstance('Account').Prefix__c);
        System.assertEquals(1, Integer.valueOf(SandboxMigrationSettings__c.getInstance('Account').RunningNumber__c));
    }

    @IsTest
    static void runTestWithExistingSetting() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);

        SandboxMigrationSettings__c setting = new SandboxMigrationSettings__c(Name = 'Account', Prefix__c = 'ACCT_', RunningNumber__c = 5);
        insert setting;

        List<Account> accounts = msGranularTestDataFactory.createTestAccounts(1, 'Germany', Application.RecordTypes.byDeveloperName('Account', 'Account').Id);
        Account singleAcc = accounts[0];
        insert singleAcc;

        Test.startTest();
        SandboxMigrationIdGenerator.populate(new List<Account>{
                singleAcc
        }, true);
        Test.stopTest();

        System.assert(SandboxMigrationSettings__c.getInstance('Account') != null);
        System.assertEquals('ACCT_', SandboxMigrationSettings__c.getInstance('Account').Prefix__c);
        System.assertEquals(6, Integer.valueOf(SandboxMigrationSettings__c.getInstance('Account').RunningNumber__c));
    }

    @IsTest
    static void testExceptionForUntypedPopulateCall() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        List<Account> accounts = msGranularTestDataFactory.createTestAccounts(1, 'Germany', Application.RecordTypes.byDeveloperName('Account', 'Account').Id);
        Account singleAcc = accounts[0];
        insert singleAcc;

        Exception ex;
        Test.startTest();
        try {
            SandboxMigrationIdGenerator.populate(new List<SObject>{
                    singleAcc
            }, true);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();

        System.assert(ex != null);
        System.assert(ex.getMessage().contains('not specified'));
    }
}