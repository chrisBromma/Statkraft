@isTest
private class EmailTemplateSelectorTest {
    @testSetup static void setup() {
        insert msGranularTestDataFactory.createTestEmailTemplates(1);
    }
    
    @isTest
    private static void testGetSobjectType() {
        EmailTemplateSelector emailTemplateSelector = (EmailTemplateSelector) Application.Selector.newInstance(EmailTemplate.SObjectType);
        System.assertEquals('EmailTemplate', String.valueOf(emailTemplateSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        EmailTemplateSelector emailTemplateSelector = (EmailTemplateSelector) Application.Selector.newInstance(EmailTemplate.SObjectType);
        System.assertEquals(5, emailTemplateSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testWithHtmlBody() {
        EmailTemplateSelector emailTemplateSelector = (EmailTemplateSelector) Application.Selector.newInstance(EmailTemplate.SObjectType);
        emailTemplateSelector.withHtmlBody();
        System.assertEquals(6, emailTemplateSelector.getSObjectFieldList().size());
    }

    @isTest
    private static void testSelectByDeveloperName() {
        EmailTemplateSelector emailTemplateSelector = (EmailTemplateSelector) Application.Selector.newInstance(EmailTemplate.SObjectType);
        System.assertEquals('test0', emailTemplateSelector.selectByDeveloperName('testdev0').Name);
    }
}