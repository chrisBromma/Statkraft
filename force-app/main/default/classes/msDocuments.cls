public with sharing class msDocuments {

    static final String FULL_DATE_PATTERN = '[0-9]{4}([0]{1}[1-9]{1}|[1]{1}[0-2]{1})([0-2]{1}[0-9]{1}|[3]{1}[0-1]{1})';
    static final String MONTH_DATE_PATTERN = '[0-9]{4}([0]{1}[1-9]{1}|[1]{1}[0-2]{1})';
    static final String YEAR_ONLY_PATTERN = '[0-9]{4}([0]{1}[0]{1}|[1]{1}[0]{1})'; //For example: 202100

    @AuraEnabled
    public static List<DocumentWrapper> fetchDocuments() {
        List<DocumentWrapper> result = new List<DocumentWrapper>();
        DocumentWrapper docInfo = new DocumentWrapper();
        msUtility.UserDetails userDetails = msUtility.getUserDetails();
        Set<Id> contractIds = new Set<Id>();
        Map<Id, String> contractIdToMeterNameMap = new Map<Id, String>();
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        List<Id> contDocPdfId = new List<Id>();
        Map<Id, Id> contenIdToContractId = new Map<Id, Id>(); //find LinkedMeterId between Item and ContentVersion

        for (Contract__c tempContract : userDetails.contracts) {
            contractIds.add(tempContract.Id);
        }

        if (contractIds.size() > 0) {
            List<MeterRegistration__c> meterRegistrations = [
                    SELECT Contract__r.Name,Contract__r.Alternative_Contract_Name__c, Contract__c,Meter__r.Name
                    FROM MeterRegistration__c
                    WHERE (Meter__c IN :userDetails.plants
                    AND Valid_from__c <= :Date.today()
                    AND (Valid_to__c >= :Date.today()
                    OR Valid_to__c = NULL))
                    OR Contract__c IN :contractIds
            ];
            List<Contract__c> contracts = [
                    SELECT Id, Name,ESales_ID__c, Alternative_Contract_Name__c
                    FROM Contract__c
                    WHERE Id IN :contractIds
            ];

            for (MeterRegistration__c regItem : meterRegistrations) {
                contractIdToMeterNameMap.put(regItem.Contract__c, regItem.Meter__r.Name);
            }

            contractsMap.putAll(contracts);

            List<ContentDocumentLink> links = [
                    SELECT Id, LinkedEntityId, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :contractIds
            ];
            for (ContentDocumentLink link : links) {
                if (link.ContentDocumentId != null) {
                    contDocPdfId.add(link.ContentDocumentId);
                    contenIdToContractId.put(link.ContentDocumentId, link.LinkedEntityId);
                }
            }
            Set<String> contractAttachmentValues = new Set<String>();
            for (Attachmenttypes__c attTypeItem : [
                    SELECT msPicklist_Value_API_Name__c, Related_Object__c
                    FROM Attachmenttypes__c
                    WHERE msIsSendNotifications__c = TRUE
                    AND msIsShowInPortal__c = TRUE
                    AND Related_Object__c = 'Contract__c'
            ]) {
                contractAttachmentValues.add(attTypeItem.msPicklist_Value_API_Name__c);
            }
            //Select correct ContentVersion for Attachment
            List<ContentVersion> cvListPdf = new List<ContentVersion>([
                    SELECT Id, Title, ContentDocumentId, CreatedDate, toLabel(Attachement_Type__c), FileType
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contDocPdfId
                    AND IsLatest = TRUE
                    // Only show documents which were uploaded through
                    AND (Community_available__c = TRUE OR Attachement_Type__c IN :contractAttachmentValues)
            ]);
            //System.debug('Found pdfs: ' + cvListPdf.size());
            Datetime dT;
            if (cvListPdf.size() > 0) {
                for (ContentVersion conVer : cvListPdf) {
                    Contract__c contract = contractsMap.get(contenIdToContractId.get(conVer.ContentDocumentId));
                    String meterName = contractIdToMeterNameMap.get(contenIdToContractId.get(conVer.ContentDocumentId));

                    docInfo = new DocumentWrapper();
                    docInfo.title = conVer.Title;
                    docInfo.url = '../sfc/servlet.shepherd/document/download/' + conVer.ContentDocumentId;
                    docInfo.doc_type = conVer.Attachement_Type__c == null ? ' ' : conVer.Attachement_Type__c;
                    docInfo.file_type = conVer.FileType;
                    docInfo.meterName = String.isEmpty(contract.Alternative_Contract_Name__c) ? meterName : contract.Alternative_Contract_Name__c;
                    docInfo.eSaleId = contract != null ? contract.Name: '';
                    docInfo.doc_id = conVer.Id;
                    docInfo.contract = contract != null ? contract.Name: '';
                    dT = conVer.CreatedDate;
                    docInfo.doc_date = Date.newInstance(dT.year(), dT.month(), dT.day());
                    if (conVer.Title.contains('CREATION_')) {
                        String dateInTitle = conVer.Title.substring(conVer.Title.indexOf('CREATION_') + 9, conVer.Title.indexOf('CREATION_') + 17);
                        Pattern MyPattern = Pattern.compile(FULL_DATE_PATTERN);
                        Matcher MyMatcher = MyPattern.matcher(dateInTitle);
                        if (MyMatcher.matches()) {
                            docInfo.doc_date = Date.newInstance(Integer.valueOf(dateInTitle.left(4)),
                                    Integer.valueOf(dateInTitle.substring(4, 6)),
                                    Integer.valueOf(dateInTitle.right(2)));
                        }
                    } else if (conVer.Title.contains('CREATION')) {
                        String dateInTitle = conVer.Title.substring(conVer.Title.indexOf('CREATION') + 8, conVer.Title.indexOf('CREATION') + 16);
                        Pattern MyPattern = Pattern.compile(FULL_DATE_PATTERN);
                        Matcher MyMatcher = MyPattern.matcher(dateInTitle);
                        if (MyMatcher.matches()) {
                            docInfo.doc_date = Date.newInstance(Integer.valueOf(dateInTitle.left(4)),
                                    Integer.valueOf(dateInTitle.substring(4, 6)),
                                    Integer.valueOf(dateInTitle.right(2)));
                        }
                    }
                    if (conVer.Title.contains('DATE')) {
                        String monthDateInTitle = conVer.Title.substring(conVer.Title.indexOf('DATE') + 4, conVer.Title.indexOf('DATE') + 10);
                        Pattern MyPattern = Pattern.compile(MONTH_DATE_PATTERN);
                        Matcher MyMatcher = MyPattern.matcher(monthDateInTitle);
                        if (MyMatcher.matches()) {
                            docInfo.deliveryPeriod = Date.newInstance(Integer.valueOf(monthDateInTitle.left(4)),
                                    Integer.valueOf(monthDateInTitle.right(2)), 1);
                        }
                        else{
                            Matcher matcher = Pattern.compile(YEAR_ONLY_PATTERN).matcher(monthDateInTitle);
                            if(matcher.matches()){
                                docInfo.deliveryPeriodYear = Integer.valueOf(monthDateInTitle.left(4));
                            }
                        }
                    }
                    if (conVer.Title.contains('_CN')) {
                        try {
                            Matcher pm = Pattern.compile('(?<=_CN)(.*\\n?)(?=_)').matcher(conVer.Title);
                            if (pm.find()) {
                                docInfo.internal_doc_id = pm.group(1);
                            }
                        } catch (Exception e) {
                        }
                    }
                    result.add((DocumentWrapper) System.JSON.deserializeStrict(JSON.serialize(docInfo), DocumentWrapper.class));
                }
            }

            List<External_Mapping__c> eMapping = [SELECT Id,Name,Contract__c, Contract__r.Name, External_DB_Name__c FROM External_Mapping__c WHERE Contract__c IN :contracts];

            for (Integer j = 0; j < result.size(); j++) {
                for (Integer i = 0; i < eMapping.size(); i++) {
                    if (eMapping[i].Contract__r.Name == result[j].contract) {
                        result[j].eSaleId = eMapping[i].External_DB_Name__c;
                    } else {
                        result[j].eSaleId = msUtility.getLeftPartOfStringRelativeToLastDivider(result[j].eSaleId, '/');
                    }
                }
            }
        }
        return result;
    }

    @AuraEnabled
    public static List<StaticDocumentWrapper> getStaticDocuments() {
        List<StaticDocumentWrapper> returnList = new List<StaticDocumentWrapper>();
        List<Id> meterIds = new List<Id>();
        Map<Id, Id> documentsMap = new Map<Id, Id>(); //maps meter ids with contentDocument itds
        String userLanguage = UserInfo.getLanguage();

        // get possible languages
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Portal_Files__c.Language__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValuesList.add(pickListVal.getValue());
        }
        if (!pickListValuesList.contains(userLanguage)) {
            userLanguage = 'en_US';
        }

        List<Portal_Files__c> portalFiles = new List<Portal_Files__c> ([SELECT Name, Subtitle__c, Id FROM Portal_Files__c WHERE Language__c = :userLanguage ORDER BY Position__c]);

        for (Portal_Files__c file : portalFiles) {
            meterIds.add(file.Id);
        }
        if (meterIds.size() < 1) {
            return null;
        }
        List<ContentDocumentLink> documentsList = new List<ContentDocumentLink> ([SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :meterIds]);

        for (ContentDocumentLink contentDoc : documentsList) {
            documentsMap.put(contentDoc.LinkedEntityId, contentDoc.ContentDocumentId);
        }

        for (Portal_Files__c file : portalFiles) {
            StaticDocumentWrapper doc = new StaticDocumentWrapper();
            doc.title = file.Name;
            doc.subtitle = file.Subtitle__c;
            doc.doc_id = documentsMap.get(file.Id);
            doc.url = '../sfc/servlet.shepherd/document/download/' + doc.doc_id;
            returnList.add(doc);
        }
        return returnList;
    }

    public class DocumentWrapper {
        @AuraEnabled public String doc_id { get; set; }
        @AuraEnabled public String internal_doc_id { get; set; }
        @AuraEnabled public String meterName { get; set; }
        @AuraEnabled public String contract { get; set; }
        @AuraEnabled public Date doc_date { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public String doc_type { get; set; }
        @AuraEnabled public String file_type { get; set; }
        @AuraEnabled public String eSaleId { get; set; }
        @AuraEnabled public Date deliveryPeriod { get; set; }
        @AuraEnabled public Integer deliveryPeriodYear { get; set; }
    }

    public class StaticDocumentWrapper {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String subtitle { get; set; }
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public String doc_id { get; set; }
        @AuraEnabled public String eSaleId { get; set; }
        @AuraEnabled public String meterName { get; set; }
    }
}