public without sharing class msContractSapCheckboxesQueueable implements Queueable {

    private Set<Id> accountIds = new Set<Id>();
    private Set<Id> contractIds = new Set<Id>();

    public msContractSapCheckboxesQueueable(Set<Id> accountIds, Set<Id> contractIds) {
        this.accountIds = accountIds;
        this.contractIds = contractIds;
    }

    public static void enqueueCalculation(msContractSapCheckboxesQueueable checkboxesQueueable) {
        System.enqueueJob(checkboxesQueueable);
    }

    public void execute(QueueableContext context) {
        msContractSapCheckboxesHelper checkboxesHelper = new msContractSapCheckboxesHelper(this.accountIds, this.contractIds);
        checkboxesHelper.execute();
    }
}