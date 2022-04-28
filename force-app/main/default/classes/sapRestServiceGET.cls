/**
 * Created by Steffen Naundorf on 25.11.2021.
 */

@RestResource(urlMapping='/sap/get/*')//endpoint definition > https://statkraft-crm--sap.lightning.force.com/services/apexrest/sap/test/
global class sapRestServiceGET {

    @HttpGet
    global static void handleGet() {
        RestRequest req = RestContext.request; //the RestRequest for the Apex REST method
        RestResponse res = RestContext.response;
        ResponseWrapper responseWrapper = new responseWrapper();
        String endpoint = req.requestURI;
        String requestedRessource = endpoint.substringAfter('/sap/test/');

        responseWrapper.answer = 'Hello SAP, this was a successfull GET call';
        responseWrapper.requestedRessource = requestedRessource;

        res.statusCode = 200;
        res.responseBody = Blob.ValueOf(JSON.serialize(responseWrapper));


        return; //return the JSON response
    }


    global class ResponseWrapper {
        global String answer { get; set; }
        global String requestedRessource { get; set; }

        //constructor
        global responseWrapper() {
            answer = '';
            requestedRessource = '';
        }
    }

}