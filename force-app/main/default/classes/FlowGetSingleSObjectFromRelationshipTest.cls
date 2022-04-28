@isTest
public with sharing class FlowGetSingleSObjectFromRelationshipTest {
    @testSetup static void setup(){
        msTestDataFactory.createTestPortalContext();
    }

    @isTest static void testRetrievalOfSobjects(){
        MeterRegistration__c mreg = [SELECT Id, Contract__r.Name FROM MeterRegistration__c LIMIT 1];

        List<FlowGetSingleSObjectFromRelationship.Input> inputs = new List<FlowGetSingleSObjectFromRelationship.Input>();
        for (integer i = 0; i <= 200; i++){
            FlowGetSingleSObjectFromRelationship.Input input = new FlowGetSingleSObjectFromRelationship.Input();
            input.record = mreg;
            input.lookupIdField = 'Contract__c';
            inputs.add(input);
        }

        
        FlowGetSingleSObjectFromRelationship.Output[] outputs = FlowGetSingleSObjectFromRelationship.extractSObjects(inputs);

        for (integer i = 0; i <= 200; i++){
            System.assertEquals(mreg.Contract__r, outputs[i].record);
        }
    }
}