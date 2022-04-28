/**
 * Created by u52448 on 28.09.2021.
 */

@IsTest
public without sharing class portalContractDataControllerTest {
    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    static testMethod void testGetContractData() {

        Contract__c testContract = [SELECT Id, Name, Contract_Holder__r.Name FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();
        System.runAs(testUser) {
            portalContractDataController.contractData contractData = portalContractDataController.getContractData(testContract.Id);
            System.assertEquals(contractData.contractHolderDetails.accountName, testContract.Contract_Holder__r.Name);
        }
        System.Test.stopTest();
    }

    static testMethod void testSetMasterDataIsUptoDate() {
        Contract__c testContract = [SELECT Id, Name, Contract_Holder__r.Name, Customer_Portal_Master_Data_Update__c FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();
        System.runAs(testUser) {
            portalContractDataController.setMasterDataIsUptoDate(testContract.Id);
        }
        System.Test.stopTest();

        Contract__c contract = [SELECT Customer_Portal_Master_Data_Update__c FROM Contract__c WHERE Id = :testContract.Id];
        System.assert(contract.Customer_Portal_Master_Data_Update__c);
    }

    static testMethod void testSendCommercialMasterData() {
        Contract__c testContract = [SELECT Id, Name, Contract_Holder__r.Name, Customer_Portal_Master_Data_Update__c FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        portalContractDataController.contractData contractData = new portalContractDataController.contractData();
        portalContractDataController.accountDetails contractHolderDetails = new portalContractDataController.accountDetails();

        contractHolderDetails.accountName = 'Test';
        contractHolderDetails.vatNumber = 'Test';
        contractHolderDetails.companyTaxNumber = 'Test';
        contractHolderDetails.isVatReseller = 'true';
        contractHolderDetails.remitAcerCode = 'Test';

        portalContractDataController.bankDetails bankDetails = new portalContractDataController.bankDetails();
        bankDetails.bankAccountHolder = 'Test';
        bankDetails.bicCode = 'Test';
        bankDetails.IBAN = 'DE89370400440532013000';

        portalContractDataController.Recipient paymentRecipient = new portalContractDataController.Recipient();
        paymentRecipient.mailAddOn = 'Test';
        paymentRecipient.company = 'Test';
        paymentRecipient.country = 'Test';
        paymentRecipient.city = 'Test';
        paymentRecipient.postalCode = 'Test';
        paymentRecipient.street = 'Test';

        portalContractDataController.Recipient mailRecipient = new portalContractDataController.Recipient();
        mailRecipient.mailAddOn = 'Test';
        mailRecipient.company = 'Test';
        mailRecipient.country = 'Test';
        mailRecipient.city = 'Test';
        mailRecipient.postalCode = 'Test';

        contractData.contractHolderDetails = contractHolderDetails;
        contractData.bankDetails = bankDetails;
        contractData.paymentRecipient = paymentRecipient != null ? paymentRecipient : null;
        contractData.mailRecipient = mailRecipient != null ? mailRecipient : null;

        String currentContractData = JSON.serialize(contractData);
        String newContractData = JSON.serialize(contractData);
        String supportingDocuments = '[{"fileName":"testdoc.pdf","base64Content":"JVBERi0xLjcKCjEgMCBvYmogICUgZW50cnkgcG9pbnQKPDwKICAvVHlwZSAvQ2F0YWxvZwogIC9QYWdlcyAyIDAgUgo+PgplbmRvYmoKCjIgMCBvYmoKPDwKICAvVHlwZSAvUGFnZXMKICAvTWVkaWFCb3ggWyAwIDAgMjAwIDIwMCBdCiAgL0NvdW50IDEKICAvS2lkcyBbIDMgMCBSIF0KPj4KZW5kb2JqCgozIDAgb2JqCjw8CiAgL1R5cGUgL1BhZ2UKICAvUGFyZW50IDIgMCBSCiAgL1Jlc291cmNlcyA8PAogICAgL0ZvbnQgPDwKICAgICAgL0YxIDQgMCBSIAogICAgPj4KICA+PgogIC9Db250ZW50cyA1IDAgUgo+PgplbmRvYmoKCjQgMCBvYmoKPDwKICAvVHlwZSAvRm9udAogIC9TdWJ0eXBlIC9UeXBlMQogIC9CYXNlRm9udCAvVGltZXMtUm9tYW4KPj4KZW5kb2JqCgo1IDAgb2JqICAlIHBhZ2UgY29udGVudAo8PAogIC9MZW5ndGggNDQKPj4Kc3RyZWFtCkJUCjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8sIHdvcmxkISkgVGoKRVQKZW5kc3RyZWFtCmVuZG9iagoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4gCjAwMDAwMDAwNzkgMDAwMDAgbiAKMDAwMDAwMDE3MyAwMDAwMCBuIAowMDAwMDAwMzAxIDAwMDAwIG4gCjAwMDAwMDAzODAgMDAwMDAgbiAKdHJhaWxlcgo8PAogIC9TaXplIDYKICAvUm9vdCAxIDAgUgo+PgpzdGFydHhyZWYKNDkyCiUlRU9G"}]"';

        System.runAs(testUser) {
            System.Test.startTest();
            portalContractDataController.sendCommercialMasterData(testContract.Id, currentContractData, newContractData, '');
            System.Test.stopTest();
        }

        Case createdCase = [Select Subject, Description, Reason, Master_Data_Change_Request__c
                            FROM Case WHERE Reason=:msUtility.CASE_REASON_MASTER_DATA_CHANGE LIMIT 1];
        System.assert(createdCase.Master_Data_Change_Request__c.length() > 0);
    }
}