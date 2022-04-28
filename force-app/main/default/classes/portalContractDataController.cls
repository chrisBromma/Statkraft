/**
 * Created by u52448 on 02.09.2021.
 */

public without sharing class portalContractDataController {

    @AuraEnabled
    public static contractData getContractData(String contractId) {

        contractData contractData = new contractData();
        if(String.isNotBlank(contractId) && msUtility.checkObjectAccess(contractId,'Contract__c'))
        {
            Contract__c contract = [
                    SELECT IBAN__c, BIC_Code__c, Bank_Name__c,Bank_Account_Owner__c,Contract_Holder__r.Id,
                            Contract_Holder__r.Name, Contract_Holder__r.VAT_Number__c, Contract_Holder__r.company_tax_number__c, Customer_Portal_Master_Data_Update__c,
                            Contract_Holder__r.VAT_Reseller__c, Contract_Holder__r.REMIT_Acer_Code__c, Contract_Holder__r.BillingAddress, Contract_Holder__r.ShippingAddress
                    FROM Contract__c
                    WHERE Id = :contractId
            ];

            Recipient mailRecipient = getRecipientByType(contractId, msUtility.MAIL_RECIPIENT_CONTRACT_ROLE);
            Recipient paymentRecipient = getRecipientByType(contractId, msUtility.PAYMENT_RECIPIENT_CONTRACT_ROLE);

            accountDetails contractHolderDetails = new accountDetails();
            if(contract.Contract_Holder__r != null){
                contractHolderDetails.accountId = contract.Contract_Holder__r.Id;
                contractHolderDetails.accountName = contract.Contract_Holder__r.Name;
                contractHolderDetails.vatNumber = contract.Contract_Holder__r.VAT_Number__c;
                contractHolderDetails.companyTaxNumber = contract.Contract_Holder__r.company_tax_number__c;
                contractHolderDetails.isVatReseller = String.valueOf(contract.Contract_Holder__r.VAT_Reseller__c);
                contractHolderDetails.remitAcerCode = contract.Contract_Holder__r.REMIT_Acer_Code__c;
            }

            bankDetails bankDetails = new bankDetails();
            bankDetails.bankAccountHolder = contract.Bank_Account_Owner__c;
            bankDetails.bicCode = contract.BIC_Code__c;
            bankDetails.IBAN = maskBankAccountNumber(contract.IBAN__c);

            contractData.contractHolderDetails = contractHolderDetails;
            contractData.bankDetails = bankDetails;
            contractData.masterDataIsUptoDate = contract.Customer_Portal_Master_Data_Update__c;
            contractData.paymentRecipient = paymentRecipient != null ? paymentRecipient : null;
            contractData.mailRecipient = mailRecipient != null ? mailRecipient : null;
        }

        return contractData;
    }

    @AuraEnabled
    public static void setMasterDataIsUptoDate(String contractId) {
        if(String.isNotBlank(contractId) && msUtility.checkObjectAccess(contractId,'Contract__c'))
        {
            Contract__c contract = [SELECT Customer_Portal_Master_Data_Update__c FROM Contract__c WHERE Id = :contractId];
            if (contract.Customer_Portal_Master_Data_Update__c == false) {
                contract.Customer_Portal_Master_Data_Update__c = true;
                update contract;

                Logger.info('Master data (commercial) is updated/confirmed by customer as upto date', contractId);
                Logger.saveLog('Master Data (Commercial) update via customer portal');
            }
        }
    }

    @AuraEnabled
    public static void sendCommercialMasterData(String contractId, String currentContractData, String newContractData, String supportingDocuments) {

        if (String.isNotBlank(contractId) && msUtility.checkObjectAccess(contractId,'Contract__c') && currentContractData != null && newContractData != null) {
            String queueName = msUtility.SALES_COORDINATORS_EEG_QUEUE_API_NAME;
            List<QueueSobject> queueList = [SELECT Id, QueueId FROM QueueSobject WHERE SObjectType = 'Case' AND Queue.DeveloperName = :queueName];

            if (queueList.size() > 0) {

                contractData contractDataCurrent = (contractData) JSON.deserializeStrict(currentContractData, contractData.class);
                contractData contractDataNew = (contractData) JSON.deserializeStrict(newContractData, contractData.class);
                Id userId = UserInfo.getUserId();
                User user = [SELECT ContactId FROM User WHERE Id = :userId];
                String changeRequestData = composeChangeRequestText(contractDataCurrent, contractDataNew);

                Case newCase = new Case(
                        RecordTypeId = Application.RecordTypes.byDeveloperName('Case', 'Customer_Portal_Master_Data_Change_Request_Case').Id,
                        Status= 'New',
                        Contract__c = contractId,
                        OwnerId = queueList.get(0).QueueId,
                        Case_Creator__c = msUtility.getSystemUserId(),
                        ContactId = user.ContactId,
                        AccountId = contractDataCurrent.contractHolderDetails.accountId,
                        Origin = msUtility.CASE_ORIGIN_WEB,
                        Reason = msUtility.CASE_REASON_MASTER_DATA_CHANGE,
                        Subject = 'Yearly Master Data Update via Portal',
                        Description = 'Please review the entered master data change request and attached documents from the customer. Apply necessary changes in Salesforce and forward case to DE PPA Contract Operations.',
                        Master_Data_Change_Request__c = changeRequestData
                );
                insert newCase;

                if(String.isNotBlank(supportingDocuments)){
                    List<fileContent> files = (List<fileContent>) JSON.deserializeStrict(supportingDocuments, List<fileContent>.class);
                    if(files != null && !files.isEmpty()){
                        set<Id> uploadedFileIds = uploadFiles(files);
                        linkFilesToCase(newCase.Id, uploadedFileIds);
                    }
                }

                setMasterDataIsUptoDate(contractId);

            } else {
                throw new AuraHandledException(Label.msMasterDataErrorMessage);
            }
        } else {
            throw new AuraHandledException(Label.msMasterDataErrorMessage);
        }

    }

    private static String composeChangeRequestText(contractData currentValues, contractData newValues) {
        if (currentValues != null && newValues != null) {
            String companyRow = '';
            String vatNumberRow = '';
            String isResellerRow = '';
            String companyTaxNoRow = '';
            String remitAcerCodeRow = '';
            String bankDetailsHeadingRow = '';
            String bankAccountHolderRow = '';
            String ibanRow = '';
            String bicCodeRow = '';
            String addressHeadingRow = '';
            String paymentRecipientRow = '';
            String mailRecipientRow = '';

            if (newValues.contractHolderDetails != null) {
                companyRow = String.isNotBlank(newValues.contractHolderDetails.accountName) ?
                        '<tr>' +
                                '<td valign="top"><p>Company</p></td>' +
                                '<td valign="top"><p>' + currentValues.contractHolderDetails.accountName + '</p></td>' +
                                '<td valign="top"><p>' + newValues.contractHolderDetails.accountName + '</p></td>' +
                                '</tr>' : '';

                vatNumberRow = String.isNotBlank(newValues.contractHolderDetails.vatNumber) ?
                        '<tr>' +
                                '<td valign="top"><p>VAT Number</p></td>' +
                                '<td valign="top"><p>' + currentValues.contractHolderDetails.vatNumber + '</p></td>' +
                                '<td valign="top"><p>' + newValues.contractHolderDetails.vatNumber + '</p></td>' +
                                '</tr>' : '';

                isResellerRow = String.isNotBlank(newValues.contractHolderDetails.isVatReseller) ?
                        '<tr>' +
                                '<td valign="top"><p>VAT Reseller according to UStG §3g</p></td>' +
                                '<td valign="top"><p>' + (String.isNotBlank(currentValues.contractHolderDetails.isVatReseller) && currentValues.contractHolderDetails.isVatReseller == 'false' ? 'No' : 'Yes') + '</p></td>' +
                                '<td valign="top"><p>' + (String.isNotBlank(newValues.contractHolderDetails.isVatReseller) && newValues.contractHolderDetails.isVatReseller == 'false' ? 'No' : 'Yes') + '</p></td>' +
                                '</tr>' : '';

                companyTaxNoRow = String.isNotBlank(String.valueOf(newValues.contractHolderDetails.companyTaxNumber)) ?
                        '<tr>' +
                                '<td valign="top"><p>Company Tax Number (if applicable)</p></td>' +
                                '<td valign="top"><p>' + currentValues.contractHolderDetails.companyTaxNumber + '</p></td>' +
                                '<td valign="top"><p>' + newValues.contractHolderDetails.companyTaxNumber + '</p></td>' +
                                '</tr>' : '';

                remitAcerCodeRow = String.isNotBlank(newValues.contractHolderDetails.remitAcerCode) ?
                        '<tr>' +
                                '<td valign="top"><p>REMIT Acer Code</p></td>' +
                                '<td valign="top"><p style="pointer-events: none;">' + currentValues.contractHolderDetails.remitAcerCode + '</p></td>' +
                                '<td valign="top"><p style="pointer-events: none;">' + newValues.contractHolderDetails.remitAcerCode + '</p></td>' +
                                '</tr>' : '';

            }

            if (!(newValues.paymentRecipient == null && newValues.mailRecipient == null)) {
                addressHeadingRow =
                        '<tr>' +
                                '<td valign="top"><p><strong>Address Data</strong></p></td>' +
                                '<td valign="top"> </td>' +
                                '<td valign="top"> </td>' +
                                '</tr>';

                paymentRecipientRow = newValues.paymentRecipient != null ?
                        ('<tr>' +
                                '<td valign="top"><p>Billing Address</p></td>' +
                                '<td valign="top">' +
                                (currentValues.paymentRecipient == null ? '' :
                                (String.isNotBlank(currentValues.paymentRecipient.mailAddOn) ? '<p><b>Mail Add On:</b> ' + currentValues.paymentRecipient.mailAddOn + '</p>' : '') +
                                '<p><b>Address:</b> ' + addressToString(currentValues.paymentRecipient) + '</p>') +
                                '</td>' +
                                '<td valign="top">' +
                                (String.isNotBlank(newValues.paymentRecipient.mailAddOn) ? '<p><b>Mail Add On:</b> ' + newValues.paymentRecipient.mailAddOn + '</p>' : '') +
                                '<p><b>Address:</b> ' + addressToString(newValues.paymentRecipient) + '</p>' +
                                '</td>' +
                                '</tr>') : '';
                
                mailRecipientRow = newValues.mailRecipient != null ?
                        ('<tr>' +
                                '<td valign="top"><p>Shipping Address</p></td>' +
                                '<td valign="top">' +
                                (currentValues.mailRecipient == null ? '' :
                                (String.isNotBlank(currentValues.mailRecipient.company) ? '<p><b>Company:</b> ' + currentValues.mailRecipient.company + '</p>' : '') +
                                (String.isNotBlank(currentValues.mailRecipient.mailAddOn) ? '<p><b>Mail Add On:</b> ' + currentValues.mailRecipient.mailAddOn + '</p>' : '') +
                                '<p><b>Address:</b> ' + addressToString(currentValues.mailRecipient) + '</p>') +
                                '</td>' +
                                '<td valign="top">' +
                                (String.isNotBlank(newValues.mailRecipient.company) ? '<p><b>Company:</b> ' + newValues.mailRecipient.company + '</p>' : '') +
                                (String.isNotBlank(newValues.mailRecipient.mailAddOn) ? '<p><b>Mail Add On:</b> ' + newValues.mailRecipient.mailAddOn + '</p>' : '') +
                                '<p><b>Address:</b> ' + addressToString(newValues.mailRecipient) + '</p>' +
                                '</td>' +
                                '</tr>') : '';
            }

            if (newValues.bankDetails != null) {
                bankDetailsHeadingRow =
                        '<tr>' +
                                '<td valign="top"><p><strong>Bank Details</strong></p></td>' +
                                '<td valign="top"> </td>' +
                                '<td valign="top"> </td>' +
                                '</tr>';

                bankAccountHolderRow = String.isNotBlank(newValues.bankDetails.bankAccountHolder) ?
                        '<tr>' +
                                '<td valign="top"><p>Account Holder Name</p></td>' +
                                '<td valign="top"><p>' + currentValues.bankDetails.bankAccountHolder + '</p></td>' +
                                '<td valign="top"><p>' + newValues.bankDetails.bankAccountHolder + '</p></td>' +
                                '</tr>' : '';

                ibanRow = String.isNotBlank(newValues.bankDetails.IBAN) ?
                        '<tr>' +
                                '<td valign="top"><p>IBAN</p></td>' +
                                '<td valign="top"><p>' + currentValues.bankDetails.IBAN + '</p></td>' +
                                '<td valign="top"><p>' + newValues.bankDetails.IBAN + '</p></td>' +
                                '</tr>' : '';

                bicCodeRow = String.isNotBlank(newValues.bankDetails.bicCode) ?
                        '<tr>' +
                                '<td valign="top"><p>BIC Code</p></td>' +
                                '<td valign="top"><p>' + currentValues.bankDetails.bicCode + '</p></td>' +
                                '<td valign="top"><p>' + newValues.bankDetails.bicCode + '</p></td>' +
                                '</tr>' : '';

            }

            String html = '<table border="1" cellspacing="0" cellpadding="0">' +
                    '<tbody>' +
                    '<tr>' +
                    '<td valign="top"> </td>' +
                    '<td valign="top"><p><strong>Current Value</strong></p></td>' +
                    '<td valign="top"><p><strong>New value</strong></p></td>' +
                    '</tr>' +
                    companyRow +
                    vatNumberRow +
                    isResellerRow +
                    companyTaxNoRow +
                    remitAcerCodeRow +
                    bankDetailsHeadingRow +
                    bankAccountHolderRow +
                    ibanRow +
                    bicCodeRow +
                    addressHeadingRow +
                    paymentRecipientRow +
                    mailRecipientRow +
                    '</tbody>' +
                    '</table>';

            return html;
        } else {
            return '';
        }
    }

    private static Recipient getRecipientByType(Id contractId, String role) {
        if (!String.isEmpty(contractId) && !String.isEmpty(role)) {
            List<Contract_Role__c> contractRoles = new List<Contract_Role__c>();
            if(role == msUtility.MAIL_RECIPIENT_CONTRACT_ROLE){
                contractRoles = [
                        SELECT Account__r.Name, Account__r.ShippingAddress, Mail_Add_On__c
                        FROM Contract_Role__c
                        WHERE Contract__c = :contractId AND Role__c = :role
                        AND (End_Date__c = NULL OR End_Date__c >= TODAY)
                        ORDER BY Start_Date__c
                ];
            }

            if(role == msUtility.PAYMENT_RECIPIENT_CONTRACT_ROLE){
                contractRoles = [
                        SELECT Account__r.BillingAddress, Mail_Add_On__c
                        FROM Contract_Role__c
                        WHERE Contract__c = :contractId AND Role__c = :role
                        AND (End_Date__c = NULL OR End_Date__c >= TODAY)
                        ORDER BY Start_Date__c
                ];
            }

            if (!contractRoles.isEmpty()) {
                Contract_Role__c contractRole = contractRoles.get(0);
                Address address = new Address();
                Recipient recipient = new Recipient();
                recipient.mailAddOn = contractRole.Mail_Add_On__c;

                if(role == msUtility.MAIL_RECIPIENT_CONTRACT_ROLE){
                    address = contractRole.Account__r.ShippingAddress;
                    recipient.company = contractRole.Account__r.Name;
                }
                else if(role == msUtility.PAYMENT_RECIPIENT_CONTRACT_ROLE){
                    address = contractRole.Account__r.BillingAddress;
                }

                if(address != null){
                    recipient.street = address.street;
                    recipient.postalCode = address.postalCode;
                    recipient.city = address.city;
                    recipient.country = address.country;
                    return (contractRole != null ? recipient : null);
                }
                else{
                    return null;
                }
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    private static String maskBankAccountNumber(String iban) {
        if (!String.isEmpty(iban)) {
            String last5Digits = iban.right(5);
            String replacedString = iban.left(iban.length() - 5).replaceAll('\\d', 'X');
            String maskedString = replacedString + last5Digits;
            return maskedString;
        }
        return '';
    }

    private static String addressToString(Recipient address) {

        if (address != null) {
            String addressLine1 = String.isBlank(address.street) ? '' : '<p>' + address.street + '</p>';
            String addressLine2 = String.isBlank(address.postalCode) && String.isBlank(address.city) ? '' : '<p>' + address.postalCode + ' ' + address.city + '</p>';
            String addressLine3 = String.isBlank(address.country) ? '' : '<p>' + address.country + '</p>';
            string result = String.join(new String[]{addressLine1, addressLine2, addressLine3}, '');
            return result;
        }
        return '';
    }

    private static Set<Id> uploadFiles(List<fileContent> files) {
        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        Map<Id, ContentVersion> contentVersionsMap = new Map<Id, ContentVersion>();

        for (fileContent f : files) {
            String base64Data = EncodingUtil.urlDecode(f.base64Content, 'UTF-8');
            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.ContentLocation = 'S';
            cv.PathOnClient = f.fileName;
            contentVersionsToInsert.add(cv);
        }
        insert contentVersionsToInsert;

        contentVersionsMap.putAll(contentVersionsToInsert);
        return contentVersionsMap.keySet();
    }

    private static void linkFilesToCase(Id caseId, Set<Id> contentVersionIds) {

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId from ContentVersion WHERE Id IN :contentVersionIds];
        for (ContentVersion document : contentVersions) {
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = document.ContentDocumentId;
            link.LinkedEntityId = caseId;
            contentDocumentLinks.add(link);
        }

        insert contentDocumentLinks;

    }

    public class contractData {
        @AuraEnabled public accountDetails contractHolderDetails { get; set; }
        @AuraEnabled public bankDetails bankDetails { get; set; }
        @AuraEnabled public Boolean masterDataIsUptoDate { get; set; }
        @AuraEnabled public recipient  paymentRecipient { get; set; }
        @AuraEnabled public recipient mailRecipient { get; set; }
    }

    public class accountDetails {
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String accountName
        {
            get {return accountName;}
            set {accountName = String.IsBlank(value) ? '' : value;}
        }
        @AuraEnabled public String vatNumber
        {
            get {return vatNumber;}
            set {vatNumber = String.IsBlank(value) ? '' : value;}
        }
        @AuraEnabled public String companyTaxNumber
        {
            get {return companyTaxNumber;}
            set {companyTaxNumber = String.IsBlank(value) ? '' : value;}
        }
        @AuraEnabled public String isVatReseller {get; set;}
        @AuraEnabled public String remitAcerCode
        {
            get {return remitAcerCode;}
            set {remitAcerCode = String.IsBlank(value) ? '' : value;}
        }
    }

    public class bankDetails {
        @AuraEnabled public String bankAccountHolder
        {
            get {return bankAccountHolder;}
            set {bankAccountHolder = String.IsBlank(value) ? '' : value;}
        }
        @AuraEnabled public String bicCode
        {
            get {return bicCode;}
            set {bicCode = String.IsBlank(value) ? '' : value;}
        }
        @AuraEnabled public String IBAN
        {
            get {return IBAN;}
            set {IBAN = String.IsBlank(value) ? '' : value;}
        }
    }

    public class fileContent {
        public string fileName { get; set; }
        public string base64Content { get; set; }
    }

    public class Recipient {
        @AuraEnabled public String mailAddOn {get; set;}
        @AuraEnabled public String company {get; set;}
        @AuraEnabled public String street {get; set;}
        @AuraEnabled public String city {get; set;}
        @AuraEnabled public String postalCode {get; set;}
        @AuraEnabled public String country {get; set;}
    }
}