/****************************************************************************************************
* Class msPricingComponentHandler
*
*   Create By  :   Steffen Naundorf (mindsquare GmbH)
*   Create Date    :   19.12.2018
*   Description    :
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                               Date                Description
*   * -----------------------------------------------------------------------------------------------
*   * Steffen Naundorf (mindsquare GmbH)   19.12.2018              Init version.
*****************************************************************************************************/

public without sharing class msPricingComponentHandler extends TriggerHandlerExtension {
    Map<String, Map<Date, Bryt_Reference_Capacity__c>> contractToDateToCapacityMap = new Map<String, Map<Date, Bryt_Reference_Capacity__c>>();
    public static final Id devRecordTypeId =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Bryt_Pricing_Component').getRecordTypeId();
    public static final Id FLOATING_ENERGY_PRICE_REC_TYPE_ID =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Floating_Energy_Price').getRecordTypeId();
    public static List<MERIT_Order_Logic__mdt> meritOrderLogics;



    private Map<Id, List<Pricing_Component__c>> contractIdToRelevantPCListMap = new Map<Id, List<Pricing_Component__c>>();
    User createdByUser = new User();

    // Constructor
    public msPricingComponentHandler() {
        super();
    }


    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate((List<Pricing_Component__c>) Trigger.new, false);
        }
        if (Trigger.isUpdate || Trigger.isInsert) {
            meritOrderLogics = [
                    SELECT Id, Contract_Type__c, Product_Type__c,
                            Price_Downreg_EPEX_Negative__c, Price_Downreg_EPEX_Positive__c, Price_Prod_EPEX_Negative__c,
                            Price_Prod_EPEX_Positive__c,Country__c,Settlement_Model__c, Ignore_RefMW__c
                    FROM MERIT_Order_Logic__mdt
            ];

            List<Pricing_Component__c>pricingComponents = (List<Pricing_Component__c>) Trigger.new;
            List<Id>contractIds = new List<Id>();
            for (Pricing_Component__c pc : pricingComponents) {
                contractIds.add(pc.Contract__c);
            }
            msPricingComponentHelper.CONTRACT_MAP = new Map<Id, Contract__c>([SELECT Id, Product_Type_New__c, Contract_Type_New__c, Country__c FROM Contract__c WHERE Id In:contractIds]);
        }
    }


    public override void bulkAfter() {

        Map<Id, Pricing_Component__c> newMap = (Map<Id, Pricing_Component__c>) Trigger.newMap;
        Map<Id, Pricing_Component__c> oldMap = (Map<Id, Pricing_Component__c>) Trigger.oldMap;

        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {

            List<Pricing_Component__c> pcNewList;
            if (Trigger.isInsert || Trigger.isUpdate) {
                pcNewList = (List<Pricing_Component__c>) Trigger.new;
            }
            if (Trigger.isDelete) {
                pcNewList = (List<Pricing_Component__c>) Trigger.old;
            }
            List<Id> contractIds = new List<Id>();

            for (Pricing_Component__c tmpPC : pcNewList) {
                if (tmpPC.RecordTypeId == devRecordTypeId) {
                    contractIds.add(tmpPC.Contract__c);
                }
            }

            List<Bryt_Reference_Capacity__c> refCapacities = [
                    SELECT Id, Contract__c, Month__c, Capacity_Off_Peak__c, Traded_Off_Peak__c
                    FROM Bryt_Reference_Capacity__c
                    WHERE Contract__c IN:contractIds
            ];


            for (Bryt_Reference_Capacity__c tmp : refCapacities) {
                Map<Date, Bryt_Reference_Capacity__c> dateToCapacityMap = contractToDateToCapacityMap.get(tmp.Contract__c);
                if (dateToCapacityMap == null)dateToCapacityMap = new Map<Date, Bryt_Reference_Capacity__c>();

                if (tmp.Capacity_Off_Peak__c == null)tmp.Capacity_Off_Peak__c = 0;
                if (tmp.Traded_Off_Peak__c == null)tmp.Traded_Off_Peak__c = 0;
                dateToCapacityMap.put(tmp.Month__c, tmp);
                contractToDateToCapacityMap.put(tmp.Contract__c, dateToCapacityMap);
            }

            if (Trigger.isInsert) {
                pcNewList = (List<Pricing_Component__c>) Trigger.new;
                if (!pcNewList.isEmpty()) {
                    createdByUser = [SELECT Id, Email, ContactId FROM User WHERE Id = :pcNewList[0].CreatedById LIMIT 1];
                }
            }

            Set<Id> contractIdsToCheckForRelevance = new Set<Id>();
            contractIdsToCheckForRelevance = msPricingComponentHelper.identifyContractsForOverlapOfPricingComponents(Trigger.isInsert, Trigger.isUpdate, newMap, oldMap);
            if (!contractIdsToCheckForRelevance.isEmpty()) {
                contractIdToRelevantPCListMap = msPricingComponentHelper.getPricingComponentsToCheckForOverlap(contractIdsToCheckForRelevance);
            }
        }

    }

    public override void beforeInsert(SObject obj) {
        Pricing_Component__c pricingComponent = (Pricing_Component__c) obj;
        msPricingComponentHelper.calculateMeritOrder(pricingComponent);
    }
    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Pricing_Component__c pricingComponent = (Pricing_Component__c) obj;
        msPricingComponentHelper.calculateMeritOrder(pricingComponent);
    }

    public override void afterInsert(SObject obj) {

        Pricing_Component__c tmpPricingComponent = (Pricing_Component__c) obj;

        if (tmpPricingComponent.RecordTypeId == devRecordTypeId) {
            Map<Date, Bryt_Reference_Capacity__c> dateToCapacityMap = contractToDateToCapacityMap.get(tmpPricingComponent.Contract__c);

            //if (!tmpPricingComponent.msBrytIsDeactivated__c) { -- Deactivations of Trade currently on hold
            Integer t = tmpPricingComponent.Start_Date__c.monthsBetween(tmpPricingComponent.End_Date__c) + 1;
            for (Integer i = 0; i < t; i++) {
                Bryt_Reference_Capacity__c tmpCapacity = dateToCapacityMap.get(tmpPricingComponent.Start_Date__c.addMonths(i));
                if (tmpCapacity == null) {
                    tmpPricingComponent.addError('Reference Capacity not found');
                    return;
                } else {
                    if (tmpCapacity.Traded_Off_Peak__c == null)tmpCapacity.Traded_Off_Peak__c = 0;
                    tmpCapacity.Traded_Off_Peak__c += tmpPricingComponent.Fixed_Volume__c;

                    if (tmpCapacity.Traded_Off_Peak__c > tmpCapacity.Capacity_Off_Peak__c) {
                        tmpPricingComponent.addError('Capacity exceeded');
                        return;
                    }
                    if (tmpCapacity.Traded_Off_Peak__c < 0) {
                        tmpPricingComponent.addError('Capacity undercut');
                        return;
                    }
                    dateToCapacityMap.put(tmpPricingComponent.Start_Date__c.addMonths(i), tmpCapacity);
                }
            }
            contractToDateToCapacityMap.put(tmpPricingComponent.Contract__c, dateToCapacityMap);
            //}
        } else if (tmpPricingComponent.RecordTypeId == FLOATING_ENERGY_PRICE_REC_TYPE_ID) {
            if (contractIdToRelevantPCListMap.keySet().contains(tmpPricingComponent.Contract__c)
                    && contractIdToRelevantPCListMap.get(tmpPricingComponent.Contract__c).size() > 1) {
                if (msPricingComponentHelper.checkPricingComponentForOverlap(tmpPricingComponent, contractIdToRelevantPCListMap)) {
                    tmpPricingComponent.addError('Floating Energy Price can not overlap for the Contract');
                    return;
                }
            }
        }
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {

        Pricing_Component__c tmpPricingComponent = (Pricing_Component__c) obj;
        Pricing_Component__c tmpPricingComponentOld = (Pricing_Component__c) oldObj;
        if (tmpPricingComponent.RecordTypeId == devRecordTypeId) {

            Decimal difference = tmpPricingComponent.Fixed_Volume__c - tmpPricingComponentOld.Fixed_Volume__c;
            Map<Date, Bryt_Reference_Capacity__c> dateToCapacityMap = contractToDateToCapacityMap.get(tmpPricingComponent.Contract__c);

            //if (!tmpPricingComponentOld.msBrytIsDeactivated__c && !tmpPricingComponent.msBrytIsDeactivated__c) { -- Deactivations of Trade currently on hold
            Integer t = tmpPricingComponent.Start_Date__c.monthsBetween(tmpPricingComponent.End_Date__c) + 1;
            for (Integer i = 0; i < t; i++) {
                Bryt_Reference_Capacity__c tmpCapacity = dateToCapacityMap.get(tmpPricingComponent.Start_Date__c.addMonths(i));
                if (tmpCapacity == null) {
                    tmpPricingComponent.addError('Reference Capacity not found');
                    return;
                } else {
                    if (tmpCapacity.Traded_Off_Peak__c == null)tmpCapacity.Traded_Off_Peak__c = 0;
                    tmpCapacity.Traded_Off_Peak__c += difference;

                    if (tmpCapacity.Traded_Off_Peak__c > tmpCapacity.Capacity_Off_Peak__c) {
                        tmpPricingComponent.addError('Capacity exceeded');
                        return;
                    }
                    if (tmpCapacity.Traded_Off_Peak__c < 0) {
                        tmpPricingComponent.addError('Capacity undercut');
                        return;
                    }

                    dateToCapacityMap.put(tmpPricingComponent.Start_Date__c.addMonths(i), tmpCapacity);
                }
            }
            contractToDateToCapacityMap.put(tmpPricingComponent.Contract__c, dateToCapacityMap);
            // }
            /*if (!tmpPricingComponentOld.msBrytIsDeactivated__c && tmpPricingComponent.msBrytIsDeactivated__c) { -- Deactivations of Trade currently on hold
                Integer t = tmpPricingComponentOld.Start_Date__c.monthsBetween(tmpPricingComponentOld.End_Date__c)+1;
                for (Integer i = 0; i < t; i++) {
                    Bryt_Reference_Capacity__c tmpCapacity = dateToCapacityMap.get(tmpPricingComponentOld.Start_Date__c.addMonths(i));
                    if (tmpCapacity == null) {
                        tmpPricingComponentOld.addError('Reference Capacity not found');
                       return;
                    } else {
                        if (tmpCapacity.Traded_Off_Peak__c == null)tmpCapacity.Traded_Off_Peak__c = 0;
                        tmpCapacity.Traded_Off_Peak__c -= tmpPricingComponentOld.Fixed_Volume__c;
                        dateToCapacityMap.put(tmpPricingComponentOld.Start_Date__c.addMonths(i), tmpCapacity);
                    }
                }
                contractToDateToCapacityMap.put(tmpPricingComponentOld.Contract__c, dateToCapacityMap);
                msBrytMailConf.msSendDeactNotif(tmpPricingComponentOld.Id);
            }
            if (tmpPricingComponentOld.msBrytIsDeactivated__c && tmpPricingComponent.msBrytIsDeactivated__c) {

            }
            if (tmpPricingComponentOld.msBrytIsDeactivated__c && !tmpPricingComponent.msBrytIsDeactivated__c) {
                Integer t = tmpPricingComponent.Start_Date__c.monthsBetween(tmpPricingComponent.End_Date__c)+1;
                for (Integer i = 0; i < t; i++) {
                    Bryt_Reference_Capacity__c tmpCapacity = dateToCapacityMap.get(tmpPricingComponent.Start_Date__c.addMonths(i));
                    if (tmpCapacity == null) {
                        tmpPricingComponent.addError('Reference Capacity not found');
                        return;
                    } else {
                        if (tmpCapacity.Traded_Off_Peak__c == null)tmpCapacity.Traded_Off_Peak__c = 0;
                        tmpCapacity.Traded_Off_Peak__c += tmpPricingComponent.Fixed_Volume__c;

                        if (tmpCapacity.Traded_Off_Peak__c > tmpCapacity.Capacity_Off_Peak__c) {
                            tmpPricingComponent.addError('Capacity exceeded');
                            return;
                        }
                        if (tmpCapacity.Traded_Off_Peak__c < 0) {
                            tmpPricingComponent.addError('Capacity undercut');
                            return;
                        }
                        dateToCapacityMap.put(tmpPricingComponent.Start_Date__c.addMonths(i), tmpCapacity);
                    }
                }
                contractToDateToCapacityMap.put(tmpPricingComponent.Contract__c, dateToCapacityMap);
            }*/
        } else if (tmpPricingComponent.RecordTypeId == FLOATING_ENERGY_PRICE_REC_TYPE_ID) {
            if (contractIdToRelevantPCListMap.keySet().contains(tmpPricingComponent.Contract__c)
                    && contractIdToRelevantPCListMap.get(tmpPricingComponent.Contract__c).size() > 1) {
                if (msPricingComponentHelper.checkPricingComponentForOverlap(tmpPricingComponent, contractIdToRelevantPCListMap)) {
                    tmpPricingComponent.addError('This Pricing Component is intersecting with another one for the respective Contract');
                    return;
                }
            }
        }
    }

    public override void afterDelete(SObject obj) {

        Pricing_Component__c tmpPricingComponent = (Pricing_Component__c) obj;


        if (tmpPricingComponent.RecordTypeId == devRecordTypeId) {
            Map<Date, Bryt_Reference_Capacity__c> dateToCapacityMap = contractToDateToCapacityMap.get(tmpPricingComponent.Contract__c);
            //if (!tmpPricingComponent.msBrytIsDeactivated__c) {  -- Deactivations of Trade currently on hold
            Integer t = tmpPricingComponent.Start_Date__c.monthsBetween(tmpPricingComponent.End_Date__c) + 1;
            for (Integer i = 0; i < t; i++) {
                Bryt_Reference_Capacity__c tmpCapacity = dateToCapacityMap.get(tmpPricingComponent.Start_Date__c.addMonths(i));
                if (tmpCapacity == null) {
                    tmpPricingComponent.addError('Reference Capacity not found');
                    return;
                } else {
                    if (tmpCapacity.Traded_Off_Peak__c == null)tmpCapacity.Traded_Off_Peak__c = 0;
                    tmpCapacity.Traded_Off_Peak__c -= tmpPricingComponent.Fixed_Volume__c;
                    dateToCapacityMap.put(tmpPricingComponent.Start_Date__c.addMonths(i), tmpCapacity);
                }
            }
            contractToDateToCapacityMap.put(tmpPricingComponent.Contract__c, dateToCapacityMap);
            //}
        }
    }


    public override void andFinally() {
        if (isDisabled) {
            return;
        }
// insert lstInsert-List
        if (!lstInsert.isEmpty()) {
            Database.insert(lstInsert);
        }

// upsert lstUpsert-List
        try {
            if (!lstUpsert.isEmpty()) {
                Database.upsert(lstUpsert);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception on UserHandler Finally upsert: ' + e);
        }
// update lstUpdate-List
        try {
            if (!lstUpdate.isEmpty()) {
                Database.update(lstUpdate);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception on UserHandler Finally update: ' + e);
        }


//update reference capacities
        try {
            if (!contractToDateToCapacityMap.isEmpty()) {
                List<Bryt_Reference_Capacity__c> refCapacitiesToUpdate = new List<Bryt_Reference_Capacity__c>();
                Set <String> keys = contractToDateToCapacityMap.keySet();
                for (String key : keys) {
                    Map<Date, Bryt_Reference_Capacity__c> dateToCapacityMap = contractToDateToCapacityMap.get(key);
                    refCapacitiesToUpdate.addAll(dateToCapacityMap.values());
                }
                update refCapacitiesToUpdate;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception on UserHandler Finally update: ' + e);
        }


// delete lstDelete-List
        try {
            if (!lstDelete.isEmpty()) {
                Database.delete(lstDelete);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception on UserHandler Finally delete: ' + e);
        }
/* Start - @changed - Christian Gottlieb - 21.01.2019- FLT-115 - Generating and sending e-mail notifications */

        try {
            if (Trigger.isInsert && Trigger.isAfter) {
                List<Pricing_Component__c> pcNewList = (List<Pricing_Component__c>) Trigger.new;
                Id contractId = null;
                List<Id> pcIds = new List<Id>();
                for (Pricing_Component__c pcItem : pcNewList) {
                    if (/*!pcItem.msBrytIsDeactivated__c &&*/ pcItem.RecordTypeId == devRecordTypeId) {
                        pcIds.add(pcItem.Id);
                    }
                }
                if (!pcIds.isEmpty()) {
                    contractId = pcNewList[0].Contract__c;
                    msBrytNotificationLogic.notifyForTrades(pcIds);
//msBrytNotificationLogic.notifyContractForTrades(pcIds, UserInfo.getUserId());
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception on Pricing Component Handler Finally insert, confirmation message could not be send: ' + e);
        }
    }
}