/****************************************************************************************************
* Class msBrytWhatsGoingOnController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   19.11.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   19.11.2018      	    Init version.
*****************************************************************************************************/

public with sharing class msBrytWhatsGoingOnController {

    @AuraEnabled
    public static List<Bryt_Portal_Bulletin__c> getBulletins() {
        List<Bryt_Portal_Bulletin__c> result = [
                SELECT Name, Text__c, Publication_Date__c, is_Active__c, Color__c
                FROM Bryt_Portal_Bulletin__c
                WHERE is_Active__c = TRUE
                AND End_Date__c >= :Date.today()
                AND Publication_Date__c <= :Datetime.now()
                ORDER BY Publication_Date__c DESC
                LIMIT 10
        ];
        return result;
    }
}