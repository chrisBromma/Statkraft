/****************************************************************************************************
* Class msKAMUtility
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2020-05-13
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2020-05-13       	Init version.
*****************************************************************************************************/

public with sharing class msKAMUtility {

    public static listViewWrapper wrapRecords(
            List<SObject> records,
            List<PicklistEntry> statusEntries,
            String filterFieldApiName,
            Boolean isWhiteListFilter,
            Set<String> listFilters,
            List<String> fieldsToSum,
            String sObjectType
    ) {

        listViewWrapper result = new listViewWrapper();

        for (String fieldName : fieldsToSum) {
            result.fieldSumOverRecords.put(fieldName, 0);
        }
        for (PicklistEntry entryItem : statusEntries) {
            result.statusEntryToCountMap.put(entryItem.value, 0);
            result.filterOptionsFull.add(entryItem.value);
        }
        if (isWhiteListFilter) {
            for (String statusFilter : listFilters) {
                if (!result.statusEntryToCountMap.containsKey(statusFilter)) {
                    result.statusEntryToCountMap.put(statusFilter, 0);
                }
            }
        }

        for (SObject recordItem : records) {
            if ((isWhiteListFilter && listFilters.contains((String) recordItem.get(filterFieldApiName)))
                    || !isWhiteListFilter && !listFilters.contains((String) recordItem.get(filterFieldApiName))) {
                result.records.add(recordItem);
                for (String fieldName : fieldsToSum) {
                    if (recordItem.get(fieldName) != null) {
                        result.fieldSumOverRecords.put(fieldName, result.fieldSumOverRecords.get(fieldName) + (Decimal) recordItem.get(fieldName));
                    }
                }
            }

            if (!result.statusEntryToCountMap.containsKey((String) recordItem.get(filterFieldApiName))) {
                result.statusEntryToCountMap.put((String) recordItem.get(filterFieldApiName), 0);
            }
            result.statusEntryToCountMap.put((String) recordItem.get(filterFieldApiName),
                    result.statusEntryToCountMap.get((String) recordItem.get(filterFieldApiName)) + 1);

        }

        result.fieldAPINameToLabelMap = generateFieldAPINameToLabelMap(sObjectType);
        result.sObjectLabel = getSObjectLabel(sObjectType);
        result.sObjectPluralLabel = getSObjectPluralLabel(sObjectType);

        return result;
    }

    public static Map<String, String> generateFieldAPINameToLabelMap(String sObjectType) {
        Map<String, String> fieldAPINameToLabelMap = new Map<String, String>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType schema = schemaMap.get(sObjectType);
        Map<String, Schema.SObjectField> fieldMap = schema.getDescribe().fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            fieldAPINameToLabelMap.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
        }
        return fieldAPINameToLabelMap;
    }

    public static String getSObjectLabel(String sObjectType) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType schema = schemaMap.get(sObjectType);
        return schema.getDescribe().getLabel();
    }

    public static String getSObjectPluralLabel(String sObjectType) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType schema = schemaMap.get(sObjectType);
        return schema.getDescribe().getLabelPlural();
    }

    public class listViewWrapper {
        @AuraEnabled public List<SObject> records { get; set; }
        @AuraEnabled public Map<String, Integer> statusEntryToCountMap { get; set; }
        @AuraEnabled public List<String> filterOptionsFull { get; set; }
        @AuraEnabled public Map<String, Decimal> fieldSumOverRecords { get; set; }
        @AuraEnabled public Map<String, String> fieldAPINameToLabelMap { get; set; }
        @AuraEnabled public String sObjectLabel { get; set; }
        @AuraEnabled public String sObjectPluralLabel { get; set; }

        listViewWrapper() {
            records = new List<SObject>();
            statusEntryToCountMap = new Map<String, Integer>();
            filterOptionsFull = new List<String>();
            fieldSumOverRecords = new Map<String, Decimal>();
            fieldAPINameToLabelMap = new Map<String, String>();
        }
    }
}