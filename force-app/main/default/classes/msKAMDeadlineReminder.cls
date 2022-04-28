public with sharing class msKAMDeadlineReminder extends BatchJobBase implements Queueable, Database.RaisesPlatformEvents{
    
    public static Date YESTERDAY = Date.today()-1;

    public msKAMDeadlineReminder(){}

    public void execute(QueueableContext ctx){
        System.attachFinalizer(this);
        super.startLogging(ctx?.getJobId());
        sendDeadlineReminder(ctx);
    }

    public void sendDeadlineReminder(QueueableContext ctx) {
        if (oneDayAfterDeadline()) {
            createTasksForAMC(ctx);
        }
    }
    public void createTasksForAMC(QueueableContext ctx){
        super.logInformation(ctx?.getJobId(), 'Tasks are being generated.');
        List<Task> tasksToInsert = new List<Task>();
        for (User amcUser : [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'KAM AMC')]) {
            Task processKAMRequest = new Task(
                    Subject = 'Process KAM Request approval batch',
                    Description = 'https://statkraft-crm.lightning.force.com/lightning/r/Report/00O1v000008YsozEAC/view',
                    Priority = 'Normal',
                    Status = 'Open',
                    OwnerId = amcUser.Id
            );
            tasksToInsert.add(processKAMRequest);
        }
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.emailHeader.triggerUserEmail = true;
        Database.insert(tasksToInsert, dmlOptions);
        super.logInformation(tasksToInsert, ctx?.getJobId(), 'Generated ' + tasksToInsert.size() + ' Tasks.');
    }
    public Boolean oneDayAfterDeadline(){
        return KAM_Request_Dashboard_Settings__c.getOrgDefaults().Deadline__c == YESTERDAY;
    }

}