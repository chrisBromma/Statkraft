public  class ContentDocumentSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return ContentDocument.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            ContentDocument.Id,
            ContentDocument.LatestPublishedVersionId
        };
    }
    
}