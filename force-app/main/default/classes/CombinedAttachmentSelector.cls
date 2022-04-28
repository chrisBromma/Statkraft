public class CombinedAttachmentSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType(){
        return CombinedAttachment.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            CombinedAttachment.Id,
            CombinedAttachment.ContentUrl,
            CombinedAttachment.LastModifiedDate,
            CombinedAttachment.CreatedById,
            CombinedAttachment.RecordType
        };
    }
    
}