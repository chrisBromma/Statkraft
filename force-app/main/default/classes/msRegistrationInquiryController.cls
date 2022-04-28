/**
 * Created by frank on 14.08.2018.
 */

public with sharing class msRegistrationInquiryController {

    @AuraEnabled
    public static List<String> getCountries(){
        List<String> countryList = new List<String>();
        List<CountryContactDetails__c> contactDetails = [SELECT Country__c, Phone__c FROM CountryContactDetails__c];
        for (CountryContactDetails__c detail : contactDetails){
                countryList.add(detail.Country__c);
                }
                return countryList;
    }

    @AuraEnabled
    public static String getServiceNumber(String country){
        CountryContactDetails__c contactDetails = [SELECT Country__c, Phone__c FROM CountryContactDetails__c WHERE Country__c = :country LIMIT 1];
        return contactDetails.Phone__c;
    }

    @AuraEnabled
    public static Boolean createCase(String salutation, String firstName, String lastName, String email, String company, String phone, String mobilePhone, String function, String country) {

        System.debug('Trying to submit Registration for ' + firstName);
        RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Portal_contact' AND SobjectType = 'Case'];
        String descrip = 'There is a new registration inquiry for the customer portal. You can find the information of the user below.\n' +
                '\nSalutation: ' + salutation +
                '\nFirst name: ' + firstName +
                '\nLast name: ' + lastName +
                '\nEmail: ' + email +
                '\nCompany: ' + company +
                '\nPhone:' + phone +
                '\nMobile Phone:' + mobilePhone +
                '\nFunction: ' + function +
                '\nCountry: ' + country ;

        AssignmentRule rule = new AssignmentRule();
        rule = [SELECT Id FROM AssignmentRule WHERE Name  ='Assigned to queue by record type'];
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.EmailHeader.triggerUserEmail = true;
        dmlOpts.assignmentRuleHeader.assignmentRuleId = rule.id;

        Case newCase = new Case(Subject='Portal Registration Inquiry', RecordTypeId = recType.Id, Description = descrip, Origin='Web');
        newCase.setOptions(dmlOpts);
        try {
            insert newCase;
            return true;
        }
        catch (DmlException e){
            System.debug('Error: '+ e);
        }
        return false;
    }
}