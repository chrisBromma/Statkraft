/****************************************************************************************************
* Class msFRContractDatesFlowController
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-08-01
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)	            2019-08-01       	Init version.
*****************************************************************************************************/

public without sharing class msFRContractDatesFlowController {
    @AuraEnabled
    public static Boolean getStatusOk(Id contractId) {
        Contract__c contract = [SELECT Status__c FROM Contract__c WHERE Id =:contractId LIMIT 1];
        Boolean ok = false;
        if(contract.Status__c == 'Active' || contract.Status__c == 'Draft') {
            ok = true;
        }
        return ok;
    }
    @AuraEnabled
    public static List<String> getOptions(Id contractId){
        Contract__c contract = [SELECT Id, Commissioning_Status__c FROM Contract__c WHERE Id=:contractId LIMIT 1];
        List<String> options = new List<String>();
        if(     contract.Commissioning_Status__c == ''
                || contract.Commissioning_Status__c == null
                || contract.Commissioning_Status__c == 'Not yet Commissioning'
                || contract.Commissioning_Status__c == 'Commissioning date confirmed'
                || contract.Commissioning_Status__c == 'Commercial operations date confirmed') {
            options.add('Estimated Commissioning Date');
            options.add('Confirmed Commissioning Date');
            options.add('Estimated Commercial Operations Date');
            options.add('Confirmed Commercial Operations Date');
        }
        return options;
    }

    @AuraEnabled
    public static void handleInput(Id contractId, Date enteredDate, String enteredChoice){
        Contract__c contract = [
                SELECT Id,
                        DurationYears__c,
                        Start_Date__c,
                        End_Date__c,
                        DurationMonths__c,
                        Status__c,
                        Commercial_Operations_Date__c,
                        Commissioning_Date__c
                FROM Contract__c WHERE Id =:contractId LIMIT 1
        ];
        List<Pricing_Component__c> connectedPCs = [SELECT Id, Index_Price__c, Start_Date__c, End_Date__c FROM Pricing_Component__c WHERE Contract__c =: contractId];
        //among other checks:
        Integer countOfM0PCs = 0;
        for(Pricing_Component__c pcItem : connectedPCs) {
            if(pcItem.Index_Price__c == 'Monthly M0'
                    || pcItem.Index_Price__c == 'Monthly M0 Wind'
                    || pcItem.Index_Price__c == 'Monthly M0 Solar'
                    || pcItem.Index_Price__c == 'Yearly M0') {
                countOfM0PCs +=1;
            }
        }
        if(countOfM0PCs > 1) {
            connectedPCs = new List<Pricing_Component__c>();
        }
        if(enteredDate != null && (contract.Status__c == 'Active' || contract.Status__c == 'Draft')) {
            switch on enteredChoice {
                when 'Estimated Commissioning Date' {
                    handleCommissioningDate(contract, connectedPCs, enteredDate);
                    contract.Commissioning_Status__c = 'Not yet Commissioning';
                }
                when 'Confirmed Commissioning Date' {
                    handleCommissioningDate(contract, connectedPCs, enteredDate);
                    contract.Commissioning_Status__c = 'Commissioning date confirmed';
                }
                when 'Estimated Commercial Operations Date' {
                    handleCommercialDate(contract,connectedPCs,enteredDate);
                }
                when 'Confirmed Commercial Operations Date' {
                    handleCommercialDate(contract,connectedPCs,enteredDate);
                    contract.Commissioning_Status__c = 'Commercial operations date confirmed';
                }
            }
            Boolean lockedStatus = Approval.isLocked(contractId);
            if(lockedStatus) {
                Approval.unlock(contractId);
            }
            update contract;
            if(countOfM0PCs <= 1) {
                update connectedPCs;
            }
            if(lockedStatus) {
                Approval.lock(contractId);
            }
        }
    }
    private static void handleCommissioningDate(Contract__c contract, List<Pricing_Component__c> connectedPCs, Date enteredDate){
        contract.Commissioning_Date__c = enteredDate;
        if(contract.Commercial_Operations_Date__c != null && contract.Commercial_Operations_Date__c <= contract.Commissioning_Date__c ) {
            contract.Commercial_Operations_Date__c = null;
        }
        for(Pricing_Component__c pcItem : connectedPCs) {
            if(pcItem.Index_Price__c == 'SSP') {
                pcItem.Start_Date__c = enteredDate;
                if(pcItem.End_Date__c < pcItem.Start_Date__c) {
                    pcItem.End_Date__c = enteredDate;
                }
            }
        }
    }
    private static void handleCommercialDate(Contract__c contract, List<Pricing_Component__c> connectedPCs, Date enteredDate){
        contract.Commercial_Operations_Date__c = enteredDate;
        if(contract.DurationYears__c + contract.DurationMonths__c > 0) {
            contract.End_Date__c = enteredDate.addYears((Integer) contract.DurationYears__c).addMonths((Integer) contract.DurationMonths__c).toStartOfMonth().addDays(-1);
        }
        for(Pricing_Component__c pcItem : connectedPCs) {
            if(pcItem.Index_Price__c == 'SSP') {
                pcItem.End_Date__c = enteredDate.addDays(-1);
                if(pcItem.End_Date__c < pcItem.Start_Date__c) {
                    pcItem.Start_Date__c = pcItem.End_Date__c;
                }
            } else {
                pcItem.Start_Date__c = enteredDate;
                pcItem.End_Date__c = contract.End_Date__c;
            }
        }
    }
}