/**
 * Created by Fabian on 06.03.2019.
 */
@IsTest
public with sharing class msSendSMSTestClass {

    static testMethod void test(){

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('sendSMSMock');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        // Call method to test

        String to = '+491758710666';
        String text = 'message from testclass';
        String sender = 'Statkraft';

        msSendSMSController.sendSms(to,text,sender);
        msSendSMSController.sendSms(to,text,sender,msUtility.getMetadata());
        
    }

}