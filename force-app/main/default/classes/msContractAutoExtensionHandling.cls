/****************************************************************************************************
     	* Class msContractAutoExtensionHandling
     	*
     	*   Create By	:   Mandy Bebenroth (mindsquare AG)
     	*   Create Date	:   24.09.2020
     	*   Description	:	---
     	*
     	*   Modification Log:
    	*   -------------------------------------------------------------------------------------------------
    	*   * Developer                        	    Date             	Description
    	*   * -----------------------------------------------------------------------------------------------
    	*   * Mandy Bebenroth (mindsquare AG)		24.09.2020       	Init version.
    	*****************************************************************************************************/
public with sharing class msContractAutoExtensionHandling {

    public class ActionInput {
        @InvocableVariable(
                Label = 'Contract Collection for Input'
                Description = 'Needs to be a list of Contract__c records with the Id Field populated'
                Required = true)
        public List<Contract__c> inputCollection;
    }
    public class ActionOutput {
        @InvocableVariable(
                Label = 'Contract count at job start'
                Description = 'Please refer to the Batch Job Listview for detailed results'
                Required = true)
        public Integer numberOfContracts;
    }

    public class FlowCustomException extends Exception {
    }

    @InvocableMethod(Label = 'Contract Auto-Extension Handling')
    public static List<ActionOutput> contractAutoExtensionHandling(List<ActionInput> requests) {
        List<ActionOutput> outputs = new List<ActionOutput>();
        Core_Batch_Settings__mdt settings = getBatchJobsSettings();
        for (ActionInput request : requests) {
            Set<Id> contractIds = new Set<Id>();
            for (Contract__c contractItem : request.inputCollection) {
                contractIds.add(contractItem.Id);
            }
            if (contractIds.size() > 0) {
                Database.executeBatch(new msBatchContractExtension(contractIds), (Integer) settings.Contract_Extension_Batch_Size__c);
            }

            ActionOutput output = new ActionOutput();
            output.numberOfContracts = contractIds.size();
            outputs.add(output);
        }
        return outputs;
    }

    @TestVisible
    private static Core_Batch_Settings__mdt getBatchJobsSettings() {

        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String metaDataName = 'Production';
        if (runningInASandbox) {
            metaDataName = 'PreProd';
        }
        return Core_Batch_Settings__mdt.getInstance(metaDataName);
    }
}