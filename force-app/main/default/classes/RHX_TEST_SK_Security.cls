@isTest
public class RHX_TEST_SK_Security {
    
	@isTest static void RHX_Testmethod() {
        SK_Security__c testSKSecurity = new SK_Security__c();
        testSKSecurity.SK_No_End_Date__c = True;
        testSKSecurity.SK_Direction__c = '';
        insert testSKSecurity;
        List<SK_Security__c> sourceList = new List<SK_Security__c>();

        rh2.ParentUtil.UpsertRollupTestRecords(sourceList);
    }
}