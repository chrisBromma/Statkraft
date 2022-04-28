public class ContentVersionSelector extends fflib_SObjectSelector{

    Boolean includeVersionData = false;

    public ContentVersionSelector withVersionData(){
        includeVersionData = true;
        return  this;
    }

    public SObjectType getSObjectType(){
        return ContentVersion.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        List<SObjectField> fields = new List<SObjectField>{
            ContentVersion.Id,
            ContentVersion.ContentDocumentId,
            ContentVersion.Validity_end_date__c,
            ContentVersion.Status_Document__c,
            ContentVersion.Attachement_Type__c,
            ContentVersion.OwnerId,
            ContentVersion.Title
        };
        
        //Because we don't always need the binary data in our queries. It would bloat everything out of proportion.
        if(this.includeVersionData){
            fields.add(ContentVersion.VersionData);
        }

        return fields;
    }
}