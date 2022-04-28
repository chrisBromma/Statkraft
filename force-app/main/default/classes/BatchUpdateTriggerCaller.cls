/**************************************************************************************************** 
* Class BatchUpdateTriggerCaller 
* 
*   Created By :   Fabian Murk (mindsquare AG) 
*   Create Date :   17.06.2021 
*   Description :   This can be used if you have made a change to a trigger and want the data to be updated
*                   on all records according to trigger logic.
* 
*   Modification Log: 
*   ------------------------------------------------------------------------------------------------- 
*   * Developer                        Date             Description 
*   * -----------------------------------------------------------------------------------------------                  
*   * Fabian Murk (mindsquare AG)      17.06.2021         Init version. 
*****************************************************************************************************/

global without sharing class BatchUpdateTriggerCaller implements Database.Batchable<SObject>, Database.Stateful {
    public String SObjectType;
    public static String QueryString = 'SELECT Id FROM ';

    global Database.QueryLocator start(Database.BatchableContext ctx) {
        String query = QueryString + SObjectType;
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<SObject> sObjects) {
        update sObjects;
    }
    global void finish(Database.BatchableContext BC) {

    }
    public BatchUpdateTriggerCaller (String SObjectTypeString){
        SObjectType = SObjectTypeString;
    }
}