/****************************************************************************************************
* Class GenerationUnitOwnership_ChangeEvtHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-08-18
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-08-18       	Init version.
*****************************************************************************************************/

public without sharing class GenerationUnitOwnership_ChangeEvtHelper {
    private List<Generation_Unit_Ownership__ChangeEvent> triggerNew;
    private Map<Id, Generation_Unit_Ownership__ChangeEvent> newMap;

    public GenerationUnitOwnership_ChangeEvtHelper(
            List<Generation_Unit_Ownership__ChangeEvent> newList,
            Map<Id, Generation_Unit_Ownership__ChangeEvent> mapNew
    ) {
        triggerNew = newList;
        newMap = mapNew;
    }

    //Generation Unit Activation and Assignment variables
    Set<Id> gaa_gUOIdScope = new Set<Id>();
    Set<Id> gaa_genUnitScope = new Set<Id>();

    //SOQL Maps
    private Map<Id, Generation_Unit_Ownership__c> genUnitOwnershipMap = new Map<Id, Generation_Unit_Ownership__c>();

    //SOQL Methods
    public void load_gUOs() {
        if(!gaa_gUOIdScope.isEmpty()) {
            genUnitOwnershipMap = new Map<Id, Generation_Unit_Ownership__c>([
                    SELECT Id, Generation_Unit__c
                    FROM Generation_Unit_Ownership__c
                    WHERE Id IN :gaa_gUOIdScope
                    ALL ROWS
            ]);
        }
    }

    //Generation Unit Activation and Assignment methods
    public void gaa_identifyScope() {
        for (Generation_Unit_Ownership__ChangeEvent change : triggerNew) {
            List<Id> recordIds = change.ChangeEventHeader.getRecordIds();
            gaa_gUOIdScope.addAll(recordIds);
        }
    }

    public void gaa_identifyGenUnitsThatInfluencePortfolioChange_Update(Generation_Unit_Ownership__ChangeEvent change) {
        for(String fieldName : change.ChangeEventHeader.getChangedFields()) {
            if(fieldName == 'Start_Date__c' || fieldName == 'End_Date__c') {
                gaa_addToFinalScope(change);
                break;
            }
        }
    }

    public void gaa_addToFinalScope(Generation_Unit_Ownership__ChangeEvent change) {
        for(Id changeId : change.ChangeEventHeader.getRecordIds()) {
            if(gaa_gUOIdScope.contains(changeId)) {
                gaa_genUnitScope.add(genUnitOwnershipMap.get(changeId).Generation_Unit__c);
            }
        }
    }

    public void gaa_executeCalculationBatches() {
        if (!gaa_genUnitScope.isEmpty()) {
            //these run synchronously to this context
            BatchAssignGenerationUnits.assignGenerationUnits(gaa_genUnitScope);
        }
    }
}