/****************************************************************************************************
* Class msCalloutMock
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:
*   Description	:	Central class for http callout mock construction for testclasses
*                   TODO: Needs to be cleared of the legacy mocks over time(same with corresponding test class)
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            19.09.2018              Init version.
*   * Christian Gottlieb (mindsquare GmbH)      27.11.2019              Added Constructor for UKRetail responses
*   * Christian Gottlieb (mindsquare GmbH)      07.02.2020              Now with generic constructor
*****************************************************************************************************/
@IsTest
global class msCalloutMock implements HttpCalloutMock {

    global Map<String,HttpResponse> ENDPOINT_TO_RESPONSE_MAP;

    global msCalloutMock(Map<String,HttpResponse> endpointToResponseMap) {
        HttpResponse tokenSuccess = new HttpResponse();
        tokenSuccess.setHeader('Content-Type', 'application/json');
        tokenSuccess.setStatus('OK');
        tokenSuccess.setStatusCode(200);
        tokenSuccess.setBody(createTokenBody());
        endpointToResponseMap.put(msUtility.getMetadata().Statkraft_Token_Endpoint__c, tokenSuccess);
        ENDPOINT_TO_RESPONSE_MAP = endpointToResponseMap;
    }

    // Implement this interface method
    global HttpResponse respond(HttpRequest request) {

        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        String body = '';
        String endpoint = request.getEndpoint();
        //if this is not being called by legacy test classes
        if(ENDPOINT_TO_RESPONSE_MAP != null && ENDPOINT_TO_RESPONSE_MAP.keySet().size() > 0) {
            for(String endpointItem : ENDPOINT_TO_RESPONSE_MAP.keySet()) {
                if(request.getEndpoint().startsWith(endpointItem)) {
                    response = ENDPOINT_TO_RESPONSE_MAP.get(endpointItem);
                }
            }
        }
        return response;
    }

    global String createTokenBody() {
        String response = '{"token_type": "ABC",' +
                '"access_token": "1234"}';
        return response;
    }

    global class MockResponseBuilder {
        private HttpResponse response;

        global MockResponseBuilder(){
            response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatus('OK');
            response.setStatusCode(200);
        }
        global MockResponseBuilder setBody(String body) {
            response.setBody(body);
            return this;
        }
        global HttpResponse build() {
            return response;
        }
    }
}