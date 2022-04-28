/****************************************************************************************************
 * Class FlowActionRenderEmailTest
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2021-11-21
 *   Description	:	---
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------                 
 *   * Christian Gottlieb (mindsquare AG)	                2021-11-21       	Init version.
*****************************************************************************************************/

@IsTest
private class FlowActionRenderEmailTest {

    @IsTest
    static void flowEmailRenderTest() {
        //This is so high to assure the proper function of the Singleton Design
        Integer batch_size = 99;
        List<EmailTemplate> emailTemplatesForTesting = new List<EmailTemplate>();
        emailTemplatesForTesting.add(new EmailTemplate(
                DeveloperName = 'FlowActionRenderEmailTest',
                Name = 'Flow ActionRender Email Test',
                Subject = 'subject',
                Body = 'body',
                HtmlValue = '<div>html body</div>',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'custom'
        ));
        insert emailTemplatesForTesting;

        Test.startTest();

        List<FlowActionRenderEmail.ActionInput> inputs = new List<FlowActionRenderEmail.ActionInput>();
        for (Integer i = 0; i < batch_size; i++) {
            FlowActionRenderEmail.ActionInput input = new FlowActionRenderEmail.ActionInput();
            input.templateName = 'FlowActionRenderEmailTest';
            inputs.add(input);
        }

        List<FlowActionRenderEmail.ActionOutput> outputs = FlowActionRenderEmail.renderEmails(inputs);

        Test.stopTest();

        System.assertEquals(batch_size, outputs.size(), 'Wrong amount of outputs');
        for (FlowActionRenderEmail.ActionOutput output : outputs) {
            System.assertEquals('subject', output.renderedSubject, 'The Subject was not rendered correctly');
            System.assertEquals('body', output.renderedBodyText, 'The Text Body was not rendered correctly');
            System.assertEquals('<div>html body</div>', output.renderedBodyHtml, 'The Html Body was not rendered correctly');
        }
    }

    @IsTest
    static void flowEmailRender_bulkTest() {
        //This is so high to assure the proper function of the Singleton Design
        Integer batch_size = 99;
        List<EmailTemplate> emailTemplatesForTesting = new List<EmailTemplate>();
        emailTemplatesForTesting.add(new EmailTemplate(
                DeveloperName = 'FlowActionRenderEmailTest',
                Name = 'Flow ActionRender Email Test',
                Subject = 'subject',
                Body = 'body',
                HtmlValue = '<div>html body</div>',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'custom'
        ));
        insert emailTemplatesForTesting;

        Test.startTest();

        List<FlowActionRenderEmail.ActionInput> inputs = new List<FlowActionRenderEmail.ActionInput>();
        FlowActionRenderEmail.ActionInput input = new FlowActionRenderEmail.ActionInput();
        input.templateName = 'FlowActionRenderEmailTest';
        inputs.add(input);
        List<List<FlowActionRenderEmail.ActionOutput>> outputsCollection = new List<List<FlowActionRenderEmail.ActionOutput>>();
        for (Integer i = 0; i < batch_size; i++) {
            outputsCollection.add(FlowActionRenderEmail.renderEmails(inputs));
        }

        Test.stopTest();

        System.assertEquals(batch_size, outputsCollection.size(), 'Wrong amount of outputs');
        for (List<FlowActionRenderEmail.ActionOutput> outputs : outputsCollection) {
            System.assertEquals(1, outputs.size(), 'Wrong amount of outputs');
            System.assertEquals('subject', outputs[0].renderedSubject, 'The Subject was not rendered correctly');
            System.assertEquals('body', outputs[0].renderedBodyText, 'The Text Body was not rendered correctly');
            System.assertEquals('<div>html body</div>', outputs[0].renderedBodyHtml, 'The Html Body was not rendered correctly');
        }
    }
}