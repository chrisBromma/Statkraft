/****************************************************************************************************
* Class DocumentViewerController
*
*   Create By	:   Jörn Gerdes (Statkraft GmbH)
*   Create Date	:
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Jörn Gerdes (Statkraft GmbH)                                	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      08.07.2019              Bugfix
*   * Christian Gottlieb (mindsquare GmbH)      12.09.2019              Restriction to AttachmentTypes Custom Setting
*****************************************************************************************************/
public class DocumentViewerController {
// ApexPages.StandardSetController must be instantiated
// for standard list controllers


    public Id RecordId { get; set; }

    public List<ContentVersion> FileList { get; set; }

    public String atttype { get; set; }
    public Boolean OnlyActive { get; set; }
    public Boolean OnlyFS { get; set; }
    public Boolean OnlyComercial { get; set; }
    public Boolean OnlyTechnical { get; set; }
    public String sizeString { get; set; }
    public Integer maxSize = 20;
    public String delConnectToId { get; set; }
    public Set<String> validAttachmentTypes { get; set; }

    public DocumentViewerController() {
        RecordId = ApexPages.currentPage().getParameters().get('id');
        atttype = '%';
        OnlyActive = false;
        OnlyFS = false;
        OnlyComercial = false;
        OnlyTechnical = false;
        validAttachmentTypes = new Set<String>();
        loadValidAttachmentTypes();
        getContentVersions();

    }
    // Initialize setCon and return a list of records
    public void getContentVersions() {
        if (RecordId == null) {
            FileList = new List<ContentVersion>();
        } else {
            List<Id> LinkedDocumentIDs = new List<Id>();
            for (ContentDocumentLink cdl : [SELECT ContentDocumentId    FROM ContentDocumentLink
                                                                        WHERE LinkedEntityId = :RecordId]) {
                LinkedDocumentIDs.add(cdl.ContentDocumentId);
            }
            String query;
            String LinkedDocumentsString = '';
            // Define query filters
            List<String> commercialDoc = new List<String>();
            for (Attachmenttypes__c typeItem : Attachmenttypes__c.getAll().values()) {
                if (typeItem.msIsSendNotifications__c == false && typeItem.msIsShowInPortal__c == false && typeItem.Comercial_Document__c == true ) {
                    commercialDoc.add(typeItem.msPicklist_Value_API_Name__c);
                }
            }
            if (LinkedDocumentIDs.size() > 0) {
                for (String str : LinkedDocumentIDs) {
                    LinkedDocumentsString += '\'' + str + '\',';
                }
                LinkedDocumentsString = LinkedDocumentsString.substring(0, LinkedDocumentsString.length() - 1);
                // Set query for documents
                query = 'SELECT Validity_start_date__c, ' +
                        'Validity_end_date__c, ' +
                        'Status_Document__c, ' +
                        'Title, ' +
                        'Id, ' +
                        'Attachement_Type__c, ' +
                        'CreatedDate, ' +
                        'ContentDocumentId ' +
                        'FROM ContentVersion WHERE ContentDocumentId IN (' + LinkedDocumentsString + ')' +
                        'AND IsLatest = TRUE';
                // Query on filters
                // Attachment Type filter
                if(atttype == '%') {
                    query += ' AND Attachement_Type__c IN :validAttachmentTypes';
                }
                if (atttype <> '%') {
                    query += ' AND Attachement_Type__c LIKE \'' + atttype + '\'';
                }
                // Only Commercial filter = true
                if (OnlyFS == false && OnlyComercial == true && OnlyTechnical == false) {
                    query += ' AND Attachement_Type__c IN :commercialDoc ';
                }
                if (OnlyActive == true) {
                    query += ' AND Status_Document__c = TRUE';
                }
                query += ' ORDER BY Attachement_Type__c ASC, CreatedDate DESC ';
                FileList = Database.query(query);

            }
        }
    }
    // Define function for deleting files from object
    public void deleteRecord() {
        ContentDocumentLink delObj = [SELECT Id FROM ContentDocumentLink    WHERE ContentDocumentId = :delConnectToId
                                                                            AND LinkedEntityId = :RecordId];
        delete delObj;
        getContentVersions();
    }
    public List<SelectOption> getAttachmentTypes() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = ContentVersion.Attachement_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Map<String,String> valueToLabelMap = new Map<String, String>();
        for (Schema.PicklistEntry entryItem: ple) {
            valueToLabelMap.put(entryItem.getValue(), entryItem.getLabel());
        }

        options.add(new SelectOption('%', 'All'));
        for (String typeItem : validAttachmentTypes) {
            //avoid null by wrong setup
            if(valueToLabelMap.containsKey(typeItem)) {
                options.add(new SelectOption(valueToLabelMap.get(typeItem), typeItem));
            }
        }
        return options;
    }
    private void loadValidAttachmentTypes() {
        String prefix = ((String) RecordId).left(3);
        String objectType = '';
        String country = '';
        //if Account
        if(prefix == '001') {
            country = [SELECT BillingCountry FROM Account WHERE Id = :RecordId LIMIT 1].BillingCountry;
            objectType = 'Account';

            //else if Contract__c
        } else if(prefix == 'a0K') {
            country = [SELECT Country__c FROM Contract__c WHERE Id = :RecordId LIMIT 1].Country__c;
            objectType = 'Contract__c';

        } else {
            //else not supported Object
            return;
        }
        if(country != 'France') {
            country = 'Germany';
        }
        String queryString = 'SELECT Name,' +
                'msPicklist_Value_API_Name__c ' +
                'FROM Attachmenttypes__c ' +
                'WHERE Related_Object__c = \'' + objectType + '\' ' +
                'AND ' + country + '__c = TRUE ' +
                'AND msIsSendNotifications__c = FALSE ' +
                'AND msIsShowInPortal__c = FALSE ORDER BY Name ASC';
        List<Attachmenttypes__c> attachmentTypes = Database.query(queryString);
        for (Attachmenttypes__c typeItem : attachmentTypes) {
            validAttachmentTypes.add(typeItem.msPicklist_Value_API_Name__c);
        }
    }
}