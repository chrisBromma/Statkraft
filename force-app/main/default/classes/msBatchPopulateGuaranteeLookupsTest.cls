/**************************************************************************************************** 
* Class msBatchPopulateGuaranteeLookupsTest 
* 
*   Created By :   Fabian Murk (mindsquare AG) 
*   Create Date :   09.04.2021 
*   Description : 
* 
*   Modification Log: 
*   ------------------------------------------------------------------------------------------------- 
*   * Developer                        Date             Description 
*   * -----------------------------------------------------------------------------------------------                  
*   * Fabian Murk (mindsquare AG)      09.04.2021)         Init version. 
*****************************************************************************************************/
@IsTest
public with sharing class msBatchPopulateGuaranteeLookupsTest {
    @TestSetup
    public static void testSetup(){
        List<Account> accountsToInsert = new List<Account>();
        SObjectField picklistUsingGlobal = SObjectType.SK_Security__c.fields.SK_BeneficiaryList__c.getSobjectField();
        List<PicklistEntry> entries = picklistUsingGlobal.getDescribe().getPicklistValues();
        for (PicklistEntry entry : entries){
            accountsToInsert.add(new Account(Name = entry.getValue()));
        }
        System.debug(accountsToInsert);
        insert accountsToInsert;
    }
    @IsTest
    public static void testBatchPopulateGuaranteeLookups(){
        SK_Security__c guarantee = new SK_Security__c(
                SK_BeneficiaryList__c = 'Statkraft AS',
                SK_Issuing_Entity__c = 'Statkraft AS',
                SK_On_behalf_of__c = 'Statkraft US LLC',
                SK_No_End_Date__c = true,
            	Mandate_approved__c  = true
        );
        insert guarantee;

        Test.startTest();
        Database.executeBatch(new msBatchPopulateGuaranteeLookups());
        Test.stopTest();

        SK_Security__c updatedGuarantee = [
                SELECT SK_Account__r.Name,  SK_Issuing_Entity_Lookup__r.Name, SK_On_behalf_of_Lookup__r.Name
                FROM SK_Security__c WHERE Id = :guarantee.Id
        ];
        System.assertEquals(guarantee.SK_BeneficiaryList__c, updatedGuarantee.SK_Account__r.Name);
        System.assertEquals(guarantee.SK_Issuing_Entity__c, updatedGuarantee.SK_Issuing_Entity_Lookup__r.Name);
        System.assertEquals(guarantee.SK_On_behalf_of__c, updatedGuarantee.SK_On_behalf_of_Lookup__r.Name);
    }

}