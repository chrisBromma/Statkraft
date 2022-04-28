public class msAccountRoleHelper {
    
    public static List<Account_Role__c> insertAccountRolesFromParentOnChildAccounts(List<Account_Role__c> newAccountRolesFromTrigger) {
        
        Set<Id> childAccIds = new Set<Id>();
        for (Account_Role__c accRole : newAccountRolesFromTrigger) {
            childAccIds.add(accRole.Account__c);
        }
        List<Account> childAccs = [select Id, (select Id from Account_Roles__r) from Account where ParentId in :childAccIds];
        for (Account childAcc : childAccs) {
            for (Account_Role__c accRole : childAcc.Account_Roles__r) {
                
            }
        }
        
        return new List<Account_Role__c>();
    }
    
}