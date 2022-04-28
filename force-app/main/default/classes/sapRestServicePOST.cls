/**
 * Created by Steffen Naundorf on 25.11.2021.
 */

@RestResource(urlMapping='/sap_post/*')//endpoint definition > https://statkraft-crm--sap.lightning.force.com/services/apexrest/sap/post/
global class sapRestServicePOST {
    global static fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();

    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request; //the RestRequest for the Apex REST method
        RestResponse res = RestContext.response;
        String jsonString = req.requestBody.toString();
        //{"requestid":"5235353EE2F91EECA2B4F389773F1282","businesspartner":"0000501427","status":"A","salesforceid":"5001w00000986SGAAY"}

        ResponseWrapper responseWrapper = new responseWrapper();
        responseWrapper.answer = 'Hello SAP, this was a successfull POST call';
        responseWrapper.requestBody = jsonString;

        res.statusCode = 200;
        res.responseBody = Blob.ValueOf(JSON.serialize(responseWrapper));

        Logger.info(jsonString);
        Logger.saveLog('SAP Transfer - Ingoing');

        return; //return the JSON response
    }

    global static Integer handleRequest() {
        String jsonString = '{"requestid":"5235353EE2F91EECA2B4F389773F1282","businesspartner":"0000501427","status":"A","salesforceid":"5001w00000986SGAAY"}';
        try {
            RequestForm requestForm = (RequestForm) JSON.deserializeStrict(jsonString, RequestForm.class);
            Case transferCase = [SELECT Id, AccountId, Status, Progress__c, SAP_Transfer_Data__c FROM Case WHERE Id = :requestForm.salesforceid];
            Account account = [SELECT Id, SAP_Customer__c FROM Account WHERE Id = :transferCase.AccountId];
            sapTriggerHelper sapTriggerHelper = new sapTriggerHelper(uow);
            List<String>messages = new List<String>();

            switch on requestForm.status {
                when 'C' { //Request created
                    messages.add('Request was created in SAP');
                    messages.add('Request ID: ' + requestForm.requestid);

                    transferCase.SAP_Transfer_Id__c = requestForm.requestid;
                    transferCase.Status = 'In SAP Approval';
                    transferCase.Progress__c = 'waiting for Approval';
                }
                when 'A' { //Request approved
                    messages.add('Request was approved');

                    if (account.SAP_Customer__c == null) {
                        messages.add('New Businesspartner ID: ' + requestForm.businesspartner);
                        account.SAP_Customer__c = requestForm.businesspartner;
                        uow.registerDirty(account);
                    }

                    transferCase.Status = 'Closed (Passed)';
                    transferCase.Progress__c = null;
                }
                when 'D' { //Request declined
                    messages.add('Request was declined!');

                    transferCase.Status = 'In Salesforce Approval';
                    transferCase.Progress__c = 'Rejected in SAP';
                }
                when 'F' { //Request failed
                    messages.add('Submission failed!');

                    transferCase.Status = 'In Salesforce Approval';
                    transferCase.Progress__c = 'Submission failed';
                }
            }

            uow.registerDirty(transferCase);

            if (!messages.isEmpty()) {
                sapTriggerHelper.addMessage(messages, transferCase);
            }

            uow.commitWork();
        } catch (Exception e) {
            return 500;
        }
        return 200;
    }
    global class ResponseWrapper {
        global String answer { get; set; }
        global String requestBody { get; set; }

        //constructor
        global responseWrapper() {
            answer = '';
            requestBody = '';
        }
    }
    global class RequestForm {
        global String requestid { get; set; }
        global String businesspartner { get; set; }
        global String status { get; set; }
        global String salesforceid { get; set; }
    }
}