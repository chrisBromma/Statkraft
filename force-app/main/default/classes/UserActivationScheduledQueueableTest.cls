@isTest
public with sharing class UserActivationScheduledQueueableTest {
    @TestSetup
    private static void testSetup() {
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__c.SObjectType);

        msTestDataFactory.createTestPortalContext();
        
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__c.SObjectType);
    }   
    
    @IsTest
    static void testActivation() {
        UserActivationScheduledQueueable UserActivationScheduledQueueable = new UserActivationScheduledQueueable();
        
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() AND isActive = true LIMIT 1];
        System.runAs(u){
            User portalUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
            portalUser.Activate_User_at__c = Date.today();
            portalUser.IsActive = false; 
            update portalUser;
        }

        Test.startTest();
        System.enqueueJob(UserActivationScheduledQueueable);
        Test.stopTest();
    }

    @IsTest
    static void testClonedActivation() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Id meterToCloneId = null;
        System.runAs(testUser) {
            msUtility.UserDetails testUserDetails = msUtility.getUserDetails();
            meterToCloneId = testUserDetails.plants[0].Id;
        }
        Site_Role__c cloningAffectedRole = new Site_Role__c(
            Name = 'Role to Clone',
            Meter__c = meterToCloneId,
            Contact__c = testUser.ContactId,
            Start_Date__c = Date.today().addDays(-7),
            Role__c = 'Customer Portal'
        );
        insert cloningAffectedRole;
        msCloneMeterFromRest.cloneMeter(meterToCloneId, Date.today(), false);
        Map<Id, Date> originalStartDate = new Map<Id, Date>();
        Map<Id, Date> originalEndDate = new Map<Id, Date>();
        for (Site_Role__c originalSiteRole : [SELECT Id, Start_Date__c, End_Date__c FROM Site_Role__c WHERE Meter__c = :meterToCloneId]) {
            originalStartDate.put(originalSiteRole.Id, originalSiteRole.Start_Date__c);
            originalEndDate.put(originalSiteRole.Id, originalSiteRole.End_Date__c);
        }
        Test.startTest();
        UserActivationScheduledQueueable queueable = new UserActivationScheduledQueueable();
        queueable.switchClonedRoles(null);
        Test.stopTest();
        Id cloneMeterId = [SELECT Succeeding_Clone__c FROM Meter__c WHERE Id = :meterToCloneId].Succeeding_Clone__c;
        Set<Id> contextMeters = new Set<Id>();
        contextMeters.add(meterToCloneId);
        contextMeters.add(cloneMeterId);
        Map<Id, Site_Role__c> contextSiteRoles = new Map<Id, Site_Role__c>(
            [
                SELECT Id, Name, Start_Date__c, End_Date__c, Meter__c, Meter__r.Name, Role__c, Succeeding_Clone__c
                FROM Site_Role__c
                WHERE Meter__c IN :contextMeters
            ]
        );
        for (Site_Role__c roleToCheck : contextSiteRoles.values()) {
            if (roleToCheck.Meter__c == meterToCloneId) {
                System.assert(roleToCheck.Start_Date__c < Date.today(), 'Start Date of cloned role is not in past');
                System.assert(roleToCheck.End_Date__c < Date.today(), 'End Date of cloned role is not in past');
                if (originalEndDate.get(roleToCheck.Id) >= Date.today() || originalEndDate.get(roleToCheck.Id) == null) {
                    System.assert(
                        contextSiteRoles.get(roleToCheck.Succeeding_Clone__c).Start_Date__c == originalStartDate.get(roleToCheck.Id),
                        'Start Date was not preserved'
                    );
                    System.assert(
                        contextSiteRoles.get(roleToCheck.Succeeding_Clone__c).End_Date__c == originalEndDate.get(roleToCheck.Id),
                        'End Date was not preserved'
                    );
                }
            } else if (roleToCheck.Meter__c == cloneMeterId) {
                System.assert(roleToCheck.End_Date__c >= Date.today() || roleToCheck.End_Date__c == null, 'End Date of role clone not correct');
            } else {
                System.assert(false, 'Meter Id not properly set up');
            }
        }
    }
}