/**
 * Created by frank on 14.08.2018.
 */
@IsTest
private class msDynamicEmailControllerTest {
    @IsTest
    static void dynamicEmailTest() {
        msTestDataFactory.createTestPortalContext();
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Community_Welcome_Email_Master' LIMIT 1];
        User target = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        User target2 = [SELECT Id FROM User WHERE Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        List<Id> targetIds = new List<Id>{target.Id,target2.Id};

        System.Test.startTest();
        /*  Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          mail.toAddresses = new String[] {'nehler@mindsquare.de'};
          mail.optOutPolicy = 'FILTER';
          mail.setTargetObjectId(target.Id);
          mail.setTemplateId(et.Id);
          mail.saveAsActivity = false;
          Messaging.SingleEmailMessage[] mails = new List<Messaging.SingleEmailMessage>{mail};
          Messaging.SendEmailResult[] results = Messaging.sendEmail(mails); */
        Messaging.SendEmailResult[] mailResults = createMails(targetIds, et.Id);
        System.Test.stopTest();
        for (Messaging.SendEmailResult res : mailResults){
            System.assertEquals(res.success, true, 'The Email was not send');
        }

    }

    static Messaging.SendEmailResult[] createMails(List<Id> targetIds, Id etId) {
        Messaging.SingleEmailMessage[] mails = new List<Messaging.SingleEmailMessage>();
        for (Id targetId : targetIds) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = new String[] {'no-reply-salesforce@statkraft.com'};
            mail.optOutPolicy = 'FILTER';
            mail.setTargetObjectId(targetId);
            mail.setTemplateId(etId);
            mail.saveAsActivity = false;
            mails.add(mail);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
        return results;
    }
}