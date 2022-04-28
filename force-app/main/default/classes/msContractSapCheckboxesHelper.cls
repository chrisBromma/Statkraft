public without sharing class msContractSapCheckboxesHelper {

    private Set<Id> accountIds = new Set<Id>();
    private Set<Id> contractIds = new Set<Id>();
    private Map<Id, Account> accountsByIds = new Map<Id, Account>();
    private Map<Id, Contract__c> contractsByIds = new Map<Id, Contract__c>();
    private Map<Id, Set<Id>> linkedEntityIdsByDocumentIds = new Map<Id, Set<Id>>();
    public Map<String, Attachmenttypes__c> attachmentTypes = new Map<String, Attachmenttypes__c>();
    public Set<SObjectField> accountSapCheckboxes = new Set<SObjectField>{
            Account.Tax_or_VAT__c,
            Account.Company_Registration__c
    };
    public Set<SObjectField> contractSapCheckboxes = new Set<SObjectField>{
            Contract__c.Double_Signed_Contract__c,
            Contract__c.Single_Signed_Contract__c
    };

    public msContractSapCheckboxesHelper() {
        prepareAttachmentTypes();
    }

    public msContractSapCheckboxesHelper(Set<Id> accountIds, Set<Id> contractIds) {
        this();
        this.accountIds = accountIds;
        this.contractIds = contractIds;
    }

    public void execute() {
        prepareMaps();
        calculateRecords(getLinkedEntityIds());
    }

    private void prepareAttachmentTypes() {
        Map<String, Schema.SObjectField> fieldMap = Attachmenttypes__c.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNamesAttachmentTypes = new List<String>(fieldMap.keySet());

        List<Attachmenttypes__c> allAttachmenttypes = Database.query('SELECT ' + String.join(fieldNamesAttachmentTypes, ',') + ' FROM Attachmenttypes__c');
        for(Attachmenttypes__c attachmentType : allAttachmenttypes) {
            attachmentTypes.put(attachmentType.msPicklist_Value_API_Name__c, attachmentType);
        }
    }

    private void prepareMaps() {
        this.accountsByIds = new Map<Id, Account>([
                SELECT Id, Tax_or_VAT__c, Company_Registration__c
                FROM Account
                WHERE Id IN :this.accountIds
        ]);
        this.contractsByIds = new Map<Id, Contract__c>([
                SELECT Id, Double_Signed_Contract__c, Single_Signed_Contract__c
                FROM Contract__c
                WHERE Id IN :this.contractIds
        ]);
    }

    private Set<Id> getLinkedEntityIds() {
        Set<Id> entityIds = new Set<Id>();
        entityIds.addAll(this.contractIds);
        entityIds.addAll(this.accountIds);
        return entityIds;
    }

    private Set<Id> getDocumentIdsByLinkedEntityIds(Set<Id> linkedEntityIds) {
        Set<Id> contentDocumentIds = new Set<Id>();
        for(ContentDocumentLink cdl : [
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :linkedEntityIds
        ]) {
            if(!linkedEntityIdsByDocumentIds.containsKey(cdl.LinkedEntityId)) {
                linkedEntityIdsByDocumentIds.put(cdl.LinkedEntityId, new Set<Id>());
            }
            linkedEntityIdsByDocumentIds.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
        return contentDocumentIds;
    }

    public Map<Id, Attachmenttypes__c> getAttachmentTypesByDocumentIds(Set<Id> contentDocumentIds) {
        Map<Id, Attachmenttypes__c> attachmentTypesByContentDocumentIds = new Map<Id, Attachmenttypes__c>();
        for(ContentVersion conVersion : [
                SELECT Id, Attachement_Type__c, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
                AND IsLatest = TRUE
        ]) {
            attachmentTypesByContentDocumentIds.put(conVersion.ContentDocumentId, attachmentTypes.get(conVersion.Attachement_Type__c));
        }
        return attachmentTypesByContentDocumentIds;
    }

    private Map<Id, Attachmenttypes__c> calculateCheckboxesForEntities(Set<Id> linkedEntityIds) {
        Set<Id> contentDocumentIds = getDocumentIdsByLinkedEntityIds(linkedEntityIds);
        Map<Id, Attachmenttypes__c> attachmentTypesByDocumentIds = getAttachmentTypesByDocumentIds(contentDocumentIds);
        for(Id entityId : linkedEntityIdsByDocumentIds.keySet()) {
            Attachmenttypes__c tempAttachmentType = createTempAttachmentType();
            for(Id contentDocumentId : linkedEntityIdsByDocumentIds.get(entityId)) {
                tempAttachmentType = calculateCheckboxes(attachmentTypesByDocumentIds, tempAttachmentType, contentDocumentId);
            }
            attachmentTypesByDocumentIds.put(entityId, tempAttachmentType);
        }
        return attachmentTypesByDocumentIds;
    }

    private Attachmenttypes__c calculateCheckboxesForEntity(Map<Id, Attachmenttypes__c> attachmentTypesByEntityIds, Attachmenttypes__c tempAttachmentType, Id entityId) {
        if(attachmentTypesByEntityIds.containsKey(entityId)) {
            return calculateCheckboxes(attachmentTypesByEntityIds, tempAttachmentType, entityId);
        }
        return tempAttachmentType;
    }

    private Attachmenttypes__c calculateCheckboxes(Map<Id, Attachmenttypes__c> attachmentTypesByRecordIds, Attachmenttypes__c tempAttachmentType, Id recordId) {
        Attachmenttypes__c currentAttachmentType = attachmentTypesByRecordIds.get(recordId);
        if(currentAttachmentType != null) {
            for(SObjectField sObjField : accountSapCheckboxes) {
                if((Boolean) currentAttachmentType.get(sObjField.getDescribe().getName())) {
                    tempAttachmentType.put(sObjField.getDescribe().getName(), true);
                }
            }
            for(SObjectField sObjField : contractSapCheckboxes) {
                if((Boolean) currentAttachmentType.get(sObjField.getDescribe().getName())) {
                    tempAttachmentType.put(sObjField.getDescribe().getName(), true);
                }
            }
        }
        return tempAttachmentType;
    }

    private void calculateRecords(Set<Id> linkedEntityIds) {
        Map<Id, Attachmenttypes__c> attachmentTypesByEntityIds = calculateCheckboxesForEntities(linkedEntityIds);
        calculateRecordsToUpdate(attachmentTypesByEntityIds, accountIds, accountsByIds, accountSapCheckboxes);
        calculateRecordsToUpdate(attachmentTypesByEntityIds, contractIds, contractsByIds, contractSapCheckboxes);
    }

    private void calculateRecordsToUpdate(Map<Id, Attachmenttypes__c> attachmentTypesByEntityIds, Set<Id> recordIds, Map<Id, SObject> recordMap, Set<SObjectField> relevantFields) {
        List<SObject> sObjectsToUpdate = new List<SObject>();
        Map<Id,Boolean> recordIsLockedMap = Approval.isLocked(new List<Id>(recordIds));
        List<Id> lockedIds = new List<Id>();
        for(Id recordId : recordIsLockedMap.keySet()) {
            if(recordIsLockedMap.get(recordId)) {
                lockedIds.add(recordId);
            }
        }
        Approval.unlock(lockedIds);
        for(Id recordId : recordIds) {
            Boolean recordToUpdate = false;
            Attachmenttypes__c tempAttachmentType = createTempAttachmentType();
            tempAttachmentType = calculateCheckboxesForEntity(attachmentTypesByEntityIds, tempAttachmentType, recordId);
            for(SObjectField sObjField : relevantFields) {
                if((Boolean) tempAttachmentType.get(sObjField.getDescribe().getName()) != (Boolean) recordMap.get(recordId).get(sObjField)) {
                    recordMap.get(recordId).put(sObjField, (Boolean) tempAttachmentType.get(sObjField.getDescribe().getName()));
                    recordToUpdate = true;
                }
            }
            if(recordToUpdate) {
                sObjectsToUpdate.add(recordMap.get(recordId));
            }
        }
        if(!sObjectsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(sObjectsToUpdate,false);
            for(Database.SaveResult result : results) {
                if(!result.isSuccess()) {
                    System.debug(result.getErrors());
                }
            }
        }
        Approval.lock(lockedIds);
    }

    private Attachmenttypes__c createTempAttachmentType() {
        Attachmenttypes__c attachmentType = new Attachmenttypes__c();
        for(SObjectField objectField : accountSapCheckboxes) {
            attachmentType.put(objectField.getDescribe().getName(), false);
        }
        for(SObjectField objectField : contractSapCheckboxes) {
            attachmentType.put(objectField.getDescribe().getName(), false);
        }
        return attachmentType;
    }
}