/****************************************************************************************************
* Class GenerationUnitOwnership_ChangeEvtHandler
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

public without sharing class GenerationUnitOwnership_ChangeEvtHandler extends TriggerHandlerExtension {

    GenerationUnitOwnership_ChangeEvtHelper Helper;
    // Constructor
    public GenerationUnitOwnership_ChangeEvtHandler() {
        super();
        Helper = new GenerationUnitOwnership_ChangeEvtHelper(
                (List<Generation_Unit_Ownership__ChangeEvent>) Trigger.new,
                (Map<Id, Generation_Unit_Ownership__ChangeEvent>) Trigger.newMap
        );
    }

    public override void bulkAfter() {
        Helper.gaa_identifyScope();
        Helper.load_gUOs();
    }

    public override void afterInsert(SObject obj) {
        Generation_Unit_Ownership__ChangeEvent change = (Generation_Unit_Ownership__ChangeEvent) obj;
        if(change.ChangeEventHeader.getChangeType() == 'CREATE') {
            Helper.gaa_addToFinalScope(change);
        } else if(change.ChangeEventHeader.getChangeType() == 'UPDATE') {
            Helper.gaa_identifyGenUnitsThatInfluencePortfolioChange_Update(change);
        } else if(change.ChangeEventHeader.getChangeType() == 'DELETE') {
            Helper.gaa_addToFinalScope(change);
        } else if(change.ChangeEventHeader.getChangeType() == 'UNDELETE') {
            Helper.gaa_addToFinalScope(change);
        }
    }

    public override void andFinally() {
        Helper.gaa_executeCalculationBatches();
    }
}