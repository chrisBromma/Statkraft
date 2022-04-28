/****************************************************************************************************
* Class msContactFormController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   10.08.2018
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Steffen Naundorf (mindsquare GmbH)        10.08.2018      	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      20.02.2020              Commented out legacy code
*****************************************************************************************************/

public without sharing class msContactFormController {

    @AuraEnabled
    public static List<MarketContactDetails__mdt> getContactDetails() {
        Set<String> markets = new Set<String>();
        Id profileId = userinfo.getProfileId();
	    
        if(profileId !='00e1v000000ZV0WAAW'){
        for (String marketItem : msUtility.getUserMarkets()) {
            String market = marketItem.remove('_Contract');
            markets.add(market);
        }
    }
        List<MarketContactDetails__mdt> contactDetails = null;
        if (markets.isEmpty()) {
            contactDetails = [
                    SELECT Label,ISO__c,Country__c,Company__c,Address__c,City__c,Email__c,Phone__c
                    FROM MarketContactDetails__mdt ORDER BY Label ASC
            ];
        } else {
            contactDetails = [
                    SELECT Label,ISO__c,Country__c,Company__c,Address__c,City__c,Email__c,Phone__c
                    FROM MarketContactDetails__mdt
                    WHERE DeveloperName IN :markets
            ];
        }
        return contactDetails;
    }

     
    /*
    @AuraEnabled
    public static List<SObject> getMeters(String selectedContract) {
        List<SObject> meters = [SELECT Meter__r.Name, Meter__c FROM MeterRegistration__c WHERE Contract__c = :selectedContract];
        return meters;
    }
    @AuraEnabled
    public static Map<String, ContractContactWrapper> getContracts() {
        List<Contract__c> contracts = new List<Contract__c>();
        Map<String, ContractContactWrapper> result = new Map<String, msContactFormController.ContractContactWrapper>();

        Id userId = UserInfo.getUserId();
        Id contactId = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
        if (contactId != null) {
            List<Contract_Role__c> contractRoles = [SELECT Contract__c FROM Contract_Role__c WHERE Contact__c = :contactId AND Start_Date__c <= :Date.today()
            AND End_Date__c >= :Date.today()];
            List<Id> contractRoleIds = new List<Id>();
            for (Contract_Role__c tmp : contractRoles) {
                contractRoleIds.add(tmp.Contract__c);
            }
            contracts = [SELECT Id, Name, Country__c FROM Contract__c WHERE Id IN :contractRoleIds];
            List<String> countries = new List<String>();
            for (Contract__c tmp : contracts) {
                countries.add(tmp.Country__c);
                ContractContactWrapper newWrapper = result.get(tmp.Country__c);
                if (newWrapper == null) {
                    newWrapper = new ContractContactWrapper();
                    newWrapper.contracts = new List<Contract__c>();
                }
                newWrapper.contracts.add(tmp);
                result.put(tmp.Country__c, newWrapper);
            }
            List<MarketContactDetails__mdt> contactDetails = [SELECT    Label,ISO__c,Country__c,Company__c,
                                                                        Address__c,City__c,Email__c,Phone__c
                                                                        FROM MarketContactDetails__mdt
                                                                        WHERE Country__c IN :countries];

            for (MarketContactDetails__mdt tmp : contactDetails) {
                ContractContactWrapper newWrapper = result.get(tmp.Country__c);
                newWrapper.contactDetails = tmp;
                result.put(tmp.Country__c, newWrapper);
            }
        }
        return result;
    }
    @AuraEnabled
    public static void createCase(Id contractId, String subject, String message, String meter, String guestUserEmail, String guestUserName, String guestUserCountry) {
        Id userId = UserInfo.getUserId();
        Boolean guestUser = false;
        Case newCase = new Case();
        if (meter == null && contractId == null) {
            guestUser = true;
        }
        newCase.Meter__c = meter;
        newCase.Contract__c = contractId;
        newCase.Subject = subject;
        newCase.Description = message;
        newCase.SuppliedEmail = guestUserEmail;
        newCase.SuppliedName = guestUserName;
        newCase.Origin = 'Web';
        newCase.CreatedById = userId;

        Id recordTypeId = [SELECT Id, Name FROM RecordType WHERE DeveloperName = 'Portal_contact' LIMIT 1].Id;
        newCase.RecordTypeId = recordTypeId;

        AssignmentRule rule = new AssignmentRule();
        rule = [SELECT Id FROM AssignmentRule WHERE Name = 'Assigned to queue by record type'];
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = rule.Id;
        dmlOpts.emailHeader.triggerUserEmail = true;
        insert newCase;

        sendEmailToCustomer(newCase.Id, guestUser, guestUserEmail, guestUserCountry);
        newCase.setOptions(dmlOpts);
        Database.upsert(newCase);
    }
    public static void sendEmailToCustomer(Id caseId, Boolean guestUser, String guestUserEmail, String guestUserCountry) {
        OrgWideEmailAddress owa  =  [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply-salesforce@statkraft.com'];
        Id userId = UserInfo.getUserId();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(owa.Id);
        EmailTemplate template;
        if (guestUser == true) {
            mail.setToAddresses(new String[]{guestUserEmail});
            String templateName = 'Community_ContactForm_Guest_'+guestUserCountry.toLowerCase();
            template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName];
        } else {
            template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Community_Contact_support_Master' LIMIT 1];
            mail.setTargetObjectId(userId);
        }
        mail.setTemplateId(template.Id);
        mail.setWhatId(caseId);
        mail.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
    @AuraEnabled
    public static Object getCountryContactDetails(String market) {
        Map<String, CountryContactDetails__c> countryContactDetails = CountryContactDetails__c.getAll();
        return countryContactDetails.get(market);
    }

    public class ContractContactWrapper {
        @AuraEnabled public List<Contract__c> contracts { get; set; }
        @AuraEnabled public MarketContactDetails__mdt contactDetails { get; set; }
    }*/
}