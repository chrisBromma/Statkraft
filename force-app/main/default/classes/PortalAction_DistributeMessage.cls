public virtual class PortalAction_DistributeMessage extends BatchJobBase implements Queueable {
    String messageName;

    public PortalAction_DistributeMessage(String messageName) {
        this.messageName = messageName;
    }

    public void execute(QueueableContext ctx) {
        if (ctx != null) {
            super.startLogging(ctx?.getJobId());
            System.attachFinalizer(this);
        }

        Exception caughtException;

        Logger.info('Launching PortalAction_DistributeMessage with: ' + messageName);
        try {
            msNotificationLogic.distributeMessage(null, new List<String>(), messageName, null, null, null, null);

            msUtility.ifTestThrowFakeException();
        } catch (Exception e) {
            Logger.error('Exception when trying to distribute Message', e);
            caughtException = e;
        } finally {
            Logger.saveLog();
            if (caughtException != null) {
                throw caughtException;
            }
        }
    }
}