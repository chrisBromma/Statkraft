global class msContractSapCheckboxesBatch implements Database.Batchable<SObject> {

    global List<Account> start(Database.BatchableContext bc) {
        return [SELECT Id, (SELECT Id FROM Contracts__r) FROM Account];
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        Set<Id> accIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        for(Account acc : scope) {
            accIds.add(acc.Id);
            for(Contract__c c : acc.Contracts__r) {
                contractIds.add(c.Id);
            }
        }
        msContractSapCheckboxesHelper helper = new msContractSapCheckboxesHelper(accIds, contractIds);
        helper.execute();
    }

    global void finish(Database.BatchableContext bc) {
    }

}