/****************************************************************************************************
* Class msMeter2GenerationUnitHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-09-30
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-09-30       	Init version.
*****************************************************************************************************/

public without sharing class msMeter2GenerationUnitHelper {

    private List<Meter2GenerationUnitRelationship__c> triggerOld;
    private List<Meter2GenerationUnitRelationship__c> triggerNew;
    private Map<Id, Meter2GenerationUnitRelationship__c> oldMap;
    private Map<Id, Meter2GenerationUnitRelationship__c> newMap;

    //SOQL Maps
    private Map<Id, Generation_Unit__c> genUnitMap = new Map<Id, Generation_Unit__c>();

    //Validation of correct Capacity and Production values at all times
    private Set<Id> cap_genUnitIdsToDoubleCheck = new Set<Id>();

    public msMeter2GenerationUnitHelper(
            List<Meter2GenerationUnitRelationship__c> oldList,
            List<Meter2GenerationUnitRelationship__c> newList,
            Map<Id, Meter2GenerationUnitRelationship__c> mapOld,
            Map<Id, Meter2GenerationUnitRelationship__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }


    private Boolean cap_M2GUHasRelevantlyChanged(Meter2GenerationUnitRelationship__c relItem) {
        return oldMap.get(relItem.Id).Installed_Capacity__c != relItem.Installed_Capacity__c
                || oldMap.get(relItem.Id).Annual_Production__c != relItem.Annual_Production__c;
    }

    public void cap_identifyM2GUsToValidateForCorrectValues_Update() {
        for (Meter2GenerationUnitRelationship__c relItem : triggerNew) {
            if (cap_M2GUHasRelevantlyChanged(relItem)) {
                cap_genUnitIdsToDoubleCheck.add(relItem.Generator_Unit__c);
            }
        }
    }

    public void cap_identifyM2GUsToValidateForCorrectValues_Insert() {
        for (Meter2GenerationUnitRelationship__c relItem : triggerNew) {
            cap_genUnitIdsToDoubleCheck.add(relItem.Generator_Unit__c);
        }
    }

    public void load_GenerationUnits() {
        if (!cap_genUnitIdsToDoubleCheck.isEmpty()) {
            genUnitMap = new Map<Id, Generation_Unit__c>([
                    SELECT Id, Annual_Production__c, Installed_Capacity__c
                    FROM Generation_Unit__c
                    WHERE Id IN :cap_genUnitIdsToDoubleCheck
            ]);
        }
    }

    public void cap_validateOrOverwriteChanges_Insert(Meter2GenerationUnitRelationship__c relItem) {
        relItem.Installed_Capacity__c = genUnitMap.get(relItem.Generator_Unit__c).Installed_Capacity__c;
        relItem.Annual_Production__c = genUnitMap.get(relItem.Generator_Unit__c).Annual_Production__c;

    }

    public void cap_validateOrOverwriteChanges_Update(Meter2GenerationUnitRelationship__c relItem) {
        if (cap_M2GUHasRelevantlyChanged(relItem)) {
            relItem.Installed_Capacity__c = genUnitMap.get(relItem.Generator_Unit__c).Installed_Capacity__c;
            relItem.Annual_Production__c = genUnitMap.get(relItem.Generator_Unit__c).Annual_Production__c;
        }
    }
}