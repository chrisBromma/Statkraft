/****************************************************************************************************
* Class msScheduledActivateMetersAndUnits
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-07-15
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-07-15       	Init version.
*****************************************************************************************************/

global class msScheduledActivateMetersAndUnits implements Schedulable {
    global void execute(SchedulableContext ctx) {
        activateMeters();
        activateGenUnits();
    }
    global static void activateMeters() {
        msBatchActivateMeters mBAM = new msBatchActivateMeters();
        Database.executeBatch(mBAM);
    }

    global static void activateGenUnits() {
        msBatchActivateGenUnits mBAGU = new msBatchActivateGenUnits();
        Database.executeBatch(mBAGU);
    }

}