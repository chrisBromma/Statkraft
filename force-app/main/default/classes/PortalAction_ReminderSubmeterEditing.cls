public virtual class PortalAction_ReminderSubmeterEditing extends BatchJobBase implements Queueable, Database.RaisesPlatformEvents {
    String reminderName;

    public PortalAction_ReminderSubmeterEditing(String reminderName) {
        this.reminderName = reminderName;
    }

    public void execute(QueueableContext QC) {
        if(QC != null){
            System.attachFinalizer(this);
            super.startLogging(QC?.getJobId());
        }
        Exception caughtException;

        Logger.info('Started PortalAction_ReminderSubmeterEditing');
        Logger.debug('reminderName: '+reminderName);
        super.logInformation(QC?.getJobId(), 'Started PortalAction_SwitchSubmeterEditing');
        super.logInformation(QC?.getJobId(), 'Started PortalAction_SwitchSubmeterEditing');

        try {
            Logger.debug('Issuing Notifications for Submeter Reminder');
            super.logInformation(QC?.getJobId(), 'Issuing Notifications for Submeter Reminder');

            msSubmeterUtility.issueNotifications(reminderName);

            msUtility.ifTestThrowFakeException();
        } catch (Exception e) {
            Logger.error('Error Sending Submeter Reminder').parseStackTrace(e.getStackTraceString());
            super.logInformation(QC?.getJobId(), 'Error Sending Submeter Reminder: ' + e.getMessage());

            caughtException = e;
        } finally {
            Logger.saveLog();
            if(caughtException != null){
                throw caughtException;
            }
        }
    }
}