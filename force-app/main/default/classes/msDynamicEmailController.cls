/**
 * Created by frank on 13.08.2018.
 */
public class msDynamicEmailController {

    public msDynamicEmailController() {
    }

    public String emailRecipientId { get; set; }
    public String communityUrlTemplate { get; set; }
    public String communityNameTemplate { get; set; }
    public Boolean isHtml { get; set; }
    public String emailTemplateName { get; set; }

    public Messaging.SingleEmailMessage renderedEmail {
        get {
            if (renderedEmail == null) {
                User recipient = [SELECT Id, ContactId, LanguageLocaleKey FROM User WHERE ContactId = :emailRecipientId OR Id = :emailRecipientId];
                String templateName = emailTemplateName + recipient.LanguageLocaleKey.substring(0, 2);

                List<EmailTemplate> temp = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName];
                if (temp.size() < 1) {
                    templateName = emailTemplateName + 'en';
                    temp = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];
                }
                renderedEmail = Messaging.renderStoredEmailTemplate(temp[0].Id, recipient.Id, recipient.ContactId);
            }
            return renderedEmail;

        }
        set;
    }

    public String getMergedEmailHtmlBody() {
        String body = renderedEmail.getHtmlBody();
        body = body.replace('{Community_Name}', communityNameTemplate);
        return body.replace('{Community_Url}', communityUrlTemplate);
    }

    public String getMergedEmailPlainTextBody() {
        String body = renderedEmail.getPlainTextBody();
        body = body.replace('{Community_Name}', communityNameTemplate);
        return body.replace('{Community_Url}', communityUrlTemplate);

    }

    public String getMergedEmailSubject() {
        return renderedEmail.getSubject();
    }
}