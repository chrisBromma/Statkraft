/****************************************************************************************************
* Class BatchResetContractCongaContext
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-05-11
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-05-11       	Init version.
*****************************************************************************************************/

global without sharing class BatchResetContractCongaContext extends BatchJobBase implements Database.Batchable<SObject>{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
                'SELECT ' +
                'Id, ' +
                'Start_Date__c, ' +
                'End_Date__c, ' +
                'Start_for_Conga_Context__c, ' +
                'End_for_Conga_Context__c, ' +
                'Last_Amentment__c, ' +
                'Last_Amentment__r.Amendment_Start__c, ' +
                'Last_Amentment__r.Amendment_End__c ' +
                'FROM Contract__c ' +
                'WHERE Conga_Context_requires_Update__c = TRUE');
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Contract__c> updateList = calculateUpdates((List<Contract__c>) scope);
        if(!updateList.isEmpty()) {
            Database.update(updateList, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        super.finishBatch(bc.getJobId());
    }

    public static List<Contract__c> calculateUpdates(Set<Id> scope) {
       return calculateUpdates(queryScope(scope));
    }

    public static Contract__c determineCongaContext(Contract__c contractItem) {
        Contract__c result = null;
        Date congaStart = contractItem.Start_Date__c;
        Date congaEnd = contractItem.End_Date__c;
        if(contractItem.Last_Amentment__c != null) {
            if(contractItem.Last_Amentment__r.Amendment_Start__c != null) {
                congaStart = contractItem.Last_Amentment__r.Amendment_Start__c;
            }
            if(contractItem.Last_Amentment__r.Amendment_End__c != null) {
                congaEnd = contractItem.Last_Amentment__r.Amendment_End__c;
            }
        }

        if(contractItem.Start_for_Conga_Context__c != congaStart
                || contractItem.End_for_Conga_Context__c != congaEnd) {
            contractItem.Start_for_Conga_Context__c = congaStart;
            contractItem.End_for_Conga_Context__c = congaEnd;
            result = contractItem;
        }
        return result;
    }

    private static List<Contract__c> calculateUpdates(List<Contract__c> scope) {
        List<Contract__c> updateList = new List<Contract__c>();
        for(Contract__c item : scope) {
            Contract__c result = determineCongaContext(item);
            if(result != null) {
                updateList.add(result);
            }
        }
        return updateList;
    }

    private static List<Contract__c> queryScope(Set<Id> scope) {
        return [
                SELECT Id,
                        Start_Date__c,
                        End_Date__c,
                        Start_for_Conga_Context__c,
                        End_for_Conga_Context__c,
                        Last_Amentment__c,
                        Last_Amentment__r.Amendment_Start__c,
                        Last_Amentment__r.Amendment_End__c
                FROM Contract__c
                WHERE Id IN : scope
        ];
    }
}