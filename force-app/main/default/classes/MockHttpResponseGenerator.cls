/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {

    private msCalloutMock fallback;

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {

        String url3, url4  ;
        String content3, content4;

        url3 = 'https://apigw.statkraft.com/bizapieex/v1/sendtoeex';
        content3 = '{"MessageType":"NonUsabilityProducerPower","NonUsabilityProducerPower":{"UnitIDGroup":{"UnitIDRecord":{"NonAvailabilityCapacity":"784","NonAvailabilityEnd":"2014-04-08T06:00:00+02:00","NonAvailabilityBegin":"2014-04-07T05:00:00+02:00","Reason":"NA01","Status":"active","EventID":"201805136020000"},"UnitID":"E110502-001"},"CreationDateTime":"2018-05-16T00:00:00.000Z","MessageVersion":"1.9"}}';
        
        
        url4 = 'https://apigw.statkraft.com/bizapieex/v1/ackformessage';
        content4 = '{"ACKRequest":{"MessageType":"NonUsabilityProducerPower","MessageID":2611013}}';
        
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint() == url3){
       
            System.assertEquals('POST', req.getMethod());
            
            //Create a fake response
            
            res.setHeader('Content-Type', 'application/json');
            res.setBody(content3);
            res.setStatusCode(200); 

        } else if(req.getEndpoint() == url4){
            System.assertEquals('POST', req.getMethod());
            
            //Create a fake response
            
            res.setHeader('Content-Type', 'application/json');
            res.setBody(content4);
            res.setStatusCode(200); 

        }
        /*else {
            if (fallback == null) {
                fallback = new msCalloutMock();
            }
            System.debug('Unexpected URL: ' + req);
            res = fallback.respond(req);
        }*/
        
        return res;    
    }
}