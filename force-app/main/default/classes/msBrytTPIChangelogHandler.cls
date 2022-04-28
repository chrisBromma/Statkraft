/****************************************************************************************************
 * Class msBrytTPIChangelogHandler
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 12.02.2019
 *   Description : Trigger Handler for the msBrytTPIChangelog SObject. This class implements the ITrigger
 * 				   interface to help ensure the trigger code is bulkified and all in one place.
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	12.02.2019	Init version.
 *****************************************************************************************************/
public without sharing class msBrytTPIChangelogHandler extends TriggerHandlerExtension {


    List<msBrytTPIChangelog__c> changelogsToDelete = new List<msBrytTPIChangelog__c>();


    public msBrytTPIChangelogHandler() {
        super();

    }

    public override void bulkAfter() {
        if(Trigger.isInsert){
            List<msBrytTPIChangelog__c> currentChangelogs = [SELECT Id, CreatedDate FROM msBrytTPIChangelog__c];
            for(msBrytTPIChangelog__c logItem : currentChangelogs){
                if(Date.today() > logItem.CreatedDate.addDays(60) ){
                    changelogsToDelete.add(logItem);
                }
            }
        }
    }

    public override void andFinally() {
        try{
            delete changelogsToDelete;
        }catch (Exception e){
            System.debug(LoggingLevel.ERROR, 'Exception on msBrytTPIChangelogHandler andFinally: ' + e);
        }
    }
}