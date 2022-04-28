@isTest(SeeAllData=true)
private class skContractNumberingTEST {
    static testmethod void testgetLatestContractId() {
        
		contract__c FrenchTestContract = new contract__c();
        
		FrenchTestContract.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract PPA').getRecordTypeId();
        //FrenchTestContract.Contract_Holder__c = [SELECT Id FROM Account LIMIT 1].Id;
        FrenchTestContract.Name = 'French Test Contract 7523';
        FrenchTestContract.Start_Date__c = system.today();
		FrenchTestContract.End_Date__c = system.today().addDays(7); 
        FrenchTestContract.Country__c = 'France';
        insert FrenchTestContract;
        
        system.debug(FrenchTestContract.Statkraft_Contract_Id__c);
        //system.assert(FrenchTestContract.Statkraft_Contract_Id__c != Null);
        
		contract__c DETestContract = new contract__c();
		DETestContract.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract PPA').getRecordTypeId();
        //DETestContract.Contract_Holder__c = [SELECT Id FROM Account LIMIT 1].Id;
        DETestContract.Name = 'German Test Contract 1448';
        DETestContract.Start_Date__c = system.today();
		DETestContract.End_Date__c = system.today().addDays(7); 
        DETestContract.Country__c = 'Germany';
        insert DETestContract;        
        
        system.debug(FrenchTestContract.Statkraft_Contract_Id__c);
        //system.assert(DETestContract.Statkraft_Contract_Id__c == '');
    }
}