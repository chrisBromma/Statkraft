public virtual class PortalAction_SwitchSubmeterEditing extends BatchJobBase implements Queueable, Database.RaisesPlatformEvents {
    @TestVisible
    msPortalSystemSetting__mdt portalSystemSettings = msUtility.getPortalSettings();
    public String submeterMode;
    public Boolean enabled;

    public PortalAction_SwitchSubmeterEditing(String mode, Boolean enable) {
        this.submeterMode = mode;
        this.enabled = enable;
    }

    public void execute(QueueableContext QC) {
        if (QC != null) {
            System.attachFinalizer(this);
            super.startLogging(QC?.getJobId());
        }
        Exception caughtException;

        super.logInformation(QC?.getJobId(), 'Started PortalAction_SwitchSubmeterEditing');
        Logger.info('Started PortalAction_SwitchSubmeterEditing');
        Logger.debug('submeterMode: ' + submeterMode);
        Logger.debug('enabled: ' + enabled);

        super.logInformation(QC?.getJobId(), 'Started PortalAction_SwitchSubmeterEditing');
        super.logInformation(QC?.getJobId(), 'submeterMode: ' + submeterMode);
        super.logInformation(QC?.getJobId(), 'enabled: ' + enabled);

        if (!portalSystemSettings.debug_submeter_enabled__c) {
            try {
                super.logInformation(QC?.getJobId(), 'Switching Submeter Editing on');
                Logger.debug('Switching Submeter Editing on');
                super.logInformation(QC?.getJobId(), 'Switching Submeter Editing on');
                msSubmeterUtility.switchSubmeterEditing(submeterMode, enabled);

                if (enabled) {
                    Logger.debug('Notifying Users');
                    super.logInformation(QC?.getJobId(), 'Notifying Users');
                    msSubmeterUtility.issueNotifications(submeterMode);
                }

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                Logger.error('Error in (De-)Activation and Notification', e);
                super.logInformation(QC?.getJobId(), 'Error in (De-)Activation and Notification: ' + e.getMessage());
                caughtException = e;
            } finally {
                Logger.saveLog();
                if (caughtException != null) {
                    throw caughtException;
                }
            }
        } else {
            super.logInformation(QC?.getJobId(), 'Switching Submeter Editing on');
            Logger.info('Skipped (De-)Activation because of Debug Mode being enabled');
            super.logInformation(QC?.getJobId(), 'Skipped (De-)Activation because of Debug Mode being enabled');
            Logger.saveLog();
        }
    }
}