public with sharing class NpaiDeadlineNotifScheduledQueueable extends BatchJobBase implements Queueable, Database.RaisesPlatformEvents {
    public static final String ASSESSMENT_DUE_TEMPLATE_NAME = 'AssessmentDue';
    public static final String IMPLEMENTATION_DUE_TEMPLATE_NAME = 'ImplementationDue';
    public static final String JOB_NAME = Test.isRunningTest() ? 'Test Deadline Notification' : 'Deadline Notification';
    public static final String CRON_EXPRESSION = '0 0 7 * * ? *';

    @TestVisible
    private static Integer amountEmailInvocations;

    public void execute(QueueableContext ctx) {
        System.attachFinalizer(this);
        super.startLogging(ctx?.getJobId());

        Date dateTomorrow = Date.today().addDays(1);
        Date dateThreeDaysInTheFuture = Date.today().addDays(3);
        Map<Id, Implementation__c> implementationIdByRecipientIdMap = new Map<Id, Implementation__c>();
        Map<Id, NPC_Assessment__c> assessmentIdByRecipientIdMap = new Map<Id, NPC_Assessment__c>();

        for (Implementation__c implementationDue : [
            SELECT Id, OwnerId, CreatedBy.Name, CreatedBy.Email
            FROM Implementation__c
            WHERE EndDate__c IN (:dateTomorrow, :dateThreeDaysInTheFuture) AND Implementation_Status__c != 'done'
        ]) {
            implementationIdByRecipientIdMap.put(implementationDue.Id, implementationDue);
        }
        super.logInformation(implementationIdByRecipientIdMap.values(), ctx?.getJobId(), 'Found ' + implementationIdByRecipientIdMap.values().size() + ' Implementations to send an Email for.');

        for (NPC_Assessment__c assessmentsDue : [
            SELECT Id, OwnerId, CreatedBy.Name, CreatedBy.Email
            FROM NPC_Assessment__c
            WHERE Deadline__c IN (:dateTomorrow, :dateThreeDaysInTheFuture) AND Status2__c != 'Done'
        ]) {
            assessmentIdByRecipientIdMap.put(assessmentsDue.Id, assessmentsDue);
        }
        super.logInformation(assessmentIdByRecipientIdMap.values(), ctx?.getJobId(), 'Found ' + assessmentIdByRecipientIdMap.values().size() + ' Assessments to send an Email for.');

        OrgWideEmailAddress orgAddress = getNpaiOrgAddress();
        msNotificationLogic.sendTemplatedEmailToAddressesForRecords(orgAddress, implementationIdByRecipientIdMap, IMPLEMENTATION_DUE_TEMPLATE_NAME);
        msNotificationLogic.sendTemplatedEmailToAddressesForRecords(orgAddress, assessmentIdByRecipientIdMap, ASSESSMENT_DUE_TEMPLATE_NAME);

        amountEmailInvocations = Limits.getEmailInvocations();
        super.logInformation(ctx?.getJobId(), 'Sent ' + amountEmailInvocations + ' Emails.');
    }

    private OrgWideEmailAddress getNpaiOrgAddress() {
        List<OrgWideEmailAddress> orgAddresses = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'npai_salesforce@statkraft.com'];
        return orgAddresses.isEmpty() ? null : orgAddresses[0];
    }
}