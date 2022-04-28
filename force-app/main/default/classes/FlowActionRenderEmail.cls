/****************************************************************************************************
 * Class FlowActionRenderEmail
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

public without sharing class FlowActionRenderEmail {

    //Singleton to avoid unnecessary SOQLs to identify Template Ids
    private static Map<String, Id> TEMPLATE_NAME_TO_ID_MAP = new Map<String, Id>();

    public class ActionInput {
        @InvocableVariable(
                Label = 'Template Developer Name'
                Description = 'The API Name of the Classic Template to be rendered'
                Required = true)
        public String templateName;
        @InvocableVariable(
                Label = 'What Id'
                Description = 'The Salesforce Id of the referred SObject, needed for all '
                Required = false)
        public Id whatId;
        @InvocableVariable(
                Label = 'Who Id'
                Description = 'The Salesforce Id of the referred SObject'
                Required = false)
        public Id whoId;
    }

    public class ActionOutput {
        @InvocableVariable(
                Label = 'Subject'
                Description = 'The Subject of the rendered Email'
                Required = false)
        public String renderedSubject;
        @InvocableVariable(
                Label = 'Body Text'
                Description = 'The Body Plain Text of the rendered Email'
                Required = false)
        public String renderedBodyText;
        @InvocableVariable(
                Label = 'Body Html'
                Description = 'The Body in HTML of the rendered Email'
                Required = false)
        public String renderedBodyHtml;
    }

    @InvocableMethod(
            Label = 'Render Classic Template'
            Description = 'Every execution consumes one SOQL, do not execute in loop operations. Instead use a non personalized template, render the email once and personalize afterwards manually')

    public static List<ActionOutput> renderEmails(List<ActionInput> requests) {
        List<ActionOutput> outputs = new List<ActionOutput>();
        Set<String> templateNamesToLoad = new Set<String>();
        for (ActionInput request : requests) {
            if (!TEMPLATE_NAME_TO_ID_MAP.containsKey(request.templateName)) {
                templateNamesToLoad.add(request.templateName);
            }
        }

        if (!templateNamesToLoad.isEmpty()) {
            for(EmailTemplate loadedTemplate : [
                    SELECT Id, DeveloperName
                    FROM EmailTemplate
                    WHERE DeveloperName IN :templateNamesToLoad
            ]) {
                TEMPLATE_NAME_TO_ID_MAP.put(loadedTemplate.DeveloperName, loadedTemplate.Id);
            }
        }

        for (ActionInput request : requests) {
            Id templateId = TEMPLATE_NAME_TO_ID_MAP.get(request.templateName);
            Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(templateId, request.whoId, request.whatId);
            ActionOutput output = new ActionOutput();
            output.renderedSubject = renderedEmail.getSubject();
            output.renderedBodyText = renderedEmail.getPlainTextBody();
            output.renderedBodyHtml = renderedEmail.getHtmlBody();
            outputs.add(output);
        }

        return outputs;
    }
}