public with sharing class msKAMsuggestionController {
    @AuraEnabled
    public static List<AccountWrapper> getUnallocatedKeyAccounts() {
        List<Account> unallocatedKeyAccounts = [
                SELECT Name, Customer_Segment_industry__c, Customer_Type__c, Owner.Name, BillingCountry, BillingCountryCode, Comments_from_AMC__c
                FROM Account WHERE KAM_relevant__c = TRUE AND last_KAM_Submitter__c = NULL AND KAM_approved__c = NULL AND KAM_pending__c = FALSE
        ];
        List<AccountWrapper> unallocatedKeyAccountsWrapped = new List<AccountWrapper>();
        for (Account account : unallocatedKeyAccounts) {
            AccountWrapper wrappedAccount = new AccountWrapper(account);
            unallocatedKeyAccountsWrapped.add(wrappedAccount);
        }
        unallocatedKeyAccountsWrapped.sort();

        return unallocatedKeyAccountsWrapped;
    }
    @AuraEnabled
    public static void saveComments(String accountWrapperString){
        List<AccountWrapper>accountWrappers = (List<AccountWrapper>)JSON.deserialize(accountWrapperString, List<AccountWrapper>.class);
        List<Account> accountsToUpdate = new List<Account>();
        for(AccountWrapper accountWrapper : accountWrappers){
            Account acc = new Account(Id=accountWrapper.AccountId, Comments_from_AMC__c=accountWrapper.CommentsFromAMC);
            accountsToUpdate.add(acc);
        }
        update accountsToUpdate;
    }
    @AuraEnabled
    public static String getUserName(String Id){
        List<User> user = [SELECT Name FROM User WHERE Id = :Id LIMIT 1];

        return user[0].name;
    }
    @AuraEnabled
    public static Map<String, List<Object>> getOtherRequestData() {
        Map<String, List<Object>> otherRequestData = msKAMrequestController.getAllRequests();
        return otherRequestData;
    }

    public class AccountWrapper implements Comparable{
        @AuraEnabled 
        public String AccountId {get; set;}
        @AuraEnabled
        public String Accountname {get; set;}
        @AuraEnabled 
        public String CustomerSegment {get; set;}
        @AuraEnabled
        public String CustomerCategory {get; set;}
        @AuraEnabled
        public String CurrentAccountOwner {get; set;}
        @AuraEnabled
        public String BillingCountry {get; set;}
        @AuraEnabled
        public String BillingCountryCode {get; set;}
        @AuraEnabled
        public Boolean ShowFlag {get; set;}
        @AuraEnabled
        public String CommentsFromAMC {get; set;}
       
        public AccountWrapper(Account account) {
            Accountname = account.Name;
            AccountId = account.Id;
            CustomerSegment = account.Customer_Segment_industry__c;
            CustomerCategory = account.Customer_Type__c;
            CurrentAccountOwner = account.Owner.Name;
            BillingCountry = account.BillingCountry;
            BillingCountryCode = account.BillingCountryCode;
            ShowFlag = (KAM_Request_Dashboard_Settings__c.getOrgDefaults().Countries_with_Flags__c.split(';')).contains(account.BillingCountryCode) ? true : false;
            CommentsFromAMC = account.Comments_from_AMC__c;
        }
        public Integer compareTo(Object compareTo){
            AccountWrapper compareToAcc = (AccountWrapper)compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (BillingCountry > compareToAcc.BillingCountry) {
                returnValue = 1;
            } else if (BillingCountry < compareToAcc.BillingCountry) {
                returnValue = -1;
            } else {
                if (Accountname > compareToAcc.Accountname) {
                    returnValue = 1;
                } else if (Accountname < compareToAcc.Accountname) {
                    returnValue = -1;
                }
            }
            return returnValue;
        }
    }
}