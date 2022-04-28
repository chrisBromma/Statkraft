public class ContentDocumentLinkSelector extends fflib_SObjectSelector{
    
    public SObjectType getSObjectType(){
        return ContentDocumentLink.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            ContentDocumentLink.Id,
            ContentDocumentLink.ContentDocumentId,
            ContentDocumentLink.LinkedEntityId,
            ContentDocumentLink.Visibility
        };
    }
}