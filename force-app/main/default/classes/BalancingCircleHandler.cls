/****************************************************************************************************
* Class BalancingCircleHandler
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-02-16
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-02-16       	Init version.
*   * Dennis Grzyb (mindsquare AG)	                    2021-05-18       	Switched Frameworks, remove dependency on Sandbox Migration Id   
*****************************************************************************************************/

public without sharing class BalancingCircleHandler extends TriggerHandlerExtension  {
    private static Set<String> validBalancingCircleNames = new Set<String>();

    // Constructor
    public BalancingCircleHandler() {
        super();
    }


    public override void bulkBefore() {
        if(Trigger.isInsert){
            SandboxMigrationIdGenerator.populate((List<Balancing_Circle__c>) Trigger.new, false);
        }
        getValidBalancingCircleNames();   
    }

    public override void beforeInsert(SObject obj) {        
        Balancing_Circle__c newCircle = (Balancing_Circle__c) obj;
        validateAndStoreBalancingCircleName(newCircle);
    }


    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Balancing_Circle__c newCircle = (Balancing_Circle__c) obj;
        validateAndStoreBalancingCircleName(newCircle);
    }

    private void getValidBalancingCircleNames(){
        List<PicklistEntry> picklistEntriesBalancingCircle = MeterRegistration__c.Balancing_Circle__c.getDescribe().getSobjectField().getDescribe().getPicklistValues();
        for (PicklistEntry entryItem : picklistEntriesBalancingCircle) {
            validBalancingCircleNames.add(entryItem.value);
        }
    }

    private void validateAndStoreBalancingCircleName(Balancing_Circle__c newCircle){
        if(!validBalancingCircleNames.contains(newCircle.Name)) {
            newCircle.addError(Label.validationErrorBalancingCircleNameIncorrect);
        } else {
            newCircle.Deduplication_Id__c = newCircle.Name;
        }
    }
}