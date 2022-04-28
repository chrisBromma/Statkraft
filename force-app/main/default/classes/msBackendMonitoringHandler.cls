/****************************************************************************************************
* Class msBackendMonitoringHandler
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   11.03.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   11.03.2020      	    Init version.
*****************************************************************************************************/


public with sharing class msBackendMonitoringHandler extends TriggerHandlerExtension {
    public List<Activity_log__c> newActivityLogs = new List<Activity_log__c>();

    public msBackendMonitoringHandler() {
        super();
    }

    public override void afterInsert(SObject obj) {
        addToLoopCount();

        BackendMonitoring__e event = (BackendMonitoring__e) obj;
        Activity_log__c log = new Activity_log__c();
        log.Name = event.Method__c;
        log.IsError__c = event.IsError__c;
        log.date_from__c=event.Start__c;
        log.date_to__c=event.End__c;
        log.Message__c=event.Message__c;
        log.data_json__c=event.DataJson__c;
        log.UserName__c=event.CreatedById;
        log.plant_name__c =event.MeterId__c;

        newActivityLogs.add(log);
    }


    public override void andFinally() {
        if (!newActivityLogs.isEmpty()) {
            insert newActivityLogs;
        }
    }
}