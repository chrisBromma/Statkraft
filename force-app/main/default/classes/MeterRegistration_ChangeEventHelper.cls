/****************************************************************************************************
* Class MeterRegistration_ChangeEventHelper
*
*   Create By	:   ChristianGottlieb (mindsquare AG)
*   Create Date	:   2021-08-16
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-08-16       	Init version.
*****************************************************************************************************/

public without sharing class MeterRegistration_ChangeEventHelper {
    private List<MeterRegistration__ChangeEvent> triggerNew;
    private Map<Id, MeterRegistration__ChangeEvent> newMap;

    public MeterRegistration_ChangeEventHelper(
            List<MeterRegistration__ChangeEvent> newList,
            Map<Id, MeterRegistration__ChangeEvent> mapNew
    ) {
        triggerNew = newList;
        newMap = mapNew;
    }

    //SOQL Maps
    Set<Id> scopeIds = new Set<Id>();
    Map<Id, MeterRegistration__c> scope = new Map<Id, MeterRegistration__c>();
    Map<Id, Meter2GenerationUnitRelationship__c> m2GUMap = new Map<Id, Meter2GenerationUnitRelationship__c>();

    //DML Lists/Maps


    //Meter Activation variables
    Set<Id> ma_meterIds = new Set<Id>();
    Set<Id> ma_metersToCalculateActivationIds = new Set<Id>();

    //Generation Unit Assignment Variables
    Set<Id> gua_meterIds = new Set<Id>();
    ListMapContainer m2GUScope = new ListMapContainer(Meter2GenerationUnitRelationship__c.SObjectType);
    Set<Id> gua_generatorsToAssignIds = new Set<Id>();

    public void scope_identifyRecords() {
        for (MeterRegistration__ChangeEvent change : triggerNew) {
            List<Id> recordIds = change.ChangeEventHeader.getRecordIds();
            scopeIds.addAll(recordIds);
        }
    }

    public void load_MeterRegistrations() {
        scope = new Map<Id, MeterRegistration__c>([
                SELECT Meter__c
                FROM MeterRegistration__c
                WHERE Id IN :scopeIds
                ALL ROWS
        ]);
    }

    public void load_M2GUs() {
        if (!gua_meterIds.isEmpty()) {
            m2GUMap = new Map<Id, Meter2GenerationUnitRelationship__c>([
                    SELECT Generator_Unit__c, Meter__c
                    FROM Meter2GenerationUnitRelationship__c
                    WHERE Meter__c IN :gua_meterIds
            ]);
        }
    }

    public void ma_identifyMeters() {
        for (MeterRegistration__c regItem : scope.values()) {
            ma_meterIds.add(regItem.Meter__c);
        }
    }

    public void gua_identifyMeters() {
        for (MeterRegistration__c regItem : scope.values()) {
            gua_meterIds.add(regItem.Meter__c);
        }
    }

    public void gua_buildDataModelM2GU() {
        for (Meter2GenerationUnitRelationship__c relItem : m2GUMap.values()) {
            if (gua_meterIds.contains(relItem.Meter__c)) {
                m2GUScope.addToMap(relItem.Meter__c, relItem);
            }
        }
    }

    public void ma_addToFinalScope(MeterRegistration__ChangeEvent change) {
        for (Id changeId : change.ChangeEventHeader.getRecordIds()) {
            ma_metersToCalculateActivationIds.add(scope.get(changeId).Meter__c);
        }
    }

    public void gua_addToFinalScope(MeterRegistration__ChangeEvent change) {
        for (Id changeId : change.ChangeEventHeader.getRecordIds()) {
            List<Meter2GenerationUnitRelationship__c> localM2GUScope = m2GUScope.get(scope.get(changeId).Meter__c);
            if (localM2GUScope != null) {
                for (Meter2GenerationUnitRelationship__c relItem : localM2GUScope) {
                    gua_generatorsToAssignIds.add(relItem.Generator_Unit__c);
                }
            }
        }
    }

    public void ma_runActivationCalculation() {
        if (!ma_metersToCalculateActivationIds.isEmpty()) {
            //runs synchronously
            msBatchActivateMeters.updateActiveFlagForMeters(ma_metersToCalculateActivationIds);
        }
    }

    public void gua_runGenUnitAssignment() {
        if (!gua_generatorsToAssignIds.isEmpty()) {
            //runs synchronously
            BatchAssignGenerationUnits.assignGenerationUnits(gua_generatorsToAssignIds);
        }
    }
}