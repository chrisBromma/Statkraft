/**
 * Created by Steffen Naundorf on 06.07.2021.
 */

global without sharing class GuaranteePremiumUpdate {
    public class FlowInputs {
        @InvocableVariable
        public String premiumId;
    }

    @InvocableMethod
    public static void updateGuarantees(List<FlowInputs> request) {
        SK_Security_Premium__c premium = [
                SELECT ID, On_behalf_of_Entity__c, Issuing_Entity__c,
                        Duration_lower_range__c, Validity_start_date__c, Validity_End_date__c,
                        Duration_upper_range__c, Guarantee_Premium__c
                FROM SK_Security_Premium__c
                WHERE Id = :request[0].premiumId
        ];
        List<SK_Security__c> guarantees = [
                SELECT ID, SK_Duration_in_years__c, SK_Initial_Start_date__c, SK_Amendment_Start_Date__c
                FROM SK_Security__c
                WHERE SK_On_behalf_of_Lookup__c = :premium.On_behalf_of_Entity__c
                AND SK_Issuing_Entity_Lookup__c = :premium.Issuing_Entity__c
                AND SK_Duration_in_years__c > :premium.Duration_lower_range__c
                AND SK_Initial_Start_date__c >= :premium.Validity_start_date__c
                AND SK_Guarantee_Fee_Percent__c = null
                AND (SK_Amendment_Start_Date__c = null OR SK_Amendment_Start_Date__c >= :premium.Validity_start_date__c)
        ];

        List<SK_Security__c> guaranteesToUpdate = new List<SK_Security__c>();
        for (SK_Security__c tempGuarantee : guarantees) {
            if ((premium.Duration_upper_range__c == null
                    || premium.Duration_upper_range__c >= tempGuarantee.SK_Duration_in_years__c)
                    && (premium.Validity_End_date__c == null
                    || premium.Validity_End_date__c >= tempGuarantee.SK_Initial_Start_date__c
                    || premium.Validity_End_date__c >= tempGuarantee.SK_Amendment_Start_Date__c)) {
                tempGuarantee.SK_Guarantee_Fee_Percent__c = premium.Guarantee_Premium__c;
                guaranteesToUpdate.add(tempGuarantee);
            }
        }

        update guaranteesToUpdate;
    }
}