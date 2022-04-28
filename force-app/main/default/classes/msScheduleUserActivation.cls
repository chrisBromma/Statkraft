/****************************************************************************************************
* Class msScheduleUserActivation
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   12.12.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   12.12.2019      	    Init version.
*****************************************************************************************************/


global without sharing class msScheduleUserActivation implements Schedulable {

    global void execute(SchedulableContext ctx) {
        activateUsers();
        switchClonedRoles();
    }

    global static void activateUsers() {
        BackendMonitoring__e logEvent = msUtility.getEvent('Activate Users');
        List<User> usersToActivate = [
                SELECT Id, Activate_User_at__c
                FROM User
                WHERE Activate_User_at__c != NULL AND Activate_User_at__c <= :Date.today() AND Isactive=false AND (NOT Username LIKE '\_%')
        ];

        for (User tempUser : usersToActivate) {
            tempUser.Activate_User_at__c = null;
            tempUser.IsActive = true;
        }

        try {
            update usersToActivate;

            msUtility.ifTestThrowFakeException();
        } catch (Exception e) {
            logEvent = msUtility.handleException(logEvent, e);
        } finally {
            if (usersToActivate.size() != 0) {
                msUtility.publishEvent(logEvent);
            }
        }
    }
    global static void switchClonedRoles() {
        Date today = Date.today();
        Date yesterday = today.addDays(-1);
        List<Site_Role__c> siteRolesToDeactivate = [
                SELECT Id, Meter__r.Scheduled_Cloning_Date__c, Succeeding_Clone__c, Start_Date__c, End_Date__c
                FROM Site_Role__c
                WHERE Meter__r.Scheduled_Cloning_Date__c =:today
                AND Role__c = 'Customer Portal'
                AND (End_Date__c = NULL OR End_Date__c >= :today)
        ];

        Set<Id> rolesToActivate = new Set<Id>();
        for(Site_Role__c roleToDeactivate : siteRolesToDeactivate) {
            rolesToActivate.add(roleToDeactivate.Succeeding_Clone__c);
        }
        Map<Id,Site_Role__c> siteRolesToActivate = new Map<Id, Site_Role__c>([
                SELECT Id, Start_Date__c FROM Site_Role__c WHERE Id IN :rolesToActivate
        ]);

        for(Site_Role__c roleToDeactivate:siteRolesToDeactivate) {
            siteRolesToActivate.get(roleToDeactivate.Succeeding_Clone__c).Start_Date__c = roleToDeactivate.Start_Date__c;
            if(today <= roleToDeactivate.End_Date__c || roleToDeactivate.End_Date__c == null) {
                roleToDeactivate.End_Date__c = yesterday;
            }
            if(today <= roleToDeactivate.Start_Date__c) {
                roleToDeactivate.Start_Date__c = yesterday;
            }
        }
        update siteRolesToDeactivate;
        update siteRolesToActivate.values();
    }
}