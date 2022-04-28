/****************************************************************************************************
* Class msBatchTerminateOffers
*
*   Create By	:   ChristianGottlieb (mindsquare AG)
*   Create Date	:   2020-09-01
*   Description	:	Warning, dew to too much Flow Automation the Batch size needs to be decreased to
 *                  at most 50.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare AG)	            2020-09-01       	Init version.
*   * Dennis Grzyb (mindsquare AG)   	            2021-07-15       	Extend BatchJobBase for Scheduler Framework.
*****************************************************************************************************/

global with sharing class msBatchTerminateOffers extends BatchJobBase implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {
    
    global msBatchTerminateOffers(){}

    global List<Offer__c> start(Database.BatchableContext bc) {
        super.startLogging(BC?.getJobId());
        return [
                SELECT Id, Valid_Until__c, Reason_Offer_Lost__c, Other_Reason_Lost__c
                FROM Offer__c
                WHERE Workflow_Type__c = 'Cancellation Amendment'
                AND Valid_Until__c = YESTERDAY
                AND Status__c != 'Closed Won'
                AND Status__c != 'Rejected - New Offer'
                AND Status__c != 'Closed Lost'
                AND REMIT_Reporting_Relevant__c = TRUE
        ];
    }

    global void execute(Database.BatchableContext bc, List<Offer__c> scope) {
        super.logInformation(scope, bc?.getJobId(), 'Found ' + scope.size() + ' records.');
        for (Offer__c offerToClose : scope) {
            offerToClose.Status__c = 'Closed Lost';
            if (offerToClose.Other_Reason_Lost__c == null) {
                offerToClose.Other_Reason_Lost__c =  Datetime.now().format('dd.MM.yyyy', '') + ' - Automated termination due to expiration of the validity period (Default 25 Days)';
            } else {
                offerToClose.Other_Reason_Lost__c += ' - ' + Datetime.now().format('dd.MM.yyyy', '') + ' - Automated termination due to expiration of the validity period (Default 25 Days)';
                if(offerToClose.Other_Reason_Lost__c.length() > 255) {
                    offerToClose.Other_Reason_Lost__c = offerToClose.Other_Reason_Lost__c.left(252) + '...';
                }
            }
        }
        update scope;
        super.logEndOfBatch(scope, BC?.getJobId(), true, 'Finished processing.');
    }

    global void finish(Database.BatchableContext bc) {
        super.finishBatch(BC.getJobId());
    }

}