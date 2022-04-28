public without sharing class msAgreementHelper {
    @AuraEnabled
    public static void generateAgreementConnections(Apttus__APTS_Agreement__c agreement) {
        List<Agreement2Details__c> oldDetails = [SELECT Id FROM Agreement2Details__c WHERE Agreement__c = :agreement.Id];
        delete oldDetails;

        List<Agreement2Details__c>newDetails = new List<Agreement2Details__c>();
        List<Id>meterIds = new List<Id>();
        String RT_CONTACT_DETAILS = Schema.SObjectType.Agreement2Details__c.getRecordTypeInfosByDeveloperName().get('Contact_Details').getRecordTypeId();
        String RT_METER_DETAILS = Schema.SObjectType.Agreement2Details__c.getRecordTypeInfosByDeveloperName().get('Meter_Details').getRecordTypeId();

        Contract__c contract = [SELECT Id, Name, Start_Date__c, End_Date__c, Third_Party_Contract__c FROM Contract__c WHERE Id = :agreement.Contract__c];
        List<Contract_Role__c> contractRoles = [
                SELECT Id, Start_Date__c, End_Date__c, Contact__c, Role__c
                FROM Contract_Role__c
                WHERE Contract__c = :contract.Id AND
                (End_Date__c >= :contract.End_Date__c OR End_Date__c = null)
                AND (Role__c = 'Contractual Contact' OR Role__c = 'Commercial Contact' OR Role__c = 'Technical Contact')
        ];

        Agreement2Details__c contactDetails = new Agreement2Details__c();
        contactDetails.RecordTypeId = RT_CONTACT_DETAILS;
        contactDetails.Agreement__c = agreement.Id;
        for (Contract_Role__c tempRole : contractRoles) {
            if (tempRole.Role__c == 'Contractual Contact')
                contactDetails.Contractual_Contact__c = tempRole.Contact__c;
            if (tempRole.Role__c == 'Commercial Contact')
                contactDetails.Commercial_Contact__c = tempRole.Contact__c;
            if (tempRole.Role__c == 'Technical Contact')
                contactDetails.Technical_Contact__c = tempRole.Contact__c;
        }
        newDetails.add(contactDetails);


        List<MeterRegistration__c> meterRegistrations = [
                SELECT Meter__c, Contract__r.Name, Contract__r.Meter_Billing_Type__c, Contract__c,
                        Meter__r.Parent_Meter__c, Meter__r.Country__c, Meter__r.Name,
                        Contract__r.Parent_Contract__r.Name, Contract__r.Start_Date__c, Contract__r.KeepPortalAccessUntil__c,
                        Contract__r.End_Date__c, Valid_from__c, Valid_to__c
                FROM MeterRegistration__c
                WHERE Contract__c = :contract.Id AND (Valid_to__c >= :contract.End_Date__c OR Valid_to__c = null)
        ];


        if (contract.Third_Party_Contract__c == true) {
            Map<Id, Id> guIdToMeterId = new Map<Id, Id>();
            Map<Id, Agreement_To_Details_GU__c> guIdToAgreementDetailsMap = new Map<Id, Agreement_To_Details_GU__c>();
            Map<String, Agreement2Details__c> meterAndOwnerToMeterDetails = new Map<String, Agreement2Details__c>();
            Map<String, List<Agreement_To_Details_GU__c>> meterAndOwnerToGUDetails = new Map<String, List<Agreement_To_Details_GU__c>>();
            List<Id>guIds = new List<Id>();
            Map<String, Generation_Unit_Ownership__c> accAndMeterToGUO = new Map<String, Generation_Unit_Ownership__c>();
            List<Agreement_To_Details_GU__c> guDetails = new List<Agreement_To_Details_GU__c>();

            for (MeterRegistration__c tempReg : meterRegistrations) {
                meterIds.add(tempReg.Meter__c);
            }

            //Generation Unit
            List<Meter2GenerationUnitRelationship__c> meter2GenerationUnitRelationships = [
                    SELECT Id, Meter__c, Generator_Unit__c, Valid_from__c, Valid_to__c
                    FROM Meter2GenerationUnitRelationship__c
                    WHERE Meter__c IN:meterIds
                    AND (Valid_to__c >= :contract.End_Date__c OR Valid_to__c = null)
            ];

            for (Meter2GenerationUnitRelationship__c tempM2GU : meter2GenerationUnitRelationships) {
                Agreement_To_Details_GU__c tempGUDetails = new Agreement_To_Details_GU__c();
                tempGUDetails.Agreement__c = agreement.Id;
                tempGUDetails.Generation_Unit__c = tempM2GU.Generator_Unit__c;
                guIdToMeterId.put(tempM2GU.Generator_Unit__c, tempM2GU.Meter__c);

                guIdToAgreementDetailsMap.put(tempM2GU.Generator_Unit__c, tempGUDetails);
                guIds.add(tempM2GU.Generator_Unit__c);
            }

            //Generation Unit - add ownership
            List<Generation_Unit_Ownership__c> generationUnitOwnerships = [
                    SELECT Id, Generation_Unit__c, Asset_Owner__c, Start_Date__c,End_Date__c, Generation_Unit__r.Installed_Capacity__c
                    FROM Generation_Unit_Ownership__c
                    WHERE Generation_Unit__c IN :guIds
                    AND (End_Date__c >= :contract.End_Date__c OR End_Date__c = null)
            ];

            for (Generation_Unit_Ownership__c tempGuOwnership : generationUnitOwnerships) {
                Agreement_To_Details_GU__c tempGUDetails = guIdToAgreementDetailsMap.get(tempGuOwnership.Generation_Unit__c);
                tempGUDetails.Generation_Unit_Ownership__c = tempGuOwnership.Id;
                tempGUDetails.Asset_Owner__c=tempGuOwnership.Asset_Owner__c;
                tempGUDetails.Installed_Capacity__c=tempGuOwnership.Generation_Unit__r.Installed_Capacity__c;

                Id meterId = guIdToMeterId.get(tempGuOwnership.Generation_Unit__c);
                List<Agreement_To_Details_GU__c> gusOfMeter = meterAndOwnerToGUDetails.get(meterId + '_' + tempGuOwnership.Asset_Owner__c);
                if (gusOfMeter == null)gusOfMeter = new List<Agreement_To_Details_GU__c>();

                gusOfMeter.add(tempGUDetails);
                meterAndOwnerToGUDetails.put(meterId + '_' + tempGuOwnership.Asset_Owner__c, gusOfMeter);
                accAndMeterToGUO.put(meterId + '_' + tempGuOwnership.Asset_Owner__c, tempGuOwnership);
            }

            //Meter
            for (String key : meterAndOwnerToGUDetails.keySet()) {
                List<String> keyList = key.split('_', 2);
                Agreement2Details__c tempMeterDetails = new Agreement2Details__c();
                tempMeterDetails.RecordTypeId = RT_METER_DETAILS;
                tempMeterDetails.Agreement__c = agreement.Id;
                tempMeterDetails.Meter__c = keyList[0];

                Generation_Unit_Ownership__c tempGuOwnership = accAndMeterToGUO.get(key);
                tempMeterDetails.Generation_Unit_Ownership__c = tempGuOwnership.Id;
                tempMeterDetails.Asset_Owner__c=tempGuOwnership.Asset_Owner__c;

                tempMeterDetails.Installed_Capacity__c=0;
                List<Agreement_To_Details_GU__c> gusOfMeter=meterAndOwnerToGUDetails.get(key);
                for(Agreement_To_Details_GU__c tempGUDetails:gusOfMeter){
                    tempMeterDetails.Installed_Capacity__c+= tempGUDetails.Installed_Capacity__c;
                }

                newDetails.add(tempMeterDetails);
                meterAndOwnerToMeterDetails.put(key, tempMeterDetails);
            }
            insert newDetails;


            //Generation Units - get Agreement2Details__c for meter and generation unit ownership
            for (String key : meterAndOwnerToGUDetails.keySet()) {
                Agreement2Details__c meterDetails = meterAndOwnerToMeterDetails.get(key);
                List<Agreement_To_Details_GU__c> gusOfMeter = meterAndOwnerToGUDetails.get(key);

                for (Agreement_To_Details_GU__c tempGUDetails : gusOfMeter) {
                    tempGUDetails.Agreement2Details__c = meterDetails.Id;
                    guDetails.add(tempGUDetails);
                }
            }
            insert guDetails;


        } else {
            Map<Id, Agreement2Details__c> meterIdToAgreementDetailsMap = new Map<Id, Agreement2Details__c>();
            Map<Id, Agreement_To_Details_GU__c> guIdToAgreementDetailsMap = new Map<Id, Agreement_To_Details_GU__c>();
            Map<Id, Id> guIdToMeterIdMap = new Map<Id, Id>();
            List<Id>guIds = new List<Id>();

            //Meter
            for (MeterRegistration__c tempReg : meterRegistrations) {
                Agreement2Details__c tempMeterDetails = new Agreement2Details__c();
                tempMeterDetails.RecordTypeId = RT_METER_DETAILS;
                tempMeterDetails.Agreement__c = agreement.Id;
                tempMeterDetails.Meter__c = tempReg.Meter__c;
                tempMeterDetails.Installed_Capacity__c=0;

                newDetails.add(tempMeterDetails);
                meterIdToAgreementDetailsMap.put(tempReg.Meter__c, tempMeterDetails);

                meterIds.add(tempReg.Meter__c);
            }


            //Generation Unit
            List<Meter2GenerationUnitRelationship__c> meter2GenerationUnitRelationships = [
                    SELECT Id, Meter__c, Generator_Unit__c, Valid_from__c, Valid_to__c, Installed_Capacity__c
                    FROM Meter2GenerationUnitRelationship__c
                    WHERE Meter__c IN:meterIds
                    AND (Valid_to__c >= :contract.End_Date__c OR Valid_to__c = null)
            ];
            for (Meter2GenerationUnitRelationship__c tempM2GU : meter2GenerationUnitRelationships) {
                Agreement2Details__c tempMeterDetails = meterIdToAgreementDetailsMap.get(tempM2GU.Meter__c);
                tempMeterDetails.Installed_Capacity__c+=tempM2GU.Installed_Capacity__c;
                guIdToMeterIdMap.put(tempM2GU.Generator_Unit__c, tempM2GU.Meter__c);
            }
            insert newDetails;


            for (Meter2GenerationUnitRelationship__c tempM2GU : meter2GenerationUnitRelationships) {
                Agreement_To_Details_GU__c tempGUDetails = new Agreement_To_Details_GU__c();
                tempGUDetails.Agreement__c = agreement.Id;
                tempGUDetails.Generation_Unit__c = tempM2GU.Generator_Unit__c;
                tempGUDetails.Agreement2Details__c = meterIdToAgreementDetailsMap.get(tempM2GU.Meter__c).Id;


                guIdToAgreementDetailsMap.put(tempM2GU.Generator_Unit__c, tempGUDetails);
                guIds.add(tempM2GU.Generator_Unit__c);
            }

            //Generation Unit Ownership
            List<Generation_Unit_Ownership__c> generationUnitOwnerships = [
                    SELECT Id, Generation_Unit__c,Start_Date__c,End_Date__c, Asset_Owner__c
                    FROM Generation_Unit_Ownership__c
                    WHERE Generation_Unit__c IN :guIds
                    AND (End_Date__c >= :contract.End_Date__c OR End_Date__c = null)
            ];
            for (Generation_Unit_Ownership__c tempGuOwnership : generationUnitOwnerships) {
                Agreement_To_Details_GU__c tempGUDetails = guIdToAgreementDetailsMap.get(tempGuOwnership.Generation_Unit__c);
                tempGUDetails.Generation_Unit_Ownership__c = tempGuOwnership.Id;
                tempGUDetails.Asset_Owner__c=tempGuOwnership.Asset_Owner__c;

                Agreement2Details__c tempMeterDetails= meterIdToAgreementDetailsMap.get(guIdToMeterIdMap.get(tempGuOwnership.Generation_Unit__c));
                tempMeterDetails.Asset_Owner__c=tempGuOwnership.Asset_Owner__c;
            }

            update meterIdToAgreementDetailsMap.values();
            insert guIdToAgreementDetailsMap.values();
        }
    }

    public static void populateAgreement(Apttus__APTS_Agreement__c agreementOld) {
        Apttus__APTS_Agreement__c agreement=[SELECT Id, Apttus__Version_Number__c, Contract__c FROM Apttus__APTS_Agreement__c WHERE Id=:agreementOld.Id];
        if (agreement.Contract__c != null && agreement.Apttus__Version_Number__c==0) {


            Contract__c contract = [
                    SELECT Status__c, Contract_Type_New__c, Product_Type_New__c, Contract_Holder__c, Contract_Date__c,
                            Start_Date__c, End_Date__c, Termination_Status__c, Third_Party_Contract__c,
                            REMIT_Reporting_Relevant__c, REMIT_delegated_reporting__c, Bank_Account_Owner__c,
                            Bank_Name__c, IBAN__c, BIC_Code__c
                    FROM Contract__c
                    WHERE Id = :agreement.Contract__c
            ];
            List<Pricing_Component__c> pc = [
                    SELECT RecordType.Name, Index_Price__c, Value__c, Risk_Premium__c
                    FROM Pricing_Component__c
                    WHERE Contract__c = :contract.Id AND Active__c = TRUE
                    LIMIT 1
            ];
            // Subtype
            if (contract.Contract_Type_New__c == 'Merchant PPA' && (contract.Product_Type_New__c == 'Fixed Price w/GOO' || contract.Product_Type_New__c == 'Fixed Price w/o GOO' || contract.Product_Type_New__c == 'Spot Indexed' || contract.Product_Type_New__c == 'Ref.MV Indexed' || contract.Product_Type_New__c == 'Fixed Price and Fixed Volume')) {
                agreement.Apttus__Subtype__c = 'Upstream - Ü20';
            }

            // Other Party Name
            agreement.Apttus__Account__c = contract.Contract_Holder__c;

            // Internal Legal Entity - TBC
            // agreement.APTS_Internal_Legal_Entity__c = ;

            // Agreement Start Date - TBC
            // agreement.Apttus__Contract_Start_Date__c = contract.Start_Date__c;

            // Delivery Start Date
            agreement.APTS_Delivery_Start_Date__c = contract.Start_Date__c;

            // Agreement End Date
            agreement.Apttus__Contract_End_Date__c = contract.End_Date__c;

            // Amendment Effective Date - TBC

            // Auto Renew + Renewal Term (Months)
            if (contract.Termination_Status__c == 'Automatic yearly extension') {
                agreement.Apttus__Auto_Renewal__c = true;
                agreement.Apttus__Auto_Renew_Term_Months__c = 12;
            }

            if(pc.size()==1){
                // Price Type & Risk Premium
                if (pc[0].RecordType.Name == 'Floating Energy Price') {
                    agreement.APTS_Price_Type__c = 'Index';
                    agreement.APTS_Risk_Premium__c = pc[0].Value__c;
                } else if (pc[0].RecordType.Name == 'Fixed Energy Price') {
                    agreement.APTS_Price_Type__c = 'Fixed';
                    agreement.APTS_Fixed_Price__c = pc[0].Value__c;
                }

                // Index Price
                agreement.APTS_Index_Price__c = pc[0].Index_Price__c;
            }


            // Fixed Volume - TBC

            // Downregulation Compensation Type - TBC

            // Minimum Delivery Volume - TBC

            // Third Party Contract
            agreement.APTS_Third_Party_Contract__c = contract.Third_Party_Contract__c;

            // REMIT Reporting Relevant
            agreement.APTS_REMIT_Reporting_Relevant__c = contract.REMIT_Reporting_Relevant__c;

            // REMIT Delegated Reporting
            agreement.APTS_REMIT_Delegated_Reporting__c = contract.REMIT_delegated_reporting__c;

            // Bank Account Owner
            agreement.APTS_Bank_Account_Owner__c = contract.Bank_Account_Owner__c;

            // Bank Name
            agreement.APTS_Bank_Name__c = contract.Bank_Name__c;

            // IBAN
            agreement.APTS_IBAN__c = contract.IBAN__c;

            // BIC
            agreement.APTS_BIC__c = contract.BIC_Code__c;

            update agreement;
        }
    }
    public static void updateContract(Apttus__APTS_Agreement__c agreement, Apttus__APTS_Agreement__c agreementOld) {
        Contract__c contract = [
                SELECT Status__c, Contract_Type_New__c, Product_Type_New__c, Contract_Holder__c, Contract_Date__c,
                        Start_Date__c, End_Date__c, Termination_Status__c, Third_Party_Contract__c,
                        REMIT_Reporting_Relevant__c, REMIT_delegated_reporting__c, Bank_Account_Owner__c,
                        Bank_Name__c, IBAN__c, BIC_Code__c
                FROM Contract__c
                WHERE Id = :agreement.Contract__c
        ];


        // Status
        if (agreement.Apttus__Status_Category__c == 'In Effect' && agreement.Apttus__Status__c == 'Activated') {
            contract.Status__c = 'Active';
        }

        // Other Party Name
        if (contract.Contract_Holder__c != agreement.Apttus__Account__c) {
            contract.Contract_Holder__c = agreement.Apttus__Account__c;
        }

        // Internal Legal Entity - TBC

        // Agreement Start Date - TBC
        /* if (contract.Contract_Date__c != agreement.Apttus__Contract_Start_Date__c) {
            contract.Contract_Date__c = agreement.Apttus__Contract_Start_Date__c;
        } */

        // Delivery Start Date
        if (contract.Start_Date__c != agreement.APTS_Delivery_Start_Date__c && agreement.APTS_Delivery_Start_Date__c != null) {
            contract.Start_Date__c = agreement.APTS_Delivery_Start_Date__c;
        }

        // Agreement End Date
        if (contract.End_Date__c != agreement.Apttus__Contract_End_Date__c && agreement.Apttus__Contract_End_Date__c != null) {
            contract.End_Date__c = agreement.Apttus__Contract_End_Date__c;
        }

        // Amendment Effective Date - TBC

        // Auto Renew
        if (contract.Termination_Status__c != 'Automatic yearly extension' && agreement.Apttus__Auto_Renewal__c == true) {
            contract.Termination_Status__c = 'Automatic yearly extension';
        }

        List<Pricing_Component__c> pc = [
                SELECT RecordType.Name, Index_Price__c, Value__c, Risk_Premium__c
                FROM Pricing_Component__c
                WHERE Contract__c = :contract.Id AND Active__c = TRUE
                LIMIT 1
        ];

        if (pc.size() == 1) {
            // Fixed Price
            if (pc[0].Value__c != agreement.APTS_Fixed_Price__c) {
                pc[0].Value__c = agreement.APTS_Fixed_Price__c;
            }

            // Risk Premium
            if (pc[0].RecordType.Name == 'Floating Energy Price') {
                pc[0].Value__c = agreement.APTS_Risk_Premium__c;
            } else if (pc[0].RecordType.Name == 'Fixed Energy Price') {
                pc[0].Risk_Premium__c = agreement.APTS_Risk_Premium__c;
            }
            update pc;
        }


        // Fixed Volume - TBC

        // Downregulation Compensation Type - TBC

        // Minimum Delivery Volume - TBC

        // Third Party Contract
        contract.Third_Party_Contract__c = agreement.APTS_Third_Party_Contract__c;

        // REMIT Reporting Relevant
        contract.REMIT_Reporting_Relevant__c = agreement.APTS_REMIT_Reporting_Relevant__c;

        // REMIT Delegated Reporting
        contract.REMIT_delegated_reporting__c = agreement.APTS_REMIT_Delegated_Reporting__c;

        // Bank Account Owner
        contract.Bank_Account_Owner__c = agreement.APTS_Bank_Account_Owner__c;

        //Bank Name
        contract.Bank_Name__c = agreement.APTS_Bank_Name__c;

        // IBAN
        contract.IBAN__c = agreement.APTS_IBAN__c;

        // BIC
        contract.BIC_Code__c = agreement.APTS_BIC__c;

        update contract;

    }
}