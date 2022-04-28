@isTest(SeeAllData=true)
public class RHX_TEST_Implementation {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Implementation__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Implementation__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}