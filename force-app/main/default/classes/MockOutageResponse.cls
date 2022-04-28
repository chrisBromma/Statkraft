@isTest
global class MockOutageResponse implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {

        String url, url1 ;
        String content, content1;
        url = 'https://apigw.statkraft.com/bizapieex/v1/sendtoeex';
        content = '{"MessageType":"NonUsabilityProducerPower","NonUsabilityProducerPower":{"UnitIDGroup":{"UnitIDRecord":{"NonAvailabilityCapacity":"784","NonAvailabilityEnd":"2014-04-08T06:00:00+02:00","NonAvailabilityBegin":"2014-04-07T05:00:00+02:00","Reason":"NA01","Status":"active","EventID":"201805136020000"},"UnitID":"E110502-001"},"CreationDateTime":"2018-05-16T00:00:00.000Z","MessageVersion":"1.9"}}';
        
        
        url1 = 'https://apigw.statkraft.com/bizapieex/v1/ackformessage';
        content1 = '{"ACKRequest":{"MessageType":"NonUsabilityProducerPower","MessageID":2611013}}';
        
      
        
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint() == url){
       
            System.assertEquals('POST', req.getMethod());
            
            //Create a fake response
            
            res.setHeader('Content-Type', 'application/json');
            res.setBody(content);
            res.setStatusCode(200); 

        } else if(req.getEndpoint() == url1){
            System.assertEquals('POST', req.getMethod());
            
            //Create a fake response
            
            res.setHeader('Content-Type', 'application/json');
            res.setBody(content1);
            res.setStatusCode(200); 

        }
        
        return res;    
    }
}