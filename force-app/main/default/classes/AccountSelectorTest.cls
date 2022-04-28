@isTest
private class AccountSelectorTest {

    private static final Id AccRecId = msTestDataFactory.DE_ACC_RECORD_TYPE;

    @testSetup static void setup() {
        insert msGranularTestDataFactory.createTestAccounts(1, 'Germany', AccRecId);
    }

    @isTest
    private static void testGetSobjectType() {
        AccountSelector accountSelector = (AccountSelector) Application.Selector.newInstance(Account.SObjectType);
        System.assertEquals('Account', String.valueOf(accountSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        AccountSelector accountSelector = (AccountSelector) Application.Selector.newInstance(Account.SObjectType);
        System.assertEquals(15, accountSelector.getSObjectFieldList().size());
    }
    @isTest
    private static void testSelectByIdList() {
        Account testAccount = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account 0'];
        List<Id> accountIds = new List<Id>();
        accountIds.add(testAccount.Id);
        AccountSelector accountSelector = (AccountSelector) Application.Selector.newInstance(Account.SObjectType);
        System.assertEquals('Test Account 0', accountSelector.selectById(accountIds)[0].Name);      
    }

    @isTest
    private static void testSelectByIdSet() {
        Account testAccount = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account 0'];
        Set<Id> accountIds = new Set<Id>();
        accountIds.add(testAccount.Id);
        AccountSelector accountSelector = (AccountSelector) Application.Selector.newInstance(Account.SObjectType);
        System.assertEquals('Test Account 0', accountSelector.selectById(accountIds)[0].Name);      
    }

    @isTest
    private static void testWithOwnerInfo() {
        Account testAccount = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Test Account 0'];
        Set<Id> accountIds = new Set<Id>();
        accountIds.add(testAccount.Id);
        AccountSelector accountSelector = (AccountSelector) Application.Selector.newInstance(Account.SObjectType);
        accountSelector.withOwnerInfo();
        String ownerId = accountSelector.selectById(accountIds)[0].OwnerId;
        System.assertEquals(false, String.isBlank(ownerId));  
    }

    @isTest
    private static void selectByTaxAndRegistration() {
        AccountSelector accountSelector = (AccountSelector) Application.Selector.newInstance(Account.SObjectType);
        System.assertEquals('Test Account 0', accountSelector.selectByTaxAndRegistration(true, false)[0].Name);  
    }
    
}