/****************************************************************************************************
* Class msSubmeterUtility
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-12-12
*   Description	:	This class contains the method that are in relation to enabling, disabling and notifying
*                   about Submeter Editing
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-12-12       	Init version.
*****************************************************************************************************/

public with sharing class msSubmeterUtility {

    private static Set<String> ANNUAL_MODES = new Set<String>{'annual_submeter_enabled', 'annual_submeter_reminder'};
    private static Set<String> MONTHLY_MODES = new Set<String>{'monthly_submeter_enabled', 'monthly_submeter_reminder'};

    public static final Id FIXED_ENERGY_PRICING_COMPONENT_REC_TYPE_ID =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Fixed_Energy_Price').getRecordTypeId();
    public static final Id FLOATING_ENERGY_PRICING_COMPONENT_REC_TYPE_ID =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Floating_Energy_Price').getRecordTypeId();

    /**
     *  @description Enables or disables annual/monthly Submeter Editing for the entire Portal
     */
    public static void switchSubmeterEditing(String mode, Boolean enable) {
        String name = translateToPortalSettingsRecordName(mode);
        List<PortalSettings__c> settings = [
                SELECT Id, Name, Checkbox__c
                FROM PortalSettings__c
                WHERE Name = :name
        ];
        if (settings.size() > 0) {
            for (PortalSettings__c settingItem : settings) {
                settingItem.Checkbox__c = enable;
            }
            update settings;
        }
    }

    /**
     * @description Issues the Notifications based on the relevant Submeter Event
     */
    public static void issueNotifications(String mode) {
        Set<String> countries = getAffectedCountries(mode);
        List<Id> meterIds = new List<Id> (getAffectedMeters(mode, countries));
        msNotificationLogic.distributeMessage('Meter__c', meterIds, mode, null, null, null, null);
    }


    /**
     *  @description Retrieves the meters in this for these market that are related to Submeter Contracts
     */
    public static Set<Id> getAffectedMeters(String mode, Set<String> countries) {
        Date today = Date.today();
        Date startThisYear = Date.newInstance(today.year(), 1, 1);
        Date lastYearStart = Date.newInstance(today.addYears(-1).year(), 1, 1);
        Date lastYearEnd = Date.newInstance(today.addYears(-1).year(), 12, 31);
        Date lastMonth = today.addMonths(-1);
        Set<Id> affectedMeterIds = new Set<Id>();

        if (mode == 'annual_submeter_enabled' || mode == 'annual_submeter_reminder') {
            mode = 'Sub-Meter Yearly';
        } else if (mode == 'monthly_submeter_enabled' || mode == 'monthly_submeter_reminder') {
            mode = 'Sub-Meter Monthly';
        }
        Integer enableXMonths = -1;
        if(mode == 'Sub-Meter Monthly') {
            List<PortalSettings__c> portalSettings = [SELECT Id, Integer__c FROM PortalSettings__c WHERE Name = 'Submeter - Edit last x months'];
            if (portalSettings.size() > 0 && portalSettings[0].Integer__c != null) {
                enableXMonths = -1 * Integer.valueOf(portalSettings[0].Integer__c);
            }
        }

        List<MeterRegistration__c> meterRegistrations = [
                SELECT Meter__c, Contract__r.Name, Contract__r.Meter_Billing_Type__c, Contract__c,
                        Meter__r.Parent_Meter__c, Meter__r.Name,
                        Contract__r.Global_Portal_Market__c, Contract__r.Start_Date__c, Contract__r.KeepPortalAccessUntil__c,
                        Contract__r.End_Date__c, Valid_from__c, Valid_to__c
                FROM MeterRegistration__c
                WHERE Valid_from__c <= :today
                AND ((
                        Contract__r.Status__c = 'Active'
                        AND (
                                Valid_to__c >= :today
                                OR Valid_to__c = NULL
                        ))
                OR (
                        Contract__r.Status__c = 'Expired'
                        AND
                        Contract__r.KeepPortalAccessUntil__c >= :today
                ))
                AND (Contract__r.Global_Portal_Market__c IN :countries)
                ORDER BY Contract__r.Start_Date__c DESC
        ];

        Set<Id> contractIds = new Set<Id>();
        for(MeterRegistration__c regItem : meterRegistrations) {
            contractIds.add(regItem.Contract__c);
        }

        Map<Id, Contract__c> relevantContractsMap = getSubMeterContracts(contractIds);

        for (MeterRegistration__c tempRegistration : meterRegistrations) {
            if (mode == 'Sub-Meter Monthly') {
                if (lastMonth >= tempRegistration.Valid_from__c && (lastMonth <= tempRegistration.Valid_to__c|| tempRegistration.Valid_to__c == null) &&
                        lastMonth >= tempRegistration.Contract__r.Start_Date__c &&
                        (tempRegistration.Contract__r.KeepPortalAccessUntil__c == null || tempRegistration.Contract__r.KeepPortalAccessUntil__c >= today)) {
                    for(Pricing_Component__c pcItem : relevantContractsMap.get(tempRegistration.Contract__c).Pricing_Components__r) {
                        if(isMeterBillingTypePricingComponent(pcItem)
                                && pcItem.Start_Date__c < today.toStartOfMonth()
                                && pcItem.End_Date__c >= today.toStartOfMonth().addMonths(enableXMonths)
                                && pcItem.Meter_Billing_Type__c == 'Sub-Meter Monthly') {
                            affectedMeterIds.add(tempRegistration.Meter__c);
                        }
                    }
                }
            } else if (mode == 'Sub-Meter Yearly') {
                if (tempRegistration.Contract__r.Start_Date__c < lastYearEnd) {
                    for(Pricing_Component__c pcItem : relevantContractsMap.get(tempRegistration.Contract__c).Pricing_Components__r) {
                        if(isMeterBillingTypePricingComponent(pcItem)
                                && pcItem.Start_Date__c < startThisYear
                                && pcItem.End_Date__c >= lastYearStart
                                && (pcItem.Meter_Billing_Type__c == 'Sub-Meter Monthly'
                                || pcItem.Meter_Billing_Type__c == 'Sub-Meter Yearly')) {

                            affectedMeterIds.add(tempRegistration.Meter__c);
                        }
                    }
                }
            }
        }
        return affectedMeterIds;
    }

    /**
     * @description retrieves the markets that are enabled for submeter editing, for annual and/or monthly editing resp.
     */
    private static Set<String> getAffectedCountries(String mode) {

        List<msPortalMarketFeature__mdt> featureSettings = [
                SELECT Id, DeveloperName, submeterEditYearly__c, submeterView__c
                FROM msPortalMarketFeature__mdt
        ];
        Set<String> countries = new Set<String>();
        for (msPortalMarketFeature__mdt tmp : featureSettings) {
            if (tmp.submeterEditYearly__c && ANNUAL_MODES.contains(mode)) {
                countries.add(tmp.DeveloperName);
            }
            if (tmp.submeterView__c && MONTHLY_MODES.contains(mode)) {
                countries.add(tmp.DeveloperName);
            }
        }
        return countries;
    }

    /**
     * @description translates Submeter Editing modes to Portal Setting Record Names
     */
    private static String translateToPortalSettingsRecordName(String mode) {
        String recordName;
        if (mode == 'annual_submeter_enabled') {
            recordName = 'Annual Submeter - Allow Update';
        } else if (mode == 'monthly_submeter_enabled') {
            recordName = 'Monthly Submeter - Allow Update';
        }
        return recordName;
    }

    public static Boolean isMeterBillingTypePricingComponent(Pricing_Component__c pcItemToTest) {
        Boolean result = false;
        if (pcItemToTest.RecordTypeId == FLOATING_ENERGY_PRICING_COMPONENT_REC_TYPE_ID
                && ((pcItemToTest.Contract__r.Contract_Type_New__c == 'Feed in Tariff PPA'
                && pcItemToTest.Contract__r.Product_Type_New__c == 'Direct Marketing')
                || (pcItemToTest.Contract__r.Contract_Type_New__c == 'Merchant PPA' &&
                (pcItemToTest.Contract__r.Product_Type_New__c == 'Ref.MV Indexed'
                        || pcItemToTest.Contract__r.Product_Type_New__c == 'Spot Indexed')))) {
            result = true;
        } else if (pcItemToTest.RecordTypeId == FIXED_ENERGY_PRICING_COMPONENT_REC_TYPE_ID
                && ((pcItemToTest.Contract__r.Contract_Type_New__c == 'Feed in Tariff PPA' && pcItemToTest.Contract__r.Product_Type_New__c == 'Direct Marketing')
                || (pcItemToTest.Contract__r.Contract_Type_New__c == 'Merchant PPA' && pcItemToTest.Contract__r.Product_Type_New__c == 'Fixed Price w/GOO')
                || (pcItemToTest.Contract__r.Product_Type_New__c == 'Fixed Price w/o GOO'))) {
            result = true;
        }
        return result;
    }

    public static Map<Id, Contract__c> getSubMeterContracts(Set<Id> contractIds) {
        Date today = Date.today();
        Date startLastYear = Date.newInstance(today.year() - 1, 1, 1);
        return new Map<Id, Contract__c>([
                SELECT
                        Name,
                        KeepPortalAccessUntil__c,
                        Contract_Holder__r.Name,
                        RecordType.DeveloperName,
                        Meter_Billing_Type__c,
                        Country__c,
                        Global_Portal_Market__c,
                        Contract_Type_New__c,
                        Product_Type_New__c,
                        Contract_Type__c, (
                        SELECT
                                Id,
                                RecordTypeId,
                                Meter_Billing_Type__c,
                                Start_Date__c,
                                End_Date__c,
                                Contract__r.Product_Type_New__c,
                                Contract__r.Contract_Type_New__c
                        FROM Pricing_Components__r
                        WHERE Start_Date__c <= :today
                        AND End_Date__c >= :startLastYear
                        ORDER BY Start_Date__c ASC
                )
                FROM Contract__c
                WHERE Id IN :contractIds
        ]);
    }
}