/****************************************************************************************************
* Class Meter2GenerationUnit_ChangeEventHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-30
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-30       	Init version.
*****************************************************************************************************/

public without sharing class Meter2GenerationUnit_ChangeEventHelper {
    private List<Meter2GenerationUnitRelationship__ChangeEvent> triggerNew;
    private Map<Id, Meter2GenerationUnitRelationship__ChangeEvent> newMap;

    public Meter2GenerationUnit_ChangeEventHelper(
            List<Meter2GenerationUnitRelationship__ChangeEvent> newList,
            Map<Id, Meter2GenerationUnitRelationship__ChangeEvent> mapNew
    ) {
        triggerNew = newList;
        newMap = mapNew;
    }

    //Generation Unit Activation and Assignment variables
    Set<Id> gaa_m2GIdScope = new Set<Id>();
    Set<Id> gaa_genUnitScope = new Set<Id>();

    //SOQL Maps
    private Map<Id, Meter2GenerationUnitRelationship__c> m2GMap = new Map<Id, Meter2GenerationUnitRelationship__c>();

    //SOQL Methods
    public void load_M2Gs() {
        if (!gaa_m2GIdScope.isEmpty()) {
            m2GMap = new Map<Id, Meter2GenerationUnitRelationship__c>([
                    SELECT Id, Generator_Unit__c
                    FROM Meter2GenerationUnitRelationship__c
                    WHERE Id IN :gaa_m2GIdScope
                    ALL ROWS
            ]);
        }
    }

    //Generation Unit Activation and Assignment methods
    public void gaa_identifyScope() {
        for (Meter2GenerationUnitRelationship__ChangeEvent change : triggerNew) {
            List<Id> recordIds = change.ChangeEventHeader.getRecordIds();
            gaa_m2GIdScope.addAll(recordIds);
        }
    }

    public void gaa_identifyGenUnitsThatInfluencePortfolioChange_Update(Meter2GenerationUnitRelationship__ChangeEvent change) {
        for (String fieldName : change.ChangeEventHeader.getChangedFields()) {
            if (fieldName == 'Valid_from__c' || fieldName == 'Valid_to__c') {
                gaa_addToFinalScope(change);
                break;
            }
        }
    }

    public void gaa_addToFinalScope(Meter2GenerationUnitRelationship__ChangeEvent change) {
        for (Id changeId : change.ChangeEventHeader.getRecordIds()) {
            if (gaa_m2GIdScope.contains(changeId)) {
                gaa_genUnitScope.add(m2GMap.get(changeId).Generator_Unit__c);
            }
        }
    }

    public void gaa_executeCalculationBatches() {
        if (!gaa_genUnitScope.isEmpty()) {
            //these run synchronously to this context
            BatchAssignGenerationUnits.assignGenerationUnits(gaa_genUnitScope);
            msBatchActivateGenUnits.updateActiveFlagForGenerators(gaa_genUnitScope);
        }
    }
}