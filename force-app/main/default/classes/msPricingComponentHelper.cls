/****************************************************************************************************
* Class msPricingComponentHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-09-29
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-09-29       	Init version.
*****************************************************************************************************/

public without sharing class msPricingComponentHelper {
    public static final Id FLOATING_ENERGY_PRICE_REC_TYPE_ID =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Floating_Energy_Price').getRecordTypeId();
    public static Map<Id, Contract__c> CONTRACT_MAP;

    public static Set<Id> identifyContractsForOverlapOfPricingComponents(
            Boolean isInsert,
            Boolean isUpdate,
            Map<Id, Pricing_Component__c> newMap,
            Map<Id, Pricing_Component__c> oldMap) {

        Set<Id> contractIdsToCheckForRelevance = new Set<Id>();
        if (isInsert) {
            for (Pricing_Component__c pcItem : newMap.values()) {
                if (pcItem.RecordTypeId == FLOATING_ENERGY_PRICE_REC_TYPE_ID) {
                    contractIdsToCheckForRelevance.add(pcItem.Contract__c);
                }
            }
        } else if (isUpdate) {
            for (Pricing_Component__c pcItem : newMap.values()) {
                if (pcItem.RecordTypeId == FLOATING_ENERGY_PRICE_REC_TYPE_ID
                        && (oldMap.get(pcItem.Id).RecordTypeId != pcItem.RecordTypeId)
                        || oldMap.get(pcItem.Id).Start_Date__c != pcItem.Start_Date__c
                        || oldMap.get(pcItem.Id).End_Date__c != pcItem.End_Date__c) {
                    contractIdsToCheckForRelevance.add(pcItem.Contract__c);
                }
            }
        }
        return contractIdsToCheckForRelevance;
    }


    public static Map<Id, List<Pricing_Component__c>> getPricingComponentsToCheckForOverlap(Set<Id> contractIdsToLoad) {
        List<Contract__c> contractsToCheck = [
                SELECT Id, (
                        SELECT Id,
                                Start_Date__c,
                                End_Date__c
                        FROM Pricing_Components__r
                        WHERE RecordTypeId = :FLOATING_ENERGY_PRICE_REC_TYPE_ID
                        ORDER BY Start_Date__c ASC
                )
                FROM Contract__c
                WHERE Id IN :contractIdsToLoad
                AND Country__c = 'Germany'
        ];

        Map<Id, List<Pricing_Component__c>> contractIdToRelevantPCSetMap = new Map<Id, List<Pricing_Component__c>>();

        for (Contract__c contractToCheck : contractsToCheck) {
            if (!contractToCheck.Pricing_Components__r.isEmpty()) {
                contractIdToRelevantPCSetMap.put(contractToCheck.Id, new List<Pricing_Component__c>());
                for (Pricing_Component__c pcItemToCheck : contractToCheck.Pricing_Components__r) {
                    contractIdToRelevantPCSetMap.get(contractToCheck.Id).add(pcItemToCheck);
                }
            }
        }
        return contractIdToRelevantPCSetMap;
    }

    public static Boolean checkPricingComponentForOverlap(
            Pricing_Component__c pcItemToCheck,
            Map<Id, List<Pricing_Component__c>> contractIdToRelevantPCSetMap) {

        List<Pricing_Component__c> pricingComponentsToCheckForOverlap = contractIdToRelevantPCSetMap.get(pcItemToCheck.Contract__c);
        Date latestEndDate = null;
        Boolean foundOverlapForPricingComponent = false;
        for (Integer i = 0; i < pricingComponentsToCheckForOverlap.size(); i++) {
            if (pricingComponentsToCheckForOverlap[i].Id == pcItemToCheck.Id) {
                if (i == 0) {
                    if (pricingComponentsToCheckForOverlap[i].End_Date__c >= pricingComponentsToCheckForOverlap[i + 1].Start_Date__c) {
                        foundOverlapForPricingComponent = true;
                    }
                } else if (i == pricingComponentsToCheckForOverlap.size() - 1) {
                    if (latestEndDate >= pricingComponentsToCheckForOverlap[i].Start_Date__c) {
                        foundOverlapForPricingComponent = true;
                    }
                } else if (latestEndDate >= pricingComponentsToCheckForOverlap[i].Start_Date__c
                        || pricingComponentsToCheckForOverlap[i].End_Date__c >= pricingComponentsToCheckForOverlap[i + 1].Start_Date__c) {
                    foundOverlapForPricingComponent = true;
                }
                break;
            } else if (latestEndDate == null || pricingComponentsToCheckForOverlap[i].End_Date__c > latestEndDate) {
                latestEndDate = pricingComponentsToCheckForOverlap[i].End_Date__c;
            }
        }
        return foundOverlapForPricingComponent;
    }

    public static void calculateMeritOrder(Pricing_Component__c pricingComponent) {
        Contract__c contract = CONTRACT_MAP.get(pricingComponent.Contract__c);
        if (contract == null) {
            return;
        }

        MERIT_Order_Logic__mdt validLogic;
        for (MERIT_Order_Logic__mdt logic : msPricingComponentHandler.meritOrderLogics) {
            if (logic.Contract_Type__c == contract.Contract_Type_New__c &&
                    logic.Product_Type__c == contract.Product_Type_New__c &&
                    logic.Settlement_Model__c == pricingComponent.Settlement_Model__c &&
                    logic.Country__c == contract.Country__c) {
                validLogic = logic;
                break;
            }
        }

        if (validLogic != null) {
            pricingComponent.Calc_Price_Prod_EPEX_Positive__c = calculateFormula(pricingComponent, validLogic.Price_Prod_EPEX_Positive__c);
            pricingComponent.Calc_Price_Prod_EPEX_Negative__c = calculateFormula(pricingComponent, validLogic.Price_Prod_EPEX_Negative__c);
            pricingComponent.Calc_Price_Downreg_EPEX_Positive__c = calculateFormula(pricingComponent, validLogic.Price_Downreg_EPEX_Positive__c);
            pricingComponent.Calc_Price_Downreg_EPEX_Negative__c = calculateFormula(pricingComponent, validLogic.Price_Downreg_EPEX_Negative__c);
            pricingComponent.Ignore_RefMW__c = validLogic.Ignore_RefMW__c;
        }
    }
    private static Decimal calculateFormula(Pricing_Component__c pricingComponent, String formula) {
        if (formula == null) {
            return null;
        }

        Decimal result = 0;
        List<String> terms = formula.split(' ');
        for (Integer i = 0; i < terms.size(); i++) {
            if (terms[i].isNumeric() == true) {
                result += Decimal.valueOf(terms[i]);
            } else if (terms[i] == '+') {
                if (terms[i + 1].isNumeric() == true) {
                    result += Decimal.valueOf(terms[i + 1]);
                    i++;
                } else if (terms[i + 1].contains('__c')) {
                    result += (Decimal) pricingComponent.get(terms[i + 1]);
                    i++;
                }
            } else if (terms[i] == '-') {
                if (terms[i + 1].isNumeric() == true) {
                    result -= Decimal.valueOf(terms[i + 1]);
                    i++;
                } else if (terms[i + 1].contains('__c')) {
                    result -= (Decimal) pricingComponent.get(terms[i + 1]);
                    i++;
                }
            } else if (terms[i].contains('__c')) {
                result += (Decimal) pricingComponent.get(terms[i]);
            }
        }
        return result;
    }
}