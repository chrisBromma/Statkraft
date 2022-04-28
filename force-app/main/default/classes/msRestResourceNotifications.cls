/****************************************************************************************************
* Class msRestResourceNotifications
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   04.10.2018
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            04.10.2018      	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      02.05.2019              V2 for New Core Model
*****************************************************************************************************/
@RestResource(UrlMapping='/notification/*')

//endpoint definition > https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/notification
/*
    {
    "Id":"0050D000001ez3zQAA",
    "ObjectType":"User",
    "Subject":"Hello World",
    "Body":"What an awesome test",
    "MessageType":"",
    "Language":"en_US"
    }
 */

global class msRestResourceNotifications {
    @HttpPost
    global static void information() {
        RestRequest req = RestContext.request; //the RestRequest for the Apex REST method
        RestResponse res = RestContext.response;
        responseWrapper responseJSON = new responseWrapper(); //responseWrapper object for API response
        Map<String, Object> body = new Map<String, Object>(); //placeholder for the JSON Body of the request
        String jsonBody = req.requestBody.toString(); //the body of the request

        List<String> requiredValues = new List<String>{
                'Id', 'ObjectType', 'Subject', 'Body', 'MessageType', 'Language'
        };
        List<String> possibleObectTypes = new List<String>{
                'Contract__c', 'Meter__c', 'User', 'Contact'
        };
        Schema.DescribeFieldResult F = msUserNotificationSetting__c.msNotificationType__c.getDescribe();
        Schema.SObjectField T = F.getSobjectField();
        List<String>possibleMessageTypes = new List<String>();
        for (PicklistEntry tmpEntry : T.getDescribe().getPicklistValues()) {
            possibleMessageTypes.add(tmpEntry.getValue());
        }

        // Hacky: Usually you can find our REST-message-types in a picklist: "msNotificationTypes"
        // But as this script does not allow to combine categories and sub-categories,
        // we need to add them manually here:
        possibleMessageTypes.add('live_metering_missing');
        possibleMessageTypes.add('live_metering_missing_reminder');
        possibleMessageTypes.add('live_metering_exceeds_capacity');
        possibleMessageTypes.add('live_metering_exceeds_capacity_reminder');
        possibleMessageTypes.add('live_metering_constant_values');
        possibleMessageTypes.add('live_metering_constant_values_reminder');

        List<String> possibleLanguages = new List<String>{
                'sq', 'ar', 'hy', 'eu', 'bs', 'bg', 'zh_CN', 'zh_TW', 'hr', 'cs', 'da', 'nl_NL', 'en_AU', 'en_CA', 'en_IN',
                'en_MY', 'en_PH', 'en_GB', 'en_US' , 'et', 'fi', 'fr_CA', 'fr', 'ka', 'de', 'el', 'iw', 'hi', 'hu', 'is',
                'in', 'ga', 'it', 'ja', 'ko', 'lv', 'lt', 'lb', 'mk', 'ms', 'mt', 'ro_MD', 'sh_ME', 'no', 'pl', 'pt_BR',
                'pt_PT', 'ro', 'rm', 'ru', 'sr', 'sh', 'sk', 'sl', 'es_MX', 'es', 'sv', 'tl', 'th', 'tr', 'uk', 'ur', 'vi', 'cy'
        };
        if (!String.isBlank(jsonBody)) { //if the request body is NOT white space, empty ('') or null
            //deserializes the JSON string into collections of primitive data types
            body = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            List<String> missingValues = new List<String> ();
            for (String value : requiredValues) {
                if (!body.containsKey(value)) {
                    missingValues.add(value);
                }
            }
            if (missingValues.size() == 0) {
                String objectType = (String) body.get('ObjectType');
                if (possibleObectTypes.contains(objectType)) {
                    String messageType = (String) body.get('MessageType');
                    if (possibleMessageTypes.contains(messageType)) {
                        String subject = (String) body.get('Subject');
                        if (subject.length() > 0) {
                            String bodyString = (String) body.get('Body');
                            if (bodyString.length() > 0) {
                                String languageKey = (String) body.get('Language');
                                if (possibleLanguages.contains(languageKey)) {
                                    String idString = (String) body.get('Id');
                                    /*Boolean idValid = msUtility.verifyId(objectType, idString);
                                    if (idValid) {*/
                                    List<String> recordIds = idString.split(',');
                                    Integer numberOfUser = msNotificationLogic.distributeMessage(objectType, recordIds, messageType, languageKey, subject, bodyString, new Map<Id, List<ContentVersion>>());
                                    if (numberOfUser > 0) {
                                        res.statusCode = 200;
                                        res.responseBody = Blob.valueOf('The notification will be sent to ' + numberOfUser + ' user.');
                                    } else {
                                        res.statusCode = 400;
                                        res.responseBody = Blob.valueOf('No dependent user found for the record id.');
                                    }
                                    /*} else {
                                        res.statusCode = 400;
                                        res.responseBody = Blob.valueOf('No record found with the received id.');
                                    }*/
                                } else {
                                    String languageString = '';
                                    for (String value : possibleLanguages) {
                                        languageString += value + ',';
                                    }
                                    languageString = languageString.removeEnd(',');
                                    res.statusCode = 400;
                                    res.responseBody = Blob.valueOf('The language key is not valid. Please use one of the following keys: ' + languageString + '.');
                                }
                            } else {
                                res.statusCode = 400;
                                res.responseBody = Blob.valueOf('Notification body is empty.');
                            }
                        } else {
                            res.statusCode = 400;
                            res.responseBody = Blob.valueOf('Notification subject is empty.');
                        }
                    } else {
                        String messagesString = '';
                        for (String value : possibleMessageTypes) {
                            messagesString += value + ',';
                        }
                        messagesString = messagesString.removeEnd(',');
                        res.statusCode = 400;
                        res.responseBody = Blob.valueOf('The message type is not defined. Please use one of the following types: ' + messagesString + '.');
                    }
                } else {
                    String objectsString = '';
                    for (String value : possibleObectTypes) {
                        objectsString += value + ',';
                    }
                    objectsString = objectsString.removeEnd(',');
                    res.statusCode = 400;
                    res.responseBody = Blob.valueOf('The object type is not defined. Please use one of the following types: ' + objectsString + '.');
                }
            } else {
                String valuesString = '';
                for (String value : missingValues) {
                    valuesString += value + ',';
                }
                valuesString = valuesString.removeEnd(',');
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('The following attributes are missing: ' + valuesString + '.');
            }

        } else {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Request body is missing.');
        }

        return;
    }

    global class responseWrapper {

        global String status { get; set; }
        global String message { get; set; }

        //constructor
        global responseWrapper() {
            //default all values
            this.status = '';
            this.message = '';
        }
    }
}