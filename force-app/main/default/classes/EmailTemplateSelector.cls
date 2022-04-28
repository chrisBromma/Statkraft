public class EmailTemplateSelector extends fflib_SObjectSelector{
    
    Boolean withHtmlBody = false;

    public SObjectType getSObjectType(){
        return EmailTemplate.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        
        List<SObjectField> fields = new List<SObjectField>{
            EmailTemplate.Id,
            EmailTemplate.Name,
            EmailTemplate.DeveloperName,
            EmailTemplate.Body,
            EmailTemplate.Subject
        };

        if(withHtmlBody){
            fields.add(EmailTemplate.HtmlValue);
        }

        return fields;
    }

    public EmailTemplateSelector withHtmlBody(){
        this.withHtmlBody = true;
        return this;
    }

    public EmailTemplate selectByDeveloperName(String devName){
        return Database.query(newQueryFactory().setCondition('DeveloperName = :devName').setLimit(1).toSOQL());
    }
}