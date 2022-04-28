global without sharing class msPerformanceIndicatorRollupBatch implements Database.Batchable<SObject>, Database.Stateful {


    global Set<Id> contractsIdsWithMissingPreviousVersions;
    global Set<Id> contractsIdsWithMissingPerformanceIndicators;
    global Map<Id, SObjectField> corruptedPerformanceIndicatorsByIds;

    private static final Id DE_EEG_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = :'DE EEG' LIMIT 1].Id;
    private static final Id INDIA_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = :'India' LIMIT 1].Id;

    global msPerformanceIndicatorRollupBatch() {

        contractsIdsWithMissingPreviousVersions = new Set<Id>();
        contractsIdsWithMissingPerformanceIndicators = new Set<Id>();
        corruptedPerformanceIndicatorsByIds = new Map<Id, SObjectField>();
    }

    global List<Account> start(Database.BatchableContext bc) {
        Set<Id> validProfileIds = new Set<Id>();
        validProfileIds.add(DE_EEG_PROFILE_ID);
        validProfileIds.add(INDIA_PROFILE_ID);
        return [
                SELECT Id, Negotiating_Party__c,
                (SELECT Id, Negotiating_Party__c FROM Accounts1__r)
                FROM Account 
                WHERE Negotiating_Party__c = NULL
                AND Owner.ProfileId IN :validProfileIds
        ];
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        msPerformanceIndicatorRollupHelper performanceIndicatorHelper = new msPerformanceIndicatorRollupHelper();
        performanceIndicatorHelper.execute(scope);
        collectErrors(performanceIndicatorHelper);
    }

    global void finish(Database.BatchableContext BC) {
        //sendErrorNotifications();
    }

    private void collectErrors(msPerformanceIndicatorRollupHelper performanceIndicatorHelper) {
        if(contractsIdsWithMissingPreviousVersions == null) {
            contractsIdsWithMissingPreviousVersions.addAll(performanceIndicatorHelper.getContractIdsWithMissingVersions());
        }
        contractsIdsWithMissingPerformanceIndicators.addAll(performanceIndicatorHelper.getContractsIdsWithMissingPerformanceIndicators());
        corruptedPerformanceIndicatorsByIds.putAll(performanceIndicatorHelper.getCorruptedPerformanceIndicatorsByIds());
    }
/*
    private void sendErrorNotifications() {

        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        Boolean shouldSendEmails = true;
        Id recipientId;
        try {
            recipientId = Id.valueOf(apiSettings.Default_PI_Rollup_Batch_Error_Recipient__c);
        } catch (Exception e) {
            shouldSendEmails = false;
        }
        if(shouldSendEmails) {
            String subject = 'Errors calculating Performance Indicator rollups';
            String body = '';
            if(corruptedPerformanceIndicatorsByIds != null && !corruptedPerformanceIndicatorsByIds.isEmpty()) {
                body += 'Following Performance Indicators are missing values: ';
                for(Id key : corruptedPerformanceIndicatorsByIds.keySet()) {
                    body += '<a href="'+ Url.getOrgDomainUrl().toExternalForm()+'/lightning/r/Performance_Indicator__c/'+ key + '/view">' + corruptedPerformanceIndicatorsByIds.get(key).getDescribe().getLabel() + '</a>, ';
                }
                body = body.removeEnd(', ');
            }
            if(!contractsIdsWithMissingPreviousVersions.isEmpty()) {
                body += '\nFollowing Contracts are missing previous versions: ';
                for(Id key : contractsIdsWithMissingPreviousVersions) {
                    body += '<a href="'+ Url.getOrgDomainUrl().toExternalForm()+'/lightning/r/Contract__c/'+ key + '/view">' + key + '</a>, ';
                }
                body = body.removeEnd(', ');
            }
            if(!contractsIdsWithMissingPerformanceIndicators.isEmpty()) {
                body += '\nFollowing Contracts are missing Performance Indicators: ';
                for(Id key : contractsIdsWithMissingPerformanceIndicators) {
                    body += '<a href="'+ Url.getOrgDomainUrl().toExternalForm()+'/lightning/r/Contract__c/'+ key + '/view">' + key + '</a>, ';
                }
                body = body.removeEnd(', ');
            }
            sendEmail(recipientId, subject, body);
        }
    }

    private void sendEmail(Id recipient, String subject, String body) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setTargetObjectId(recipient);
        email.saveAsActivity = false;
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }*/
}