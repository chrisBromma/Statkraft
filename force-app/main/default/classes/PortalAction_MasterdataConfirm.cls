/**
 *   Create By	 : Georg Luch (Statkraft)
 *   Create Date : 22.09.2021
 *   Description : Queries these contracts:
 *                  - German contracts
 *                  - Contract__c.Customer_Portal_Master_Data_Update__c is unchecked (FALSE)
 *                 and sends ONE email to all contacts, which have an active contract-role.
 *   Ticket:       https://statkraftonjira.atlassian.net/browse/PIM-1355
 *
 *   Confluence-
 *   Documentation:https://statkraft.atlassian.net/wiki/spaces/MC/pages/3298820175/my.statkraft.com+-+Commercial+Master+Data
 *
 *   Hint: messageType == notificationType == reminderName (=or whatever variable-name you like, it´s all the same)
 */

public virtual class PortalAction_MasterdataConfirm extends BatchJobBase implements Queueable {
    String notificationType; // Can be "masterdata_confirmation" or "masterdata_confirmation_reminder"

    public PortalAction_MasterdataConfirm(String notificationType) {
        // Constructor
        this.notificationType = notificationType;
    }

    public void execute(QueueableContext QC) {
        if (QC != null) {
            super.startLogging(QC?.getJobId());
            System.attachFinalizer(this);
        }
        Exception caughtException;

        try {
            List<Id> contractList = new List<Id>(getContractListIdsForMasterdataConfirmationNotification());
            msNotificationLogic.distributeMessage(
                'Contract__c',
                contractList,
                notificationType,
                null,
                null,
                null,
                null
            );

            msUtility.ifTestThrowFakeException();
        } catch (Exception e) {
            Logger.error('Error Sending Notification Masterdata Confirmation').parseStackTrace(e.getStackTraceString());
            Logger.saveLog('Masterdata - Notification: ERROR');
            caughtException = e;
        } finally {
            if (caughtException != null) {
                throw caughtException;
            }
        }
    }

    /**
     * @description Subset of contracts, which are to be notified about masterdata-confirmation
     * @return Set<Id>
     * */
    public Set<Id> getContractListIdsForMasterdataConfirmationNotification() {
        Integer currentYear = System.today().year();
        Date d = Date.newInstance(currentYear, 1, 1);

        List<Contract__c> contractsToNotify = new List<Contract__c>(
            [
                SELECT Id
                FROM Contract__c
                WHERE
                    Id IN (
                        SELECT Contract__c
                        FROM Contract_Role__c
                        WHERE
                            Contract__r.Status__c IN ('Active', 'Expired')
                            AND Contract__r.Country_Code__c = 'DE'
                            AND Contract__r.Customer_Portal_Master_Data_Update__c = FALSE
                            AND Role__c = 'Customer Portal'
                    )
                    AND End_Date__c >= :d
            ]
        );

        Set<Id> contractIds = new Set<Id>();
        for (Contract__c contractId : contractsToNotify) {
            contractIds.add(contractId.Id);
        }

        return contractIds;
    }
}