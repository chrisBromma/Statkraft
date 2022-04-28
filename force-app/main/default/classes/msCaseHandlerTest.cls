/****************************************************************************************************
* Class msCaseHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-07-23
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-07-23       	Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msCaseHandlerTest {
    private static final String PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;
    private static final String DE_ACC_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Account', 'Account').Id;

    @IsTest
    private static void contractUpdateViaCaseStatusTests() {

        Account deAccount = new Account();
        deAccount.Name = 'Test Account DE';
        deAccount.RecordTypeId = DE_ACC_RECORD_TYPE;
        deAccount.BillingCountry = 'Germany';
        deAccount.Customer_Type__c = 'not yet identified';
        deAccount.Customer_Segment_industry__c = 'Large industrials';
        insert deAccount;


        Contract__c newContract = new Contract__c();
        newContract.RecordTypeId = PPA_CONTRACT_RECORD_TYPE;
        newContract.Start_Date__c = Date.today();
        newContract.End_Date__c = Date.today().addDays(1);
        newContract.Status__c = 'Active';
        newContract.Contract_Holder__c = deAccount.Id;
        newContract.Country__c = 'Germany';
        newContract.RED_Contract_ID__c = 'GermanTestContract1';
        newContract.Approved__c = true;
        newContract.Meter_Billing_Type__c = 'Sub-Meter Yearly';
        newContract.Workflow_Type__c = 'New';
        newContract.Name = 'DETestContract1';
        insert newContract;

        List<Case> newCases = new List<Case>();

        newCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..CIS Handling..',
                Status = 'New'
        ));
        newCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..Contract Document Handling..',
                Status = 'New'
        ));
        newCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..Security Handling..',
                Status = 'New'
        ));
        newCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..Remote Control Handling..',
                Status = 'New'
        ));
        newCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..SAP Setup..',
                Status = 'New'
        ));
        newCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..Portal user registration..',
                Status = 'New'
        ));
        List<Case> meterRegCases = new List<Case>();
        meterRegCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..Meter Registration..',
                Status = 'New'
        ));
        meterRegCases.add(new Case(
                Contract__c = newContract.Id,
                Reason = '..Meter Registration..',
                Status = 'New'
        ));

        Test.startTest();
        insert newCases;

        for (Case newCase : newCases) {
            newCase.Status = 'In Progress';
        }
        update newCases;

        insert meterRegCases;

        meterRegCases[0].Status = 'New';
        meterRegCases[1].Status = 'Closed (Passed)';
        update meterRegCases;

        meterRegCases[0].Status = 'In Progress';
        meterRegCases[1].Status = 'Closed (Passed)';
        update meterRegCases;

        meterRegCases[0].Status = 'Closed (Passed)';
        meterRegCases[1].Status = 'Closed (Passed)';
        update meterRegCases;

        Test.stopTest();

        newContract = [
                SELECT Meter_Registration_Requested__c, CIS_File_Status__c,
                        Security_Issuance_Status__c, Remote_Control_Status__c, SAP_Masterdata_Status__c,
                        Customer_Portal_User_Setup_Status__c
                FROM Contract__c
                WHERE Id = :newContract.Id
                LIMIT 1
        ];

        System.assert(newContract.Meter_Registration_Requested__c != null);
        System.assert(newContract.CIS_File_Status__c != null);
        System.assert(newContract.Security_Issuance_Status__c != null);
        System.assert(newContract.Remote_Control_Status__c != null);
        System.assert(newContract.SAP_Masterdata_Status__c != null);
        System.assert(newContract.Customer_Portal_User_Setup_Status__c != null);
    }
}