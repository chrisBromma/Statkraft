/****************************************************************************************************
* Class msPaymentController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   10.10.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   10.10.2018      	    Init version.
*****************************************************************************************************/

public with sharing class msPaymentController {
    public static Map<String, Object> paymentDocMap = (Map<String, Object>) JSON.deserializeUntyped(Label.msPaymentDocMap);
    public static Map<String, Object> paymentProductMap = (Map<String, Object>) JSON.deserializeUntyped(Label.msPaymentProductMap);

    @AuraEnabled
    public static PaymentResponseWrapper getPayment(String accountId) {
        PaymentResponseWrapper responseWrapper = new PaymentResponseWrapper();
        List<Payment> payments = new List<Payment>();
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
        responseWrapper.excelFileLabels = excelFileHeaderLabels();
        Map<String, String>accountIdToContractName = new Map<String, String>();

        Date dateTwoYearsAgoFromToday = Date.today().addYears(-2);
        String endpoint = ApiSettings.Payments_Endpoint__c;
        msUtility.UserDetails userDetails = msUtility.getUserDetails();
        List<Id> contractIds = new List<Id>();

        for (Contract__c tempContract : userDetails.contracts) {
            contractIds.add(tempContract.Id);
        }
        List<Contract__c> contracts = [SELECT Name, Contract_Holder__r.Name FROM Contract__c WHERE Id IN:contractIds];

        for (Contract__c contract : contracts) {
            responseWrapper.accounts.add(contract.Contract_Holder__r);
            accountIdToContractName.put(contract.Contract_Holder__c, contract.Name);

            if (accountId != null && contract.Contract_Holder__c == accountId) {
                responseWrapper.selectedAccount = contract.Contract_Holder__r;
            }
        }
        if (responseWrapper.selectedAccount == null) {
            responseWrapper.selectedAccount = contracts[0].Contract_Holder__r;
        }

        String contractName = accountIdToContractName.get(responseWrapper.selectedAccount.Id);
        //contractName = '100060'; //TODO remove!

        String filter = '?cp=' + contractName.replaceAll('^FR0+|^DE0+|/([^/])$', '') + '&fkdatStart=' + String.valueOf(dateTwoYearsAgoFromToday) + '';
        HttpResponse response = msUtility.getHttp(endpoint + filter, null, 'GET');
        if (response.getStatusCode() == 200) {
            String body = response.getBody().replaceAll('__metadata', 'metadata');
            payments = (List<Payment>) System.JSON.deserializeStrict(body, List<Payment>.class);

            List<msDocuments.DocumentWrapper> documents = msDocuments.fetchDocuments();
            Map<String, msDocuments.DocumentWrapper> documentsByDocId = new Map<String, msDocuments.DocumentWrapper>();
            for (msDocuments.DocumentWrapper tmpWrapper : documents) {
                documentsByDocId.put(tmpWrapper.internal_doc_id, tmpWrapper);
            }

            for (Payment tmpPayment : payments) {
                tmpPayment.Augdt = parseDate(tmpPayment.Augdt);
                tmpPayment.Bldat = parseDate(tmpPayment.Bldat);
                tmpPayment.Fkdat = parseDate(tmpPayment.Fkdat);
                tmpPayment.Zfbdt = parseDate(tmpPayment.Zfbdt);

                if (paymentDocMap.get(tmpPayment.Blart) != null) {
                    tmpPayment.Blart = (String) paymentDocMap.get(tmpPayment.Blart);
                    if (tmpPayment.Blart != 'Payment') {
                        tmpPayment = parseSgtxt(tmpPayment);
                    }
                    else {
                            tmpPayment.Product = '';
                            tmpPayment.Contract = '';
                    }
                }
                if (documentsByDocId.get(tmpPayment.VbelnVf) != null) {
                    tmpPayment.downloadURL = documentsByDocId.get(tmpPayment.VbelnVf).url;
                }
            }

            //Remove internal items that should not be shown
            Integer j = 0;
            while (j < payments.size()) {
                if (payments.get(j).Sgtxt.startsWith(Label.msPaymentApiRemoveKey)) {
                    payments.remove(j);
                } else {
                    j++;
                }
            }
        }
        responseWrapper.payments = payments;
        return responseWrapper;
    }

    public static String parseDate(String dateString) {
        try {
            if (dateString == '00000000')
                return null;

            Integer year = Integer.valueOf(dateString.substring(0, 4));
            Integer month = Integer.valueOf(dateString.substring(4, 6));
            Integer day = Integer.valueOf(dateString.substring(6, 8));

            Date result = Date.newInstance(year, month, day);
            return String.valueOf(result);
        } catch (Exception e) {
            return null;
        }
    }

    private static List<String> excelFileHeaderLabels()
    {
        List<String> headers = new List<String>();
        headers.add(Label.msPaymentTableStatus);
        headers.add(Label.msPaymentTableDate);
        headers.add(Label.msPaymentTableType);
        headers.add(Label.msPaymentTableDocNr);
        headers.add(Label.msPaymentTableDocDate);
        headers.add(Label.msPaymentTableAmount);
        headers.add(Label.msPaymentTableCurrency);
        headers.add(Label.msPaymentTablePeriod);
        headers.add(Label.msPaymentTableProduct);
        headers.add(Label.msPaymentTableContract);
        return headers;
    }

    public static Payment parseSgtxt(Payment tmpPayment) {
        String inputString = tmpPayment.Sgtxt;
        tmpPayment.Period = '';
        tmpPayment.Product = '';
        tmpPayment.Contract = '';

        if (inputString != '') {
            try {
                Integer year = Integer.valueOf(inputString.substring(0, 4));
                Integer month = Integer.valueOf(inputString.substring(4, 6));
                Date result = Date.newInstance(year, month, 1);
                tmpPayment.Period = String.valueOf(result);

                tmpPayment.Contract = inputString.substring(inputString.indexOf('_') + 1, inputString.length());
                if (tmpPayment.Contract.isNumeric() == false) {
                    Integer value = 0;
                    for (String part : tmpPayment.Contract.split('[^0-9]')) {
                        if (part.isNumeric() && Integer.valueOf(part) > value)
                            value = Integer.valueOf(part); // remove everything around the contract name, because Formats like FR_100010_1 should become 100010
                    }
                    tmpPayment.Contract = String.valueOf(value);
                }


                String productID = inputString.substring(inputString.indexOf(' ') + 4, inputString.indexOf('_'));
                if (paymentProductMap.get(productID) != null) {
                    tmpPayment.Product = (String) paymentProductMap.get(productID);
                } else {
                    tmpPayment.Product = productID;
                }

            } catch (Exception e) {
            }
        }
        return tmpPayment;
    }

    public class Payment {
        @AuraEnabled public String ConcKey { get; set; }
        @AuraEnabled public String Kunnr { get; set; }
        @AuraEnabled public String Cp { get; set; }
        @AuraEnabled public String Fkdat { get; set; }
        @AuraEnabled public String Bukrs { get; set; }
        @AuraEnabled public String Blart { get; set; }
        @AuraEnabled public String VbelnVf { get; set; }
        @AuraEnabled public String Bldat { get; set; }
        @AuraEnabled public String Wrbtr { get; set; }
        @AuraEnabled public String Waers { get; set; }
        @AuraEnabled public String Augdt { get; set; }
        @AuraEnabled public String Augbl { get; set; }
        @AuraEnabled public String Zfbdt { get; set; }
        @AuraEnabled public String Bvtyp { get; set; }
        @AuraEnabled public String Sgtxt { get; set; }
        @AuraEnabled public String ReBillingid { get; set; }
        @AuraEnabled public String Period { get; set; }
        @AuraEnabled public String Product { get; set; }
        @AuraEnabled public String Contract { get; set; }
        @AuraEnabled public String downloadURL { get; set; }
        @AuraEnabled public PaymentMetadata metadata { get; set; }
    }
    public class PaymentMetadata {
        @AuraEnabled public string id { get; set; }
        @AuraEnabled public string uri { get; set; }
        @AuraEnabled public string type { get; set; }
    }

    public class PaymentResponseWrapper {
        @AuraEnabled public List<Payment> payments { get; set; }
        @AuraEnabled public Set<Account> accounts { get; set; }
        @AuraEnabled public Account selectedAccount { get; set; }
        @AuraEnabled public List<String> excelFileLabels { get; set; }

        public PaymentResponseWrapper() {
            accounts = new Set<Account>();
            excelFileLabels = new List<String>();
        }
    }
}