@isTest(seeAllData='true')
public class msAccountRoleHelperTEST {
    static testmethod void testinsertAccountRolesFromParentOnChildAccounts() {
        list<Account_Role__c> arl = new list<Account_Role__c>();
        
        msAccountRoleHelper.insertAccountRolesFromParentOnChildAccounts(arl);
    }
}