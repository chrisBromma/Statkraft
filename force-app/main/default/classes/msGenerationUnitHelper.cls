/****************************************************************************************************
 * Class msGenerationUnitHelper
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2021-07-07
 *   Description	:	cap_ -  Changes in the Capacity or Production Values result in an update to keep Data on
 *                           the Contracts correct
 *                   ssc_ -  Subsidy Scheme Calculations: The Last Day of Subsidy is automatically populated
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare AG)	            2021-07-07       	Init version.
 *****************************************************************************************************/

public without sharing class msGenerationUnitHelper {
    private List<Generation_Unit__c> triggerOld;
    private List<Generation_Unit__c> triggerNew;
    private Map<Id, Generation_Unit__c> oldMap;
    private Map<Id, Generation_Unit__c> newMap;

    public msGenerationUnitHelper(
        List<Generation_Unit__c> oldList,
        List<Generation_Unit__c> newList,
        Map<Id, Generation_Unit__c> mapOld,
        Map<Id, Generation_Unit__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //SOQL Maps
    private Map<Id, Meter2GenerationUnitRelationship__c> m2GUMap = new Map<Id, Meter2GenerationUnitRelationship__c>();
    private Map<String, Control_Circuit__c> controlCircuitMap = new Map<String, Control_Circuit__c>();

    //DML List/Maps
    public Map<Id, Meter2GenerationUnitRelationship__c> m2GUUpdateMap = new Map<Id, Meter2GenerationUnitRelationship__c>();

    //Capacity and Production variables
    private ListMapContainer cap_genUnitIdToM2GUs = new ListMapContainer(
        Meter2GenerationUnitRelationship__c.SObjectType
    );
    private Set<Id> cap_genUnitIdsToUpdate = new Set<Id>();

    //Control Circuit Object generation
    Set<String> ccg_controlCircuitIds = new Set<String>();

    //SOQL methods
    public void load_M2Gs() {
        if (!cap_genUnitIdsToUpdate.isEmpty()) {
            m2GUMap = new Map<Id, Meter2GenerationUnitRelationship__c>(
                [
                    SELECT Annual_Production__c, Installed_Capacity__c, Generator_Unit__c
                    FROM Meter2GenerationUnitRelationship__c
                    WHERE Generator_Unit__c IN :cap_genUnitIdsToUpdate
                ]
            );
        }
    }

    public void load_ControlCircuits() {
        if (!ccg_controlCircuitIds.isEmpty()) {
            controlCircuitMap = new Map<String, Control_Circuit__c>();
            for (Control_Circuit__c cc : query_ControlCircuits(ccg_controlCircuitIds)) {
                controlCircuitMap.put(cc.Control_Circuit_Id__c, cc);
            }
        }
    }

    public static List<Control_Circuit__c> query_ControlCircuits(Set<String> controlCircuitIds) {
        return [SELECT Control_Circuit_Id__c FROM Control_Circuit__c WHERE Control_Circuit_Id__c IN :controlCircuitIds];
    }

    //Control Circuit creation methods
    public void ccg_isolateControlCircuitIds() {
        ccg_controlCircuitIds = new Set<String>();
        for (Generation_Unit__c gu : triggerNew) {
            if (gu.Control_Circuit_Id__c != null && !gu.Control_Circuit_Id__c?.contains(',')) {
                ccg_controlCircuitIds.add(gu.Control_Circuit_Id__c);
            }
        }
    }

    public List<Control_Circuit__c> ccg_createNewControlCircuits() {
        Map<String, Control_Circuit__c> mapOfNewControlCircuits = new Map<String, Control_Circuit__c>();
        if (!ccg_controlCircuitIds.isEmpty()) {
            for (String ccId : ccg_controlCircuitIds) {
                if (!controlCircuitMap.containsKey(ccId) && !mapOfNewControlCircuits.containsKey(ccId)) {
                    mapOfNewControlCircuits.put(ccId, new Control_Circuit__c(Control_Circuit_Id__c = ccId));
                }
            }
        }
        return mapOfNewControlCircuits.values();
    }

    //Capacity and Production methods
    public void cap_identifyGenUnitsForUpdates() {
        for (Generation_Unit__c generationUnit : triggerNew) {
            Generation_Unit__c old = oldMap.get(generationUnit.Id);
            if (cap_updateNecessary(generationUnit, old)) {
                cap_genUnitIdsToUpdate.add(generationUnit.Id);
            }
        }
    }

    public void cap_buildM2GDataModel() {
        if (!cap_genUnitIdsToUpdate.isEmpty()) {
            for (Meter2GenerationUnitRelationship__c relItem : m2GUMap.values()) {
                if (cap_genUnitIdsToUpdate.contains(relItem.Generator_Unit__c)) {
                    cap_genUnitIdToM2GUs.addToMap(relItem.Generator_Unit__c, relItem);
                }
            }
        }
    }

    private Boolean cap_updateNecessary(
        Generation_Unit__c genUnit,
        Meter2GenerationUnitRelationship__c relationshipToCompare
    ) {
        return (genUnit.Installed_Capacity__c != relationshipToCompare.Installed_Capacity__c ||
        genUnit.Annual_Production__c != relationshipToCompare.Annual_Production__c);
    }

    private Boolean cap_updateNecessary(Generation_Unit__c genUnit, Generation_Unit__c genUnitToCompare) {
        return (genUnit.Installed_Capacity__c != genUnitToCompare.Installed_Capacity__c ||
        genUnit.Annual_Production__c != genUnitToCompare.Annual_Production__c);
    }

    public void cap_setAndUpdateM2GValues(Generation_Unit__c oldGenerationUnit, Generation_Unit__c newGenerationUnit) {
        if (cap_updateNecessary(oldGenerationUnit, newGenerationUnit)) {
            List<Meter2GenerationUnitRelationship__c> m2GUsToCheckForUpdate = cap_genUnitIdToM2GUs.get(
                newGenerationUnit.Id
            );
            for (Meter2GenerationUnitRelationship__c rel : m2GUsToCheckForUpdate) {
                if (cap_updateNecessary(newGenerationUnit, rel)) {
                    rel.Annual_Production__c = newGenerationUnit.Annual_Production__c;
                    rel.Installed_Capacity__c = newGenerationUnit.Installed_Capacity__c;
                    m2GUUpdateMap.put(rel.Id, rel);
                }
            }
        }
    }

    //Subsidy state calculation methods

    public void ssc_setSubsidyEndDate_Insert(Generation_Unit__c genUnit) {
        if (ssc_isRelevant(genUnit)) {
            ssc_setLastDayOfSubsidy(genUnit);
        }
    }

    public void ssc_setSubsidyEndDate_Update(Generation_Unit__c oldGenUnit, Generation_Unit__c newGenUnit) {
        if (
            ssc_isRelevant(newGenUnit) &&
            (ssc_isRelevantChange(oldGenUnit, newGenUnit) || newGenUnit.Last_Day_of_Subsidy_Scheme__c == null)
        ) {
            ssc_setLastDayOfSubsidy(newGenUnit);
        }
    }

    private Boolean ssc_isRelevant(Generation_Unit__c genUnit) {
        return genUnit.Country__c == 'Germany' && genUnit.Commissioning_Date__c != null;
    }

    private Boolean ssc_isRelevantChange(Generation_Unit__c oldGenUnit, Generation_Unit__c newGenUnit) {
        return oldGenUnit.Commissioning_Date__c != newGenUnit.Commissioning_Date__c ||
            oldGenUnit.Country__c != newGenUnit.Country__c;
    }

    private void ssc_setLastDayOfSubsidy(Generation_Unit__c genUnit) {
        genUnit.Last_Day_of_Subsidy_Scheme__c = Date.newInstance(
            genUnit.Commissioning_Date__c.addYears(20).year(),
            12,
            31
        );
    }
}