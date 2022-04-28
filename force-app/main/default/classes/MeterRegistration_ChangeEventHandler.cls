/****************************************************************************************************
* Class MeterRegistration_ChangeEventHandler
*
*   Create By	:   ChristianGottlieb (mindsquare AG)
*   Create Date	:   2021-05-26
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare AG)	            2021-05-26       	Init version.
*****************************************************************************************************/

public without sharing class MeterRegistration_ChangeEventHandler extends TriggerHandlerExtension {

    MeterRegistration_ChangeEventHelper Helper;
    public MeterRegistration_ChangeEventHandler() {
        super();
        Helper = new MeterRegistration_ChangeEventHelper(
                (List<MeterRegistration__ChangeEvent>) Trigger.new,
                (Map<Id, MeterRegistration__ChangeEvent>) Trigger.newMap
        );
    }

    public override void bulkAfter() {
        Helper.scope_identifyRecords();
        Helper.load_MeterRegistrations();
        Helper.ma_identifyMeters();
        Helper.gua_identifyMeters();
        Helper.load_M2GUs();
        Helper.gua_buildDataModelM2GU();
    }

    public override void afterInsert(SObject obj) {
        MeterRegistration__ChangeEvent change = (MeterRegistration__ChangeEvent) obj;
        if (change.ChangeEventHeader.getChangeType() == 'UPDATE') {
            for (String fieldName : change.ChangeEventHeader.getChangedFields()) {
                if (fieldName == 'Valid_from__c' || fieldName == 'Valid_to__c') {
                    Helper.ma_addToFinalScope(change);
                    Helper.gua_addToFinalScope(change);
                }
            }
        } else if (change.ChangeEventHeader.getChangeType() == 'DELETE'
                || change.ChangeEventHeader.getChangeType() == 'UNDELETE'
                || change.ChangeEventHeader.getChangeType() == 'CREATE') {
            Helper.ma_addToFinalScope(change);
            Helper.gua_addToFinalScope(change);
        }
    }

    public override void andFinally() {
        Helper.ma_runActivationCalculation();
        Helper.gua_runGenUnitAssignment();
    }
}