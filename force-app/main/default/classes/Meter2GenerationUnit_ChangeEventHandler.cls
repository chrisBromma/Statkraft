/****************************************************************************************************
* Class Meter2GenerationUnit_ChangeEventHandler
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-05-26
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-05-26       	Init version.
*****************************************************************************************************/

public without sharing class Meter2GenerationUnit_ChangeEventHandler extends TriggerHandlerExtension {

    Meter2GenerationUnit_ChangeEventHelper helper;
    // Constructor
    public Meter2GenerationUnit_ChangeEventHandler() {
        super();
        helper = new Meter2GenerationUnit_ChangeEventHelper(
                (List<Meter2GenerationUnitRelationship__ChangeEvent>) Trigger.new,
                (Map<Id, Meter2GenerationUnitRelationship__ChangeEvent>) Trigger.newMap
        );
    }

    public override void bulkAfter() {
        helper.gaa_identifyScope();
        helper.load_M2Gs();
    }

    public override void afterInsert(SObject obj) {
        Meter2GenerationUnitRelationship__ChangeEvent change = (Meter2GenerationUnitRelationship__ChangeEvent) obj;
        if (change.ChangeEventHeader.getChangeType() == 'UPDATE') {
            helper.gaa_identifyGenUnitsThatInfluencePortfolioChange_Update(change);
        } else if (change.ChangeEventHeader.getChangeType() == 'CREATE') {
            helper.gaa_addToFinalScope(change);
        } else if(change.ChangeEventHeader.getChangeType() == 'DELETE') {
            helper.gaa_addToFinalScope(change);
        } else if(change.ChangeEventHeader.getChangeType() == 'UNDELETE') {
            helper.gaa_addToFinalScope(change);
        }
    }

    public override void andFinally() {
        helper.gaa_executeCalculationBatches();
    }
}