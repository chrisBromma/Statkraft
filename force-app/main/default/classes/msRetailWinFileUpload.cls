/****************************************************************************************************
* Class msRetailWinFileUpload
*
*   Create By	:   Michael Demars (Statkraft)
*   Create Date	:
*   Description	:	Controller for the msRetailWinFileUpload Lightning Component.
*
*                   The main part of this Component is to present the user with a List of relevant Files and the
*                   ability to upload files first to Salesforce. This further kicks off a process that informs an outside
*                   REST interface that there are files to download to a downstream system that further validates
*                   the uploaded files. The status of the validation is being monitored asynchronously in intervals.
*
*                   After the validation ends or the procedure breaks down at any step in between, the corresponding
*                   ContentVersion records are updated and a feedback message for the Front End is constructed.
*
*                   TODO: There are hard coded customer Names inside the validation.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Michael Demars (Statkraft)                                  	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      02.05.2019              V2 for New Core Model
*   * Christian Gottlieb (mindsquare GmbH)      19.11.2019              V3 for multiple files and asynchronous
*                                                                       validation handling
*****************************************************************************************************/
public without sharing class msRetailWinFileUpload {
    @TestVisible
    private static Date today = Date.today();
    private static final Map<String, Integer> MONTHS = new Map<String, Integer> {
            'January' => 1,
            'February' => 2,
            'March' => 3,
            'April' => 4,
            'May' => 5,
            'June' => 6,
            'July' => 7,
            'August' => 8,
            'September' => 9,
            'October'  => 10,
            'November' => 11,
            'December' => 12
    };

    /**
     * @description -  retrieve latest uploads for list
     */
    @AuraEnabled
    public static UserFileWrapper getUploads(){
        Id currentUserId = UserInfo.getUserId();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        UserFileWrapper wrapper = new UserFileWrapper();

        // if the user has a parent contact, get the latest files (ContentVersion) of its parent account via the content links
        User runningUser = [SELECT  ContactId, Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(runningUser.ContactId != null) {
            wrapper.recordId = runningUser.Contact.AccountId;
            List<ContentDocumentLink> contentDocumentLinkList = [SELECT Id, ContentDocumentId
                                                                 FROM ContentDocumentLink
                                                                 WHERE LinkedEntityId = :runningUser.Contact.AccountId];
            if(contentDocumentLinkList.size() > 0) {
                Set<Id> contentDocumentIdSet = new Set<Id>();
                for(ContentDocumentLink cdl : contentDocumentLinkList) {
                    contentDocumentIdSet.add(cdl.ContentDocumentId);
                }

                contentVersionList = [
                        SELECT
                                Id,
                                OwnerId,
                                Title,
                                msIsUploaded__c,
                                msIsValidationPassed__c,
                                msUploadMessage__c,
                                CreatedDate,
                                FileExtension
                        FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIdSet ORDER BY CreatedDate DESC];
                wrapper.contentVersionList = contentVersionList;
            }
        }
        return wrapper;
    }

    /**
     * @description -   this method informs the quartz API Server that the files have been successfully uploaded to
     *                  Salesforce and can now be retrieved for validation. The validation happens during a separate
     *                  asynchronous interview
     *
     */
    @AuraEnabled
    public static List<UploadResult> initiateFilesValidation(List<Id> documentIds) {
        // Find the entity we're related and map it to a Retail customer
        User currentUser = [SELECT Contact.Account.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String customerName = '';
        if (currentUser.Contact.Account.Name.contains('Bryt')) {
            customerName = 'bryt';
        } else if (currentUser.Contact.Account.Name.contains('CNG')) {
            customerName = 'cng';
        } else if (currentUser.Contact.Account.Name.contains('Squeaky')) {
            customerName = 'sce';
        } else if (currentUser.Contact.Account.Name.contains('Corona')) {
            customerName = 'corona';
        } else {
            //Bad result, return that we can't identify the intended Customer
            List<UploadResult> results = new List<UploadResult>();
            for(ContentVersion fileItem : [ SELECT Title FROM ContentVersion
                                            WHERE ContentDocumentId IN :documentIds
                                            AND IsLatest=TRUE]) {
                UploadResult resultItem = new UploadResult();
                resultItem.Success = false;
                resultItem.Errors = new List<String> {'Unexpected Parent Account: ' + currentUser.Contact.Account.Name};
                resultItem.FileName = fileItem.Title;
                results.add(resultItem);
            }
            return results;

        }

        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();

        String endpoint = apiSettings.RetailWinFile_Upload_Endpoint__c;
        for(Integer i = 0; i < documentIds.size(); i++) {
            if(i == 0) {
                endpoint += '?fileIds=' + documentIds[i];
            } else {
                endpoint += '&fileIds=' + documentIds[i];
            }
            endpoint += '&customer=' + customerName;
        }

        String apiKey = apiSettings.RetailWinFile_API_Key__c;
        HttpResponse response = msUtility.getHttp(endpoint, '', 'POST', apiKey);
        String body = response.getBody();

        if (response.getStatus() == 'OK') {
            List<UploadResult> results = (List<UploadResult>) JSON.deserialize(body, List<UploadResult>.class);
            handleUploadResults(documentIds, results);
            return results;
        } else {
            List<UploadResult> results = new List<UploadResult>();
            for(Integer i=0; i<documentIds.size();i++) {
                UploadResult result = new UploadResult();
                result.Errors = new List<String>();
                result.Errors.add('Processing failed: Error ' + response.getStatusCode() + '. Message: ' + body);
                result.Success = false;
                result.FileId = documentIds[i];
                result.FileName = '';
                results.add(result);
            }
            handleUploadResults(documentIds, results);
            return results;
        }
    }

    /**
     *
     * @description Calls the external API to get an update on the validation status and proceeds to update records
     *              accordingly as well as generate feedback for the Front End.
     *
     */
    @AuraEnabled
    public static List<ValidationResult> retrieveValidationResults() {

            User runningUser = [SELECT Contact.AccountId FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
            List<Id> linkIds = new List<Id>();
            List<ContentDocumentLink> accountFileLinks = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :runningUser.Contact.AccountId
            ];
            for(ContentDocumentLink linkItem : accountFileLinks) {
                linkIds.add(linkItem.ContentDocumentId);
            }
            List<Id> documentIds = new List<Id>();
            List<ContentVersion> unvalidatedFiles = [
                    SELECT ContentDocumentId FROM ContentVersion
                    WHERE msIsUploaded__c = TRUE
                    AND msIsValidationPassed__c = FALSE
                    AND ContentDocumentId IN :linkIds
            ];
            if(unvalidatedFiles.size() > 0) {
                for(ContentVersion fileItem : unvalidatedFiles) {
                    documentIds.add(fileItem.ContentDocumentId);
                }
                Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();

                String endpoint = apiSettings.RetailWinfile_Validation_Status_Endpoint__c;
                for(Integer i = 0; i < documentIds.size(); i++) {
                    if(i == 0) {
                        endpoint += '?fileIds=' + documentIds[0];
                    } else {
                        endpoint += '&fileIds=' + documentIds[i];
                    }
                }

                String apiKey = apiSettings.RetailWinFile_API_Key__c;
                HttpResponse response = msUtility.getHttp(endpoint, null, 'GET', apiKey);
                String body = response.getBody();

                if (response.getStatus() == 'OK') {
                    List<ValidationResult> results = (List<ValidationResult>) JSON.deserialize(body, List<ValidationResult>.class);
                    handleValidationResults(documentIds, results);
                    return results;
                } else {
                    throw new AuraHandledException('The validation server encountered an error, please try again later');
                }
            } else {
                return null;
            }
    }
    /**
     *
     * @description Checks whether we are currently inside the UKRetail Business Hours
     */
    @AuraEnabled
    public static Boolean isInBusinessHours() {
        Date saturday = Date.newInstance(1900, 1, 6);
        Date sunday = Date.newInstance(1900, 1, 7);
        Integer modSaturday = Math.mod(today.daysBetween(saturday),7);
        Integer modSunday = Math.mod(today.daysBetween(sunday),7);

        msPortalSystemSetting__mdt portalSettings = msUtility.getPortalSettings();

        Date targetDate = today;
        Time targetTimeStart = Time.newInstance((Integer)portalSettings.RetailStartTimeHour__c,
                (Integer) portalSettings.RetailStartTimeMinute__c, 0, 0);
        Time targetTimeEnd = Time.newInstance((Integer)portalSettings.RetailEndTimeHour__c,
                (Integer) portalSettings.RetailEndTimeMinute__c, 0, 0);

        TimeZone targetTimezone = TimeZone.getTimeZone('Europe/London');
        Integer offsetSeconds = targetTimezone.getOffset(targetDate) / 1000;

        Datetime targetDatetimeStart = Datetime.newInstanceGmt(targetDate, targetTimeStart)
                .addSeconds(-offsetSeconds);
        Datetime targetDatetimeEnd = Datetime.newInstanceGmt(targetDate, targetTimeEnd)
                .addSeconds(-offsetSeconds);

        if(getHolidayDatesToday().contains(today) ||
                modSaturday == 0 ||
                modSunday == 0 ||
                Datetime.now() < targetDatetimeStart ||
                Datetime.now() > targetDatetimeEnd) {
            return false;
        } else {
            return true;
        }
    }

    /**
     *
     * @description Updates the connected ContentVersion records to state the progress of the upload process and adjusts
     *              the feedback messages for the frontend if necessary.
     */
    private static void handleUploadResults(List<Id> documentIds, List<UploadResult> uploadResults) {
        List<ContentVersion> documents = [
                SELECT ContentDocumentId, Title
                FROM ContentVersion
                WHERE ContentDocumentId IN :documentIds
                AND IsLatest = TRUE
        ];
        Map<Id, ContentVersion> documentIdToDocumentMap = new Map<Id, ContentVersion>();
        for(ContentVersion documentItem : documents) {
            documentIdToDocumentMap.put(documentItem.ContentDocumentId, documentItem);
        }
        Map<Id, UploadResult> documentIdToResultMap = new Map<Id, UploadResult>();

        for(UploadResult resultItem : uploadResults) {
            documentIdToResultMap.put(resultItem.FileId, resultItem);
        }
        for(Id documentIdItem : documentIds) {
            if(documentIdToResultMap.containsKey(documentIdItem) && documentIdToDocumentMap.containsKey(documentIdItem)) {
                ContentVersion document = documentIdToDocumentMap.get(documentIdItem);
                UploadResult result = documentIdToResultMap.get(documentIdItem);
                if(result.FileName == '') {
                    result.FileName = document.Title;
                }
                if(result.Success) {
                    document.msUploadMessage__c = 'File successfully uploaded, validation requested';
                    document.msIsUploaded__c = true;
                    document.msIsValidationPassed__c = false;
                } else {
                    document.msUploadMessage__c = formatMessage(result.Errors);
                    document.msIsUploaded__c = false;
                    document.msIsValidationPassed__c = false;
                }
            } else if(!documentIdToDocumentMap.containsKey(documentIdItem)) {
                if(documentIdToResultMap.containsKey(documentIdItem)) {
                    UploadResult result = documentIdToResultMap.get(documentIdItem);
                    result.Errors.add('File deleted from Salesforce Database');
                    result.Errors.add('File validation initiated successfully prior');
                    result.Success = false;
                } else {
                    UploadResult newResult = new UploadResult();
                    newResult.Success = false;
                    newResult.Errors = new List<String>{'File upload to Salesforce failed','No response from validation System'};
                    newResult.FileId = documentIdItem;
                    newResult.FileName = 'Unknown';
                    uploadResults.add(newResult);
                }
            } else if(!documentIdToResultMap.containsKey(documentIdItem)) {
                UploadResult newResult = new UploadResult();
                newResult.Success = false;
                newResult.FileName = documentIdToDocumentMap.get(documentIdItem).Title;
                newResult.FileId = documentIdToDocumentMap.get(documentIdItem).ContentDocumentId;
                newResult.Errors = new List<String>{'Upload to Salesforce successful','Received no answer from validation server'};
                uploadResults.add(newResult);
                ContentVersion document = documentIdToDocumentMap.get(documentIdItem);
                document.msUploadMessage__c = 'Upload to Salesforce successful; Received no answer from validation Server';
                document.msIsUploaded__c = false;
                document.msIsValidationPassed__c = false;
            }
        }
        update documents;
    }

    /**
     * @description Handles the results for a status update on a validation request
     */
    private static void handleValidationResults(List<Id> documentIds, List<ValidationResult> validationResults) {
        List<ContentVersion> documents = [
                SELECT ContentDocumentId, Title, msUploadMessage__c
                FROM ContentVersion
                WHERE ContentDocumentId IN :documentIds
                AND IsLatest = TRUE
        ];
        Map<Id, ContentVersion> documentIdToDocumentMap = new Map<Id, ContentVersion>();
        for(ContentVersion documentItem : documents) {
            documentIdToDocumentMap.put(documentItem.ContentDocumentId, documentItem);
        }
        Map<Id, ValidationResult> documentIdToResultMap = new Map<Id, ValidationResult>();
        for(ValidationResult resultItem : validationResults) {
            documentIdToResultMap.put(resultItem.FileId, resultItem);
        }

        for(Id documentIdItem : documentIds) {
            if(documentIdToResultMap.containsKey(documentIdItem) && documentIdToDocumentMap.containsKey(documentIdItem)) {
                ContentVersion document = documentIdToDocumentMap.get(documentIdItem);
                ValidationResult result = documentIdToResultMap.get(documentIdItem);
                if(result.FileName == '') {
                    result.FileName = document.Title;
                }
                switch on result.Status {
                    when -9 {
                        document.msIsUploaded__c = true;
                        document.msIsValidationPassed__c = false;
                        if(result.Messages.size() == 0) {
                            document.msUploadMessage__c = 'File successfully uploaded, File enqueued for validation';
                        } else {
                            document.msUploadMessage__c = formatMessage(result.Messages);
                        }
                    }
                    when -1 {
                        document.msIsUploaded__c = false;
                        document.msIsValidationPassed__c = false;
                        if(result.Messages.size() == 0) {
                            document.msUploadMessage__c = 'File failed validation';
                        } else {
                            document.msUploadMessage__c = formatMessage(result.Messages);
                        }
                    }
                    when 0 {
                        document.msIsUploaded__c = true;
                        document.msIsValidationPassed__c = false;
                        if(result.Messages.size() == 0) {
                            document.msUploadMessage__c = 'File successfully uploaded, File is being processed for validation';
                        } else {
                            document.msUploadMessage__c = formatMessage(result.Messages);
                        }
                    }
                    when 1 {
                        document.msIsUploaded__c = true;
                        document.msIsValidationPassed__c = true;
                        if(result.Messages.size() == 0) {
                            document.msUploadMessage__c = 'File successfully validated';
                        } else {
                            document.msUploadMessage__c = formatMessage(result.Messages);
                        }
                    }
                    when else {
                        //unexpected behaviour
                        document.msIsUploaded__c = true;
                        document.msIsValidationPassed__c = false;
                        if(result.Messages.size() == 0) {
                            document.msUploadMessage__c = 'File uploaded, validation status unknown';
                        } else {
                            document.msUploadMessage__c = formatMessage(result.Messages);
                        }
                    }
                }
            } else if(!documentIdToResultMap.containsKey(documentIdItem) && documentIdToDocumentMap.containsKey(documentIdItem)) {
                ContentVersion document = documentIdToDocumentMap.get(documentIdItem);
                document.msUploadMessage__c += ', Last validation status request did not send an answer';
            }
        }
        update documents;
    }


    private static String formatMessage(List<String> messages) {
        String finalMessage = '';
        for (String message : messages) {
            if (finalMessage.length() > 0) {
                finalMessage = finalMessage + '\n' + message;
            } else {
                finalMessage = message;
            }
        }
        return finalMessage;
    }

    private static Set<Date> getHolidayDatesToday() {
        List<Operational_Holiday__c> holidays = [
                SELECT Affected_Date__c
                FROM Operational_Holiday__c
                WHERE (Market__c = 'UK' OR Market__c = 'UKRetail')
                AND Affected_Date__c = :Date.today()
        ];
        Set<Date> holidayDates = new Set<Date>();
        for(Operational_Holiday__c holiday : holidays) {
            holidayDates.add(holiday.Affected_Date__c);
        }
        return holidayDates;
    }

    public class UserFileWrapper {
        @AuraEnabled public Id recordId {get; set;}
        @AuraEnabled public List<ContentVersion> contentVersionList {get; set;}
    }
    public class UploadResult {
        @AuraEnabled public Boolean Success { get; set; }
        @AuraEnabled public List<String> Errors { get; set; }
        @AuraEnabled public String FileName { get; set; }
        @AuraEnabled public Id FileId { get; set; }
    }
    public class ValidationResult {
        /**Status:  -9: waiting for process;
                    -1: Failed;
                    0: In progress;
                    1: Success; */
        @AuraEnabled public Integer Status { get; set; }
        @AuraEnabled public List<String> Messages { get; set; }
        @AuraEnabled public String FileName { get; set; }
        @AuraEnabled public Id FileId { get; set; }
    }
}