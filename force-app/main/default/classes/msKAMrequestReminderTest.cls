@isTest
public with sharing class msKAMrequestReminderTest {
    @isTest
    public static void testmsKAMrequestReminder() {
        KAM_Request_Dashboard_Settings__c setting = new KAM_Request_Dashboard_Settings__c();
        setting.Name = 'Test Setting';
        setting.Query_date__c = Date.today();
        setting.VP_Type__c = 'DAT';
        insert setting;
        msKAMrequestReminder.msKAMrequestReminder(Date.today());
        List<KAM_request_approver__mdt> requestApprover = [SELECT Approver_id__c FROM KAM_request_approver__mdt WHERE Associated_VP__c != 'AMC'];
        System.debug(requestApprover);
        Set<Id> requestApproverIds = new Set<Id>();
        for (KAM_request_approver__mdt approver : requestApprover) {
            requestApproverIds.add(approver.Approver_id__c);
        }
        List<Task> createdTasks = [SELECT Subject FROM Task WHERE Subject = 'KAM structure - KAM allocation requests for your approval' AND OwnerId IN :requestApproverIds];
        
        System.assertEquals(requestApproverIds.size(), createdTasks.size());

    }
}