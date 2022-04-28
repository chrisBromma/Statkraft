/****************************************************************************************************
* Class msBatchProductionMails
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   12.06.2019
*   Description	:	This Batch Job runs over all Portal Users of the Global Customer Portal and sends them
*                   a (monthly) CSV,Excel (collection) of their related Meters production data, depending on their
*                   User Notification Setting
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            12.06.2019       	Init version.
*   * Christian Gottlieb (mindsquare GmbH)	            07.01.2020       	With Constructor and part of
*                                                                           Notification Framework now
*   * Lukasz Bak (mindsquare GmbH)	                    31.03.2020       	Log error cases where 
*   *                                                                       attachment was not available
*****************************************************************************************************/

global with sharing class msBatchProductionMails implements
                Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {


    private static final String MONTHLY_EMAIL_NOTIFICATION_TYPE = 'monthly_production_data';
    private static final TimeZone PLANT_TIMEZONE = TimeZone.getTimeZone('Europe/Berlin');
    private static final Date THIS_DAY = Date.today();

    public msNotificationLogic.debugModeWrapper DEBUG_MODE;
    public Map<Id,msNotificationLogic.notificationWrapper> USER_ID_TO_MESSAGE_MAP = new Map<Id, msNotificationLogic.notificationWrapper>();
    public Map<String, String> portfolioIdToErrorLogMessage = new Map<String, String>();
    public Id owaId = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply-salesforce@statkraft.com'].Id;
    public Id templateId = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = 'Community_Notifications' LIMIT 1].Id;

    global msBatchProductionMails(List<msNotificationLogic.notificationWrapper> messageWrappers, msNotificationLogic.debugModeWrapper debugMode) {
        DEBUG_MODE = debugMode;
        for(msNotificationLogic.notificationWrapper messageWrapperItem : messageWrappers) {
            USER_ID_TO_MESSAGE_MAP.put(messageWrapperItem.userId, messageWrapperItem);
        }
    }

    global List<User> start(Database.BatchableContext bc) {
        List<User> globalScope = [SELECT Id, ContactId, IsActive FROM User WHERE Id IN :USER_ID_TO_MESSAGE_MAP.keySet()];
        return globalScope;
    }

    global void execute(Database.BatchableContext bc, List<User> scope) {
        Map<Id, User> usersToContactIds = getUsersByContactIds(scope);
        Map<Id, String> fileFormatToContactIds = new Map<Id, String>();
        List<msUserNotificationSetting__c> notificationSettings = getUserNotificationSettings(usersToContactIds.keySet());
        Set<Id> contactsToReceiveEmail = new Set<Id>();
        for (msUserNotificationSetting__c setting : notificationSettings) {
            contactsToReceiveEmail.add(setting.msContact__c);
            fileFormatToContactIds.put(setting.msContact__c, setting.msFileFormat__c);
        }
        List<Site_Role__c> siteRoles = getSiteRoles(contactsToReceiveEmail);
        Set<Id> meterIds = new Set<Id>();
        Set<String> parentIds = new Set<String>();

        for (Site_Role__c siteRole : siteRoles) {
            if (String.isNotBlank(siteRole.Meter__r.Parent_Meter__c)) {
                if (! parentIds.contains(siteRole.Meter__r.Parent_Meter__c)) {
                    meterIds.add(siteRole.Meter__c);
                }
                parentIds.add(siteRole.Meter__r.Parent_Meter__c);
            }else{
                meterIds.add(siteRole.Meter__c);
            }
        }

        Map<Id, Meter__c> metersToIds = getMetersByIds(meterIds);
        Map<Id, Set<Meter__c>> metersByContactIds = new Map<Id, Set<Meter__c>>();

        for(Site_Role__c siteRole : siteRoles) {
            if(metersToIds.containsKey(siteRole.Meter__c)) {
                if(metersByContactIds.containsKey(siteRole.Contact__c)) {
                    metersByContactIds.get(siteRole.Contact__c).add(metersToIds.get(siteRole.Meter__c));
                }
                else {
                    metersByContactIds.put(siteRole.Contact__c, new Set<Meter__c>{metersToIds.get(siteRole.Meter__c)});
                }
            }
        }

        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        String endPoint = apiSettings.Production_Files_Endpoint__c;
        String apiKey = apiSettings.Statkraft_API_Key__c;
        String method = 'GET';


        Messaging.SingleEmailMessage emailTemplate = Messaging.renderStoredEmailTemplate(templateId, null, null);

        Datetime startDateTime = Datetime.newInstance(THIS_DAY.addMonths(-1).toStartOfMonth(), Time.newInstance(0, 0, 0, 0));
        Datetime endDateTime = Datetime.newInstance(THIS_DAY.toStartOfMonth(), Time.newInstance(0, 0, 0, 0));
        String fileNameStartDate = startDateTime.format('yyyy-MM-dd');
        String fileNameEndDate = endDateTime.addDays(-1).format('yyyy-MM-dd');
        String startDate = formatDateToUTC(startDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),PLANT_TIMEZONE);
        String endDate = formatDateToUTC(endDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),PLANT_TIMEZONE);

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for(Id contactId : metersByContactIds.keySet()) {
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            for(Meter__c meter : metersByContactIds.get(contactId)) {
                String fileFormat = fileFormatToContactIds.get(contactId);
                String portfolioId = String.isNotBlank(meter.Parent_Meter__c) ? meter.Parent_Meter__r.Portfolio_ID__c : meter.Portfolio_ID__c;
                String path = '/' + portfolioId + apiSettings.Settlement_Timeseries_Path__c;
                String title = msUtility.getLeftPartOfStringRelativeToLastDivider(meter.Name, '/DE');
                String body = getRequestBody(startDate, endDate, path, fileFormat, title);
                if(!Test.isRunningTest()) {
                    HttpResponse response = msUtility.getHttp(endPoint, body, method, apiKey);
                    for(String header : response.getHeaderKeys()) {
                        System.debug(header + ' : ' + response.getHeader(header));
                    }
                    if(response.getStatus() == 'OK' && response.getBody() != null) {
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        Blob blobFile = EncodingUtil.base64Decode(response.getBody());
                        attachment.setBody(blobFile);
                        String fileName = getFileName(fileNameStartDate, fileNameEndDate, title, fileFormat);
                        attachment.setFileName(fileName);
                        attachments.add(attachment);
                    } else{
                        if (!portfolioIdToErrorLogMessage.containsKey(meter.Portfolio_ID__c)) {
                            portfolioIdToErrorLogMessage.put(meter.Portfolio_ID__c, response.getStatus()+', \n'+response.getBody());
                        }
                    }
                }

            }
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setFileAttachments(attachments);


            message.setOrgWideEmailAddressId(owaId);
            message.setUseSignature(false);
            message.setBccSender(false);
            message.setSaveAsActivity(false);
            message.setOptOutPolicy('FILTER');
            msNotificationLogic.notificationWrapper messageWrapper = USER_ID_TO_MESSAGE_MAP.get(usersToContactIds.get(contactId).Id);
            message.setSubject(messageWrapper.subject);
            String body = emailTemplate.getHtmlBody();
            body = body.replaceAll('##BODY##', messageWrapper.body);
            message.setHtmlBody(body);

            if(DEBUG_MODE.messageType != 'monthly_production_data') {
                message.setTargetObjectId(usersToContactIds.get(contactId).Id);
            } else if(DEBUG_MODE.userTargetId != null) {
                message.setTargetObjectId(DEBUG_MODE.userTargetId);
            }
            if(!message.getFileAttachments().isEmpty() &&
                    (DEBUG_MODE.messageType != 'monthly_production_data' || DEBUG_MODE.userTargetId != null)) {
                messages.add(message);
            }
        }
        Messaging.sendEmail(messages);
    }

    global void finish(Database.BatchableContext bc) {
        if(!portfolioIdToErrorLogMessage.isEmpty()){
            String errorMessageBody = buildErrorLogMessageBody();
            publishBackendMonitoringLogEvent(errorMessageBody);
            sendErrorLogEmail(errorMessageBody);
        }
    }

    public static String getRequestBody(String startDate, String endDate, String path, String format, String title) {
        Map<String, Object> requestParams = new Map<String, Object>();
        requestParams.put('Resolution', 'PT15M');
        requestParams.put('Unit', 'KWH');
        requestParams.put('End', endDate);
        requestParams.put('Begin', startDate);
        requestParams.put('Path', path);
        requestParams.put('TemplateName', 'eeg_settlement_report');
        requestParams.put('Format', format);
        requestParams.put('Title', title);
        requestParams.put('encoding', 'base64');
        return JSON.serialize(requestParams);
    }

    private Map<Id, User> getUsersByContactIds(List<User> scope) {
        Map<Id, User> usersByContactIds = new Map<Id, User>();
        for (User user : scope) {
            usersByContactIds.put(user.ContactId, user);
        }
        return usersByContactIds;
    }

    private List<msUserNotificationSetting__c> getUserNotificationSettings(Set<Id> contactIds) {
        return [
                SELECT msContact__c, msNotificationType__c, msFileFormat__c
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = :MONTHLY_EMAIL_NOTIFICATION_TYPE
                AND msContact__c IN :contactIds
                AND msIsEmail__c = TRUE
        ];

    }

    private List<Site_Role__c> getSiteRoles(Set<Id> contactIds) {
        return [
                SELECT Contact__c, Meter__c, Meter__r.Portfolio_ID__c, Meter__r.Parent_Meter__c
                FROM Site_Role__c
                WHERE Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
                AND Contact__c IN :contactIds
                AND Role__c INCLUDES ('Customer Portal')
                AND Meter__r.Portfolio_ID__c != NULL
                AND Meter__r.Country__c = 'Germany'
        ];
    }

    private Map<Id, Meter__c> getMetersByIds(Set<Id> meterIds) {
        return new Map<Id, Meter__c>([
                SELECT Id, Name, Country__c, Portfolio_ID__c, Parent_Meter__r.Portfolio_ID__c
                FROM Meter__c
                WHERE Id IN (
                        SELECT Meter__c
                        FROM MeterRegistration__c
                        WHERE Contract__r.Status__c = 'Active'
                        AND Valid_from__c <= :Date.today()
                        AND (Valid_to__c >= :Date.today() OR Valid_to__c = NULL)
                        AND Meter__c IN :meterIds
                )
        ]);
    }

    private String getFileName(String startDate, String endDate, String meterName, String fileFormat) {
        String fileName = meterName + '_Production_Data_From_' + startDate.substring(0, 10) +
                '_to_' + endDate.substring(0, 10);
        if(fileFormat == 'excel') {
            fileName += '.xlsx';
        }
        else {
            fileName += '.csv';
        }
        return fileName;
    }

    public static String formatDateToUTC(String oldDate, TimeZone plantTimeZone) {

        // format the date to UTC timezone
        Datetime formatedDate = (Datetime) JSON.deserialize('"' + oldDate + '"', Datetime.class);
        Long timeDifference = plantTimeZone.getOffset(formatedDate);
        Long newTime = formatedDate.getTime() - timeDifference;
        Datetime newDate = Datetime.newInstance(newTime);

        //check if datetime was near change of summer or winter time
        Datetime formatedDate2 = formatedDate.addHours(-1);
        Long timeDifference2 = plantTimeZone.getOffset(formatedDate2);
        if (timeDifference != timeDifference2) {
            if (formatedDate.month() == 3) {
                newDate = newDate.addHours(1);
            }
            if (formatedDate.month() == 10) {
                newDate = newDate.addHours(-1);
            }
        }

        String finalDate = newDate.formatGmt('yyyy-MM-dd') + 'T' + newDate.formatGmt('HH:mm:ss') + 'Z';
        return finalDate;
    }

    private static void publishBackendMonitoringLogEvent(String messageBody){
        BackendMonitoring__e logEvent = msUtility.getEvent('Production Mails Batch');
        logEvent.Message__c = messageBody;
        logEvent.IsError__c = true;
        msUtility.publishEvent(logEvent);
    }

    private String buildErrorLogMessageBody() {
        String errorMessageBody = 'List of Meters for which getting the Production Data file failed: \n \n';
        for(String portfolioId : portfolioIdToErrorLogMessage.keySet()){
            errorMessageBody += '--------------------------------------- \n';
            errorMessageBody += '*** '+portfolioId + ' *** \n'+portfolioIdToErrorLogMessage.get(portfolioId)+ ' \n';
        }
        return errorMessageBody;
    }

    private void sendErrorLogEmail(String messageBody) {

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        String errorLogTargetUsers = msUtility.getPortalSettings().Production_Mail_Errorlog_Target_Users__c;
        if (errorLogTargetUsers != null) {
            for (String recipient : errorLogTargetUsers.deleteWhitespace().split(',')) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(recipient);
                mail.setOrgWideEmailAddressId(owaId);
                mail.setSubject('Production Data Email error log');
                mail.setPlainTextBody(messageBody);
                mail.setSaveAsActivity(false);
                messages.add(mail);
            }
            Messaging.sendEmail(messages, false);
        }
    }
}