/****************************************************************************************************
* Class dynamicEmailAlertTemplateController
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-02-10
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-02-10       	Init version.
*****************************************************************************************************/

global with sharing class dynamicEmailAlertTemplateController {
    private List<String> fieldNamesAccount = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
    private List<String> fieldNamesCase = new List<String>(Case.SObjectType.getDescribe().fields.getMap().keySet());
    private List<String> fieldNamesContact = new List<String>(Contact.SObjectType.getDescribe().fields.getMap().keySet());
    private List<String> fieldNamesContract = new List<String>(Contract__c.SObjectType.getDescribe().fields.getMap().keySet());
    private List<String> fieldNamesContractRole = new List<String>(Contract_Role__c.SObjectType.getDescribe().fields.getMap().keySet());

    private static Set<String> SUPPORTED_MERGE_HEADS = new Set<String>{
            '{Contract.', '{ContractRole.'
    };
    private static Set<String> SUPPORTED_SOBJECT_TYPES = new Set<String>{
            'Case', 'Contract__c'
    };

    global Id recipientId { get; set; }
    global Id caseId { get; set; }
    global Id contractId { get; set; }
    global String contractRoleType { get; set; }
    global String sObjectName { get; set; }
    global Boolean isHTML { get; set; }
    global String templateName { get; set; }
    global dynamicEmailAlertTemplateController() {
    }

    global Case caseRecord {
        get {
            if (caseRecord == null) {
                List<Case> cases = Database.query(
                        'SELECT ' +
                                String.join(fieldNamesCase, ',') +
                                ' FROM Case ' +
                                'WHERE Id =: caseId ' +
                                'LIMIT 1'
                );
                if (cases.size() > 0) {
                    SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, cases);
                    caseRecord = (Case) securityDecision.getRecords()[0];
                }
            }
            return caseRecord;
        }
        set;
    }

    global List<Contract_Role__c> contractRoles {
        get {
            if (contractRoleType != null && contractRoles == null) {
                for (String contactFieldName : fieldNamesContact) {
                    fieldNamesContractRole.add(
                            'Contact__r.' + contactFieldName
                    );
                }
                List<Contract_Role__c> roles = Database.query(
                        'SELECT ' +
                                String.join(fieldNamesContractRole, ',') +
                                ' FROM Contract_Role__c ' +
                                'WHERE Contract__c =: contractId ' +
                                'AND Role__c INCLUDES (:contractRoleType) '
                );
                if (roles.size() > 0) {
                    SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, roles);
                    contractRoles = (List<Contract_Role__c>) securityDecision.getRecords();
                }
            }
            return contractRoles;
        }
        set;
    }

    global Contract__c contract {

        get {
            if (contractId == null && caseId == null) {
                return null;
            } else {
                contractId = caseRecord.Contract__c;
            }
            if (contract == null) {

                for (String accountFieldName : fieldNamesAccount) {
                    fieldNamesContract.add(
                            'Contract_Holder__r.' + accountFieldName
                    );
                    fieldNamesContract.add(
                            'Contract_Holder__r.Parent.' + accountFieldName
                    );
                    fieldNamesContract.add(
                            'Contract_Holder__r.Negotiating_Party__r.' + accountFieldName
                    );
                }

                List<Contract__c> contracts = Database.query(
                        'SELECT ' +
                                String.join(fieldNamesContract, ',') +
                                ' FROM Contract__c ' +
                                'WHERE Id =: contractId ' +
                                'LIMIT 1'
                );
                if (contracts.size() > 0) {
                    SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, contracts);
                    contract = (Contract__c) securityDecision.getRecords()[0];
                }
            }
            return contract;
        }
        private set;
    }

    private Messaging.SingleEmailMessage renderedEmail {
        get {
            if (renderedEmail == null) {
                Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1].Id;
                renderedEmail = Messaging.renderStoredEmailTemplate(templateId, recipientId, null);
            }
            return renderedEmail;
        }
        set;
    }

    global String getMergedEmailHtmlBody() {
        checkForSupport();
        String body = renderedEmail.getHtmlBody();
        body = merger(body);
        return body;
    }

    global String getMergedEmailPlainTextBody() {
        checkForSupport();
        String body = renderedEmail.getPlainTextBody();
        body = merger(body);
        return body;
    }

    private String merger(String body) {
        for (String mergeHead : SUPPORTED_MERGE_HEADS) {
            List<SObject> sourceRecordsList = null;
            switch on mergeHead {
                when '{Contract.' {
                    sourceRecordsList = new List<Contract__c>{
                            contract
                    };
                }
                when '{ContractRole.' {
                    sourceRecordsList = contractRoles;
                }
                when else {
                    continue;
                }
            }

            while (body.contains(mergeHead)) {
                Boolean error = false;
                String queryResult = '';
                Integer indexStartOfMergeEntry = body.indexOf(mergeHead);
                Integer indexPastEndOfMergeEntry = body.indexOf('}', indexStartOfMergeEntry) + 1;
                String leftString = body.left(indexStartOfMergeEntry);
                String rightString = body.right(body.length() - indexPastEndOfMergeEntry);
                String mergeEntry = body.substring(indexStartOfMergeEntry, indexPastEndOfMergeEntry);
                String fullQueryResult = '';
                if (sourceRecordsList == null || sourceRecordsList.isEmpty()) {
                    fullQueryResult = 'N/A';
                } else {
                    for (SObject sourceRecord : sourceRecordsList) {
                        String fieldName = mergeEntry.remove(mergeHead).remove('}');
                        SObject relatedRecord = sourceRecord;
                        if (relatedRecord == null || fieldName == '') {
                            error = true;
                            queryResult = 'N/A';
                        }
                        while (fieldName.contains('.') && !error) {
                            Integer indexOfRelationPeriod = fieldName.indexOf('.');
                            if (indexOfRelationPeriod > 0) {
                                try {
                                    relatedRecord = relatedRecord.getSObject(fieldName.left(indexOfRelationPeriod));
                                    fieldName = fieldName.right(fieldName.length() - indexOfRelationPeriod - 1);
                                } catch (Exception e) {
                                    //Error during climbing the Record path
                                    queryResult = 'N/A';
                                    error = true;
                                }
                            } else {
                                //likely a double dot in the field path
                                error = true;
                                queryResult = 'N/A';
                            }
                        }
                        if (!error) {
                            try {
                                DisplayType dType = relatedRecord.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
                                String fieldType = String.valueOf(dType);
                                if (fieldType == 'BOOLEAN') {
                                    queryResult = String.valueOf((Boolean) relatedRecord.get(fieldName));
                                } else {
                                    queryResult = (String) relatedRecord.get(fieldName);
                                }
                            } catch (Exception e) {
                                //Error during accessing the Field
                                queryResult = 'N/A';
                                error = true;
                            }
                        }
                        fullQueryResult += queryResult + ', ';
                    }
                }
                fullQueryResult = fullQueryResult.removeEnd(', ');
                body = leftString + fullQueryResult + rightString;
            }
        }
        return body;
    }
    private void checkForSupport() {
        if (!SUPPORTED_SOBJECT_TYPES.contains(sObjectName)) {
            throw new AuraHandledException('Unsupported SObject Type. Currently only supported: ' + SUPPORTED_SOBJECT_TYPES);
        }
    }
}