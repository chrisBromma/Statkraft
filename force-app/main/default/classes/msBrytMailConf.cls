/****************************************************************************************************
 * Class msBrytMailConf
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 21.01.2019
 *   Description :  This class carries all explicit mail sending processes for notifications of the Bryt Customer
 *                  Portal.
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	21.01.2019	Init version.
 *****************************************************************************************************/

public with sharing class msBrytMailConf {
    public static void msSendConfirmationMails(List<msBrytNotificationLogic.notificationWrapper> contractNotifications) {

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        EmailTemplate personalizedTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :'Bryt_Trade_Confirmation' LIMIT 1];
        EmailTemplate systemTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :'Bryt_Trade_System_Confirmation' LIMIT 1];
        OrgWideEmailAddress owa = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply-salesforce@statkraft.com'];
        Messaging.SingleEmailMessage systemEmailTemplateMaster = Messaging.renderStoredEmailTemplate(systemTemplate.Id, null, null);
        for (msBrytNotificationLogic.notificationWrapper contractNotification : contractNotifications) {

            PageReference pdf = Page.msBrytSendConf;
            String listOfIdsByConcatenation = '';
            for (Id pcItem : contractNotification.pcIds) {
                listOfIdsByConcatenation = listOfIdsByConcatenation + pcItem + '.';
            }
            pdf.getParameters().put('listOfIdsByConcatenation', listOfIdsByConcatenation);
            Blob b;
            if (Test.isRunningTest()) {
                b = Blob.valueOf('Unit_Test_Is_Running');
            } else {
                b = pdf.getContent();
            }
            if (contractNotification.targetUserIds != null) {
                for (Id userTargetId : contractNotification.targetUserIds) {

                    message = emailSetup(owa.Id, contractNotification.contract.Name, b);
                    message.setTemplateId(personalizedTemplate.Id);

                    if (contractNotification.isDebug) {
                        if (contractNotification.debugTarget != null) {
                            message.setTargetObjectId(contractNotification.debugTarget);
                            messages.add(message);
                        }
                    } else {
                        message.setTargetObjectId(userTargetId);
                        messages.add(message);
                    }
                }
            }
            if (contractNotification.targetEmailsList != null) {
                for (String systemEmailAddress : contractNotification.targetEmailsList) {
                    message = emailSetup(owa.Id, contractNotification.contract.Name, b);
                    message.setHtmlBody(systemEmailTemplateMaster.getHtmlBody());
                    message.setSubject(systemEmailTemplateMaster.getSubject());
                    message.setPlainTextBody(systemEmailTemplateMaster.getPlainTextBody());

                    if (contractNotification.isDebug) {
                        if (contractNotification.debugTarget != null) {
                            message.setTargetObjectId(contractNotification.debugTarget);
                            messages.add(message);
                        }
                    } else {
                        message.setToAddresses(new List<String>{
                                systemEmailAddress
                        });
                        messages.add(message);
                    }
                }
            }
            if (contractNotification.contract.BrytNotificationEmails__c != null) {
                message = emailSetup(owa.Id, contractNotification.contract.Name, b);
                message.setHtmlBody(systemEmailTemplateMaster.getHtmlBody());
                message.setSubject(systemEmailTemplateMaster.getSubject());
                message.setPlainTextBody(systemEmailTemplateMaster.getPlainTextBody());

                if (contractNotification.isDebug) {
                    if (contractNotification.debugTarget != null) {
                        message.setTargetObjectId(contractNotification.debugTarget);
                        messages.add(message);
                    }
                } else {
                    List<String> separatedEmailsList = contractNotification.contract.BrytNotificationEmails__c.split(';');
                    Set<String> separatedCheckedEmails = new Set<String>();
                    for (String separatedEmail : separatedEmailsList) {
                        if (msBrytNotificationLogic.checkEmailPattern(separatedEmail)) {
                            separatedCheckedEmails.add(separatedEmail);
                        } else {
                            System.debug('BrytNotificationEmail has failed on Contract: ' + contractNotification.contract.Id + ' for mailing address: ' + separatedEmail);
                        }
                    }
                    message.setToAddresses(new List<String>(
                        separatedCheckedEmails
                    ));
                    messages.add(message);
                }
            }
        }
        Messaging.sendEmail(messages);
    }

    private static Messaging.SingleEmailMessage emailSetup(Id owaId, String contractName, Blob b) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        message.setUseSignature(false);
        message.setBccSender(false);

        message.setSaveAsActivity(false);
        message.optOutPolicy = 'FILTER';
        message.setOrgWideEmailAddressId(owaId);

        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        String exportTime = Datetime.now().format();
        String docTitle = 'Trade_Confirmation:_' + contractName + '---' + exportTime + '.pdf';
        efa.setFileName(docTitle);
        efa.setBody(b);
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{
                efa
        });
        return message;
    }

    @Future
    public static void msSendDeactNotif(Id pcId) {
        Pricing_Component__c pc = [
                SELECT Id, Name, Contract__r.BrytNotificationEmails__c,
                        Contract__r.Name, Contract__r.Contract_Holder__r.Name, Contract__c
                FROM Pricing_Component__c
                WHERE Id = :pcId
                LIMIT 1
        ];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSenderDisplayName('mindsquare Testing deactivation');
        message.setUseSignature(false);
        message.setBccSender(false);
        message.setPlainTextBody('Trigger works for deactivation');
        List<String> separatedEmailsList = pc.Contract__r.BrytNotificationEmails__c.split(';');
        Set<String> separatedCheckedEmails = new Set<String>();
        for (String separatedEmail : separatedEmailsList) {
            if (msBrytNotificationLogic.checkEmailPattern(separatedEmail)) {
                separatedCheckedEmails.add(separatedEmail);
            } else {
                System.debug('BrytNotificationEmail has failed on Contract: ' + pc.Contract__c + ' For mailing address: ' + separatedEmail);
            }
        }
        message.toAddresses = new List<String>(separatedCheckedEmails);
        message.optOutPolicy = 'FILTER';
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        messages.add(message);
        Messaging.sendEmail(messages);
    }
}