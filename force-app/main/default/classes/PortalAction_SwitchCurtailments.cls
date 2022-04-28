public virtual class PortalAction_SwitchCurtailments extends BatchJobBase implements Queueable, Database.RaisesPlatformEvents {
    Boolean unlockCurtailments;

    public PortalAction_SwitchCurtailments(Boolean unlock) {
        this.unlockCurtailments = unlock;
    }

    public void execute(QueueableContext qc) {
        if (qc != null) {
            System.attachFinalizer(this);
            super.startLogging(QC?.getJobId());
        }
        Exception caughtException;

        Logger.info('Started PortalAction_SwitchCurtailments');
        super.logInformation(QC?.getJobId(), 'Started PortalAction_SwitchCurtailments');
        try {
            super.logInformation(
                QC?.getJobId(),
                'Switching Availability of Curtailments (true -> unlock, false -> lock): ' + this.unlockCurtailments
            );
            Logger.debug(
                'Switching Availability of Curtailments (true -> unlock, false -> lock): ' + this.unlockCurtailments
            );
            super.logInformation(
                qc?.getJobId(),
                'Switching Availability of Curtailments (true -> unlock, false -> lock): ' + this.unlockCurtailments
            );
            msCurtailmentLockHandler.switchCurtailmentUnlock(unlockCurtailments);

            msUtility.ifTestThrowFakeException();
        } catch (Exception e) {
            Logger.error('Exception while switching availability of Curtailments', e);
            super.logInformation(
                qc?.getJobId(),
                'Exception while switching availability of Curtailments: ' + e.getMessage()
            );
            caughtException = e;
        } finally {
            Logger.saveLog();
            if (caughtException != null) {
                throw caughtException;
            }
        }
    }
}