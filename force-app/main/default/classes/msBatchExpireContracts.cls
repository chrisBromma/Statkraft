/****************************************************************************************************
     	* Class msBatchExpireContracts
     	*
     	*   Create By	:   Mandy Bebenroth (mindsquare AG)
     	*   Create Date	:   01.07.2020
     	*   Description	:	---
     	*
     	*   Modification Log:
    	*   -------------------------------------------------------------------------------------------------
    	*   * Developer                        	    Date             	Description
    	*   * -----------------------------------------------------------------------------------------------
    	*   * Mandy Bebenroth (mindsquare AG)		01.07.2020       	Init version.
    	*****************************************************************************************************/
global class msBatchExpireContracts extends BatchJobBase implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {
    global msBatchExpireContracts(){}

    global List<Contract__c> start(Database.BatchableContext bc) {
        super.startLogging(BC?.getJobId());
        List<Contract__c> globalScope = [
                SELECT Id, End_Date__c
                FROM Contract__c
                WHERE End_Date__c < TODAY
                AND Status__c = 'Active'
        ];
        return globalScope;
    }

    global void execute(Database.BatchableContext bc, List<Contract__c> contractList) {
        super.logInformation(contractList, bc?.getJobId(), 'Found ' + contractList.size() + ' records.');
        for (Contract__c con : contractList) {
            con.Status__c = 'Expired';
        }
        update contractList;
        super.logEndOfBatch(contractList, bc?.getJobId(), true, 'Finished processing.');
    }

    global void finish(Database.BatchableContext bc) {
        //Dependencies can be handled by Framework.
        super.finishBatch(bc.getJobId());
    }
}