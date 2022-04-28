global without sharing class msKAMScreenController {
    @InvocableMethod(Label='Change Document Owners')
    public static void changeDocumentOwners(List<KAM> proposedKAM) {
        Map<Id, Id> contentDocumentLinkIdtoContentDocumentIdMap = new Map<Id, Id>();
        for (ContentDocumentLink cdLink : [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :proposedKAM[0].accountId AND LinkedEntity.Type='Account']) {
                contentDocumentLinkIdtoContentDocumentIdMap.put(cdlink.Id, cdlink.ContentDocumentId);
        }

        List<ContentVersion> contentVersionsToUpdate = new List<ContentVersion>();
        for (ContentVersion cv : [
            SELECT OwnerId, ContentDocumentId, IsLatest 
            FROM ContentVersion 
            WHERE IsLatest = true AND ContentDocumentId IN :contentDocumentLinkIdtoContentDocumentIdMap.values()]) {
                cv.ownerId = proposedKAM[0].ownerId;
                contentVersionsToUpdate.add(cv);
        }
        update contentVersionsToUpdate;
    }
    public class KAM{
        @InvocableVariable(label='Account Id' required=true)
        public Id accountId;
        @InvocableVariable(label='Owner Id' required=true)
        public Id ownerId;
    }
}