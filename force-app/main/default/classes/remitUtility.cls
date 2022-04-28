/****************************************************************************************************
 * Class remitUtility
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2022-01-20
 *   Description	:	Remit relevant Utility methods
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------                 
 *   * Christian Gottlieb (mindsquare AG)	                2022-01-20       	Init version.
*****************************************************************************************************/

public without sharing class remitUtility {

    /**
     * @description The method determines the current Remit Relevant status for the given Contract Ids and will
     *              update the Contracts accordingly in the database. Centralized here since the determination is
     *              dependent on multiple objects and the records changing have to enforce recalculation
     *
     *              The Remit Relevant flag on Contract__c is a major node and will trigger Case generation and
     *              at one point the entire Remit Reporting status entries in SF will have to be calculated.
     *              Only call this from synchronous context if it is the only action you perform, otherwise stick to
     *              asynchronous context like asynchronous triggers, scheduled apex, etc. be careful not to call
     *              a future here, otherwise this will have issues at runtime.
     *
     * @param contractIds Set of Contract Ids to determine Remit relevancy for
     */
    public static void determineRemitRelevancyAndUpdateContracts(Set<Id> contractIds) {

        if (contractIds != null && !contractIds.isEmpty()) {
            List<Contract__c> contractsToCheck = getContracts(contractIds);
            ListMapContainer contractIdToMeterRegs = getMeterRegistrations(contractIds);

            Map<Id, Contract__c> contractUpdates = new Map<Id, Contract__c>();
            for (Contract__c contractToCheck : contractsToCheck) {
                Boolean initialState = contractToCheck.REMIT_Reporting_Relevant__c;
                List<MeterRegistration__c> connectedMeterRegistrations = contractIdToMeterRegs.get(contractToCheck.Id);
                Boolean resultingState = contractIsRemitRelevant(contractToCheck, connectedMeterRegistrations);
                //Only German Contracts are currently allowed to uncheck their state again during automation
                if (initialState != resultingState
                        && (contractToCheck.Country__c == 'Germany'
                        || !initialState)) {
                    contractToCheck.REMIT_Reporting_Relevant__c = resultingState;
                    contractUpdates.put(contractToCheck.Id, contractToCheck);
                }
            }

            if (!contractUpdates.isEmpty()) {
                update contractUpdates.values();
                for (Contract__c contractToLog : contractUpdates.values()) {
                    //TODO: This needs to be categorized in the future
                    Logger.info('Remit Relevancy was switched to ' + contractToLog.REMIT_Reporting_Relevant__c, contractToLog);
                }
                Logger.saveLog();
            }
        }
    }

    private static List<Contract__c> getContracts(Set<Id> contractIds) {
        return [
                SELECT
                        Id,
                        REMIT_Reporting_Relevant__c,
                        Contract_Type_New__c,
                        Product_Type_New__c,
                        Contracted_Capacity__c,
                        Active_Installed_Capacity__c,
                        Legal_Capacity__c,
                        Country__c,
                        Third_Party_Contract__c,
                        Contract_Holder__r.SK_Group_Member__c,
                        Contract_Type__c,
                        Status__c,
                        Start_Date__c
                FROM Contract__c
                WHERE Id IN :contractIds
        ];
    }

    private static ListMapContainer getMeterRegistrations(Set<Id> contractIds) {

        ListMapContainer result = new ListMapContainer(MeterRegistration__c.SObjectType);

        List<MeterRegistration__c> meterRegList = [
                SELECT Id, Status__c, Contract__c, Meter__r.Status__c
                FROM MeterRegistration__c
                WHERE Contract__c IN :contractIds
                AND (Valid_to__c = NULL OR Valid_to__c >= TODAY)
        ];
        for (MeterRegistration__c regItem : meterRegList) {
            result.addToMap(regItem.Contract__c, regItem);
        }
        return result;
    }

    /**
     * @description Definition of Remit Relevancy, don't expose this since the required fields might change
     *
     * @param contractToCheck Contract to determine the Remit status for
     * @param connectedRegistrations all current Meter Registerations of the Contract including their fields on Meter
     *
     * @return determined value for Remit Relevancy. Is not updated on the supplied Contract record yet (Call by Reference)
     */
    private static Boolean contractIsRemitRelevant(Contract__c contractToCheck, List<MeterRegistration__c> connectedRegistrations) {
        Boolean result = false;
        Boolean allMetersActive = hasOnlyActiveMeters(connectedRegistrations);
        //Group Company Accounts are never relevant.
        if (!contractToCheck.Contract_Holder__r.SK_Group_Member__c) {
            //French Capacity Contracts are excluded
            if (!(contractToCheck.Country__c == 'France'
                    && (contractToCheck.Contract_Type__c == 'Capacity Guarantees Contract'
                    || (contractToCheck.Contract_Type_New__c == 'Certificates'
                    && contractToCheck.Product_Type_New__c == 'Capacity Guarantees (FR)')))) {
                //India, Flex Contracts and WL subcontracts are never relevant
                if (contractToCheck.Product_Type_New__c != 'Flex Optimization GB'
                        && contractToCheck.Product_Type_New__c != 'Flex Co-location GB'
                        && contractToCheck.Product_Type_New__c != 'Flex Optimization IRE'
                        && contractToCheck.Product_Type_New__c != 'Flex Optimization NI'
                        && contractToCheck.Country__c != 'India'
                        && !(contractToCheck.Contract_Type_New__c == 'Sub-Contract'
                        && (contractToCheck.Product_Type_New__c == 'White Label'
                        || contractToCheck.Product_Type_New__c == 'White Label U20 Spot Indexed'
                        || contractToCheck.Product_Type_New__c == 'White Label U20 Ref.MV Indexed'))) {
                    //Third Party Contracts are otherwise always relevant
                    if (contractToCheck.Third_Party_Contract__c) {
                        result = true;
                        //WL Frame Contracts are otherwise always relevant
                    } else if ((contractToCheck.Product_Type_New__c == 'White label'
                            || contractToCheck.Product_Type_New__c == 'White Label U20 Spot Indexed'
                            || contractToCheck.Product_Type_New__c == 'White Label U20 Ref.MV Indexed')
                            && contractToCheck.Contract_Type_New__c == 'Framework Agreement') {
                        result = true;
                        //Germany has a bit different logic, here the Capacity and Meter Activation comes into account
                    } else if (contractToCheck.Country__c != 'Germany'
                            && (contractToCheck.Legal_Capacity__c > 10
                            || contractToCheck.Contracted_Capacity__c > 10)) {
                        result = true;
                    } else if (contractToCheck.Country__c == 'Germany') {
                        if (contractToCheck.Start_Date__c > Date.today()
                                && contractToCheck.Legal_Capacity__c > 10) {
                            result = true;
                        }
                        if (!allMetersActive &&
                                contractToCheck.Start_Date__c <= Date.today()
                                && contractToCheck.Legal_Capacity__c > 10) {
                            result = true;
                        }
                        if (allMetersActive &&
                                contractToCheck.Start_Date__c <= Date.today()
                                && contractToCheck.Active_Installed_Capacity__c > 10) {
                            result = true;
                        }
                    }
                }
            }
        }
        return result;
    }

    private static Boolean hasOnlyActiveMeters(List<MeterRegistration__c> connectedMeterRegistrations) {
        Boolean result = false;
        for (MeterRegistration__c regItem : connectedMeterRegistrations) {
            if (regItem.Meter__r.Status__c == 'Planned'
                    || regItem.Meter__r.Status__c == 'Under Construction') {
                result = false;
                break;
            } else {
                result = true;
            }
        }
        return result;
    }
}