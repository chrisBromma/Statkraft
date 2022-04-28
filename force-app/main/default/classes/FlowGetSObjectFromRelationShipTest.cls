@isTest
public with sharing class FlowGetSObjectFromRelationShipTest {
    @testSetup static void setup(){
        msTestDataFactory.createTestPortalContext();
    }

    @isTest static void testRetrievalOfSobjects(){
        List<MeterRegistration__c> mregs = [SELECT Id, Contract__r.Name FROM MeterRegistration__c];

        List<FlowGetSObjectFromRelationShip.Input> inputs = new List<FlowGetSObjectFromRelationShip.Input>();
        FlowGetSObjectFromRelationShip.Input input = new FlowGetSObjectFromRelationShip.Input();
        input.records = mregs;
        input.lookupIdField = 'Contract__c';
        inputs.add(input);

        FlowGetSObjectFromRelationShip.Output[] outputs = FlowGetSObjectFromRelationShip.extractSObjects(inputs);
        
        Set<Contract__c> contractsFromMreg = new Set<Contract__c>();
        for(MeterRegistration__c mreg : mregs){
            contractsFromMreg.add(mreg.Contract__r);
        }
        List<Contract__c> contractList = new List<Contract__c>(contractsFromMreg);
        for(integer i = 0; i < contractList.size(); i++){
            System.assertEquals(contractList[i], outputs[0].records[i]);
        }

    }
}