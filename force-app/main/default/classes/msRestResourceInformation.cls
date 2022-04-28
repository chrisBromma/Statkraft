/**
 * Created by frank on 04.10.2018.
 */
@RestResource(urlMapping='/information/*')//endpoint definition > https://statkraft-crm--frankdev.lightning.force.com/services/apexrest/information/
global class msRestResourceInformation {

    @HttpGet
    global static void information() {
        RestRequest req = RestContext.request; //the RestRequest for the Apex REST method
        RestResponse res = RestContext.response;
        responseWrapper resWrapper = new responseWrapper();
        String endpoint = req.requestURI;
        String requestItem = endpoint.substringAfter('/information/');
        String responseJSON = ''; //responseWrapper object for API response
        List<String> possibleItems = new List<String>{
                'request items', 'language keys', 'message types'
        };


        if (requestItem != null & requestItem != '') {

            resWrapper.request_item = requestItem ;

            switch on requestItem {
                when 'request_items' {
                    resWrapper.information_response = new List<String>{
                            'request_items', 'message_types', 'language_keys'
                    };
                    res.statusCode = 200;
                    res.responseBody = Blob.ValueOf(JSON.serialize(resWrapper));
                }
                when 'message_types' {
                    // new logic if object for mail setting is implemented
                    Schema.DescribeFieldResult F = msUserNotificationSetting__c.msNotificationType__c.getDescribe();
                    Schema.SObjectField T = F.getSobjectField();
                    List<String>possibleMessageTypes = new List<String>();
                    for (PicklistEntry tmpEntry : T.getDescribe().getPicklistValues()) {
                        possibleMessageTypes.add(tmpEntry.getValue());
                    }

                    resWrapper.information_response = possibleMessageTypes;
                    res.statusCode = 200;
                    res.responseBody = Blob.ValueOf(JSON.serialize(resWrapper));
                }
                when 'language_keys' {
                    resWrapper.information_response = new List<String>{
                            'Albanian: sq', 'Arabic: ar', 'Armenian: hy', 'Basque: eu', 'Bosnian: bs', 'Bulgarian: bg', 'Chinese (Simplified): zh_CN', 'Chinese (Traditional): zh_TW', 'Croatian: hr', 'Czech: cs', 'Danish: da', 'Dutch: nl_NL', 'English (Australia): en_AU', 'English (Canada): en_CA', 'English (India): en_IN', 'English (Malaysia): en_MY', 'English (Philippines): en_PH', 'English (UK): en_GB', 'English: en_US', 'Estonian: et', 'Finnish: fi', 'French (Canada): fr_CA', 'French: fr', 'Georgian: ka', 'German: de', 'Greek: el', 'Hebrew: iw', 'Hindi: hi', 'Hungarian: hu', 'Icelandic: is', 'Indonesian: in', 'Irish: ga', 'Italian: it', 'Japanese: ja', 'Korean: ko', 'Latvian: lv', 'Lithuanian: lt', 'Luxembourgish: lb', 'Macedonian: mk', 'Malay: ms', 'Maltese: mt', 'Moldovan: ro_MD', 'Montenegrin: sh_ME', 'Norwegian: no', 'Polish: pl', 'Portuguese (Brazil): pt_BR', 'Portuguese (European): pt_PT', 'Romanian: ro', 'Romansh: rm', 'Russian: ru', 'Serbian (Cyrillic): sr', 'Serbian (Latin): sh', 'Slovak: sk', 'Slovenian: sl', 'Spanish (Mexico): es_MX', 'Spanish: es', 'Swedish: sv', 'Tagalog: tl', 'Thai: th', 'Turkish: tr', 'Ukrainian: uk', 'Urdu: ur', 'Vietnamese: vi', 'Welsh: cy'
                    };
                    res.statusCode = 200;
                    res.responseBody = Blob.ValueOf(JSON.serialize(resWrapper));
                }
                when else {
                    res.statusCode = 400;
                    res.responseBody = Blob.ValueOf('The request item don\'t exist. To check possible items add \'/request_items\' to the endpoint.');
                }
            }

        } else {
            res.statusCode = 400;
            res.responseBody = Blob.ValueOf('The request item is missing. To check possible items add \'/request_items\' to the endpoint.');
        }
        return; //return the JSON response
    }

    global class responseWrapper {

        global String request_item { get; set; }
        global List<String> information_response { get; set; }

        //constructor
        global responseWrapper() {
            //default all values
            this.request_item = '';
            this.information_response = new List<String>();
        }
    }
}