global class msKAMrequestReminder implements Schedulable {
    global void execute(SchedulableContext sc){
        //Command to set Schedule: System.schedule('KAMWeeklyVPReminder','0 0 8 ? * MON', new msKAMrequestReminder());
        Date deadline = Date.today().toStartOfWeek().addDays(6);
        msKAMrequestReminder(deadline);
    }
    public static void msKAMrequestReminder(Date deadline) {
        List<KAM_request_approver__mdt> requestApprover = [SELECT Approver_id__c FROM KAM_request_approver__mdt WHERE Associated_VP__c != 'AMC'];
        Set<Id> requestApproverIds = new Set<Id>();
        for (KAM_request_approver__mdt approver : requestApprover) {
            requestApproverIds.add(approver.Approver_id__c);
        }
        List<User> requestApproverUsers = [SELECT Id, email FROM User WHERE Id IN :requestApproverIds];
        List<KAM_Request_Dashboard_Settings__c> queryDate = [
            SELECT Id, Query_date__c, SetupOwnerId 
            FROM KAM_Request_Dashboard_Settings__c 
            WHERE VP_Type__c='DAT'];
        List<Task> tasksToInsert = new List<Task>();
        for (User approver : requestApproverUsers) {
            Task KAMreminder = new Task();
            KAMreminder.subject = 'KAM structure - KAM allocation requests for your approval';
            KAMreminder.description = 'Hei, \n\n'+

            'The list of KAM proposals requiring approval has been updated. All requests for initial KAM allocation or KAM change registered in Salesforce up to '+ queryDate[0].Query_date__c.format() +' are now available for review in the Salesforce-based dashboard available here:\n\n'+
            
            System.URL.getSalesforceBaseURL().getHost()+'/lightning/n/KAM_Request_Dashboard \n \n'+
            
            'Deadline for making any adjustments/log a disagreement is set to ' + deadline.format() + '.\n\n'+
            'How to proceed:\n\n'+

            '\u2022 The dashboard is structured in various sections depending on the type of request received (initial KAM allocation, KAM change etc.). \n'+
            
            '\u2022 As a reminder, the approval system is opt-out – by default it is assumed that you approve the attached proposals, unless you voice your disagreements. This is reflected in the “Approval” toggle being always initialized to “approve”. \n'+
            
            '\u2022 You can disagree with any proposal by turning the “Approval” toggle to “Reject”, and add any comment in the “VP comment” field. \n'+
            
            '\u2022 You can delegate the process to anybody, simply use the “Delegate Approval” button on the top right corner of the page. \n'+
            
            '\u2022 Once you click “Save and submit to the AMC” your answers will be locked until the deadline. By default, your answers as saved last will be locked when the deadline is hit. \n\n'+
            
            'The last section of this report, “Key Accounts without KAM” is listing all Salesforce accounts identified as Key but for which no key account manager proposal has been made. \n\n'+
            
            'Feel free to suggest someone for these accounts. \n\n'+
            
            'For any question, feedback or comment, please reach out to AMC@statkraft.com \n\n\n___________';
            KAMreminder.activityDate = deadline;
            KAMreminder.OwnerId = approver.Id;
            tasksToInsert.add(KAMreminder);
        }
        insert tasksToInsert;
    }
}