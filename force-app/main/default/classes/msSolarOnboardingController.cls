/**
 * Created by u52448 on 21.08.2020.
 */

public without sharing class msSolarOnboardingController {

    static String apiKey = msUtility.getMetadata().Solar_Onboarding_Mastr_API_Key__c;
    static String marktActorMastrNumber = msUtility.getMetadata().Solar_Onboarding_Markt_Actor_Mastr_No__c;

    static final String FRAMEWORK_AGREEMENT_CONTRACT_TYPE = 'Framework Agreement';
    static final String WHITE_LBL_PROD_TYPE = 'White Label';
    static final String SITE_ROLE_CUS_PORTAL_ROLE = 'Customer Portal';
    static Contract__c wlParentContract;
    static List<LabelValuePair> dsoOptions;
    static Map<String, LabelValuePair> inclinationOptions;
    static Map<String, LabelValuePair> alignmentOptions;

    @AuraEnabled
    public static PlantWrapper getPlantDetails(String mastrId) {

        try {

            if(isPlantExists(mastrId)){
                throw new AuraHandledException(Label.Solar_Onboarding_Plant_Already_Exists);
            }

            Contract__c parentWLContract = getWLParentContractOfCurrentUser();
            if (parentWLContract != null) {
                msSolarOnboardingMastrSoapService.Anlage soapService = new msSolarOnboardingMastrSoapService.Anlage();
                msSolarOnboardingMastrSoapService.GetEinheitSolarAntwort solarPlant = soapService.GetEinheitSolar(apiKey, marktActorMastrNumber, mastrId);
                msSolarOnboardingMastrSoapService.GetAnlageEegSolarAntwort eeg = soapService.GetAnlageEegSolar(apiKey, marktActorMastrNumber, solarPlant.EegMastrNummer);
                msSolarOnboardingMastrSoapService.GetLokationStromErzeugerAntwort location = soapService.GetLokationStromErzeuger(apiKey, marktActorMastrNumber, solarPlant.LokationMastrNummer);

                PlantDetails plant = new PlantDetails();
                PlantWrapper plantWrapper = new PlantWrapper();
                plant.plantStatus = solarPlant.EinheitBetriebsstatus == 'inBetrieb' ? PlantStatus.inOperation.name() : PlantStatus.inPlanning.name();
                plant.mastrId = solarPlant.EinheitMastrNummer;
                plant.plantName = solarPlant.NameStromerzeugungseinheit;
                plant.measurementLocationId = location.Netzanschlusspunkte != null ? location.Netzanschlusspunkte[0].Messlokation : '';
                //plant.marketLocationId = location.NameDerTechnischenLokation;
                plant.eegSystemKey = eeg.AnlagenschluesselEeg;
                plant.installedCapacityKw = solarPlant.Bruttoleistung;

                LabelValuePair inclination = inclinationOptions.get(solarPlant.HauptausrichtungNeigungswinkel.toLowerCase());
                plant.inclinationAngle = inclination == null ? '' : inclination.value;

                LabelValuePair orientation = alignmentOptions.get(solarPlant.Hauptausrichtung.toLowerCase());
                plant.orientation = orientation == null ? '' : orientation.value;

                plant.commissioningDate = solarPlant.Inbetriebnahmedatum;
                plant.street = solarPlant.Strasse;
                plant.postCode = solarPlant.Postleitzahl;
                plant.city = solarPlant.Ort;
                plant.province = solarPlant.Bundesland;
                plant.country = solarPlant.Land;
                plant.longitude = solarPlant.Laengengrad;
                plant.latitude = solarPlant.Breitengrad;
                //plant.networkOperator = '';
                //plant.controlArea = '';
                plant.spvName = parentWLContract.Contract_Holder__r.Name;
                plantWrapper.plant = plant;
                plantWrapper.minContractStartDate = Date.today().addDays(14);
                plantWrapper.maxContractEndDate = parentWLContract.End_Date__c;
                return plantWrapper;
            } else {
                throw new AuraHandledException(Label.Solar_Onboarding_Valid_Contract_not_found);
            }
        } catch (CalloutException ex) {
            throw new AuraHandledException(Label.Solar_Onboarding_Plant_details_retrieval_failed);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException(Label.msInternalErrorMessage);
        }
    }

    @AuraEnabled
    public static Contract__c savePlantDetails(PlantDetails plantDetails) {

        Savepoint sp = Database.setSavepoint();

        try {
            Contract__c parentContract = getWLParentContractOfCurrentUser();
            if (parentContract != null) {

                String contract_country = parentContract.Country__c;
                String contract_currency = parentContract.CurrencyIsoCode;

                if (plantDetails.networkOperatorId == 'other') {
                    Account dsoAccount = new Account(
                            Name = plantDetails.otherNetworkOperator,
                            RecordTypeId = msUtility.ACCOUNT_SYS_OPERATOR_REC_TYPE_ID,
                            CurrencyIsoCode = contract_currency,
                            OwnerId = msUtility.getPixosServiceUserId()
                    );
                    insert dsoAccount;
                    plantDetails.networkOperatorId = dsoAccount.Id;
                    createAccountCreationCase(dsoAccount);
                }

                Contract__c subContract = parentContract.clone(false, false, false, false);
                subContract.Name = parentContract.Name + '_WL_' + plantDetails.plantName;
                subContract.Parent_Contract__c = parentContract.Id;
                subContract.Shared_Meter__c = plantDetails.sharedMeteringPoint;
                subContract.Status__c = 'In Approval Process';
                subContract.Approved__c = false;
                subContract.Contract_Type_New__c = 'Sub-Contract';
                subContract.Legal_Capacity__c = convertKwtoMw(Decimal.valueOf(plantDetails.installedCapacityKw));
                subContract.Start_Date__c = plantDetails.contractStartDate;
                subContract.End_Date__c = plantDetails.contractEndDate;
                subContract.Created_through_Portal__c = true;
                subContract.Portal_PM__c = true;
                insert subContract;

                if (!parentContract.Pricing_Components__r.isEmpty()) {

                    String pcId = getPricingCmpIdByInstalledCapacity(Decimal.valueOf(plantDetails.installedCapacityKw));
                    Map<Id, Pricing_Component__c> pcMap = new Map<Id, Pricing_Component__c>();
                    pcMap.putAll(parentContract.Pricing_Components__r);
                    Pricing_Component__c pc = pcMap.get(pcId);

                    if(pc != null){
                        Pricing_Component__c pcClone = pc.clone(false, false, false, false);
                        pcClone.Contract__c = subContract.Id;
                        pcClone.Start_Date__c = subContract.Start_Date__c;
                        pcClone.End_Date__c = subContract.End_Date__c;
                        insert pcClone;
                    }
                }

                Meter__c meter = new Meter__c(
                        RecordTypeId = msUtility.METER_EXP_METER_REC_TYPE_ID,
                        Status__c = plantDetails.plantStatus == 'inOperation' ? 'Active' : 'Planned',
                        Marktstammdatenregister_ID__c = plantDetails.mastrId,
                        Name = plantDetails.plantName,
                        Site_Construction_Project_Number__c = plantDetails.projectNumber == null ? '' : plantDetails.projectNumber,
                        Alternative_Meter_ID__c = plantDetails.marketLocationId,
                        Meter_ID__c = plantDetails.measurementLocationId,
                        DSO__c = plantDetails.networkOperatorId,
                        TSO__c = plantDetails.controlAreaId,
                        Battery_System_Company__c = plantDetails.batteryManufacturer == null ? '' : plantDetails.batteryManufacturer,
                        Battery_Model__c = plantDetails.batteryModel == null ? '' : plantDetails.batteryModel,
                        Battery_Information__c = plantDetails.OtherBatteryInfos == null ? '' : plantDetails.OtherBatteryInfos,
                        Site_Location_Street__c = plantDetails.street == null ? '' : plantDetails.street,
                        Site_Location_Postcode__c = plantDetails.postCode == null ? '' : plantDetails.postCode,
                        Site_Location_County__c = plantDetails.province == null ? '' : plantDetails.province,
                        Site_Location_Country__c = plantDetails.country == null || plantDetails.country == 'Deutschland'? 'Germany' : plantDetails.country,
                        Site_Location_City__c = plantDetails.city == null ? '' : plantDetails.city,
                        GPS_Location__Longitude__s = plantDetails.longitude,
                        GPS_Location__Latitude__s = plantDetails.latitude,
                        Country__c = contract_country,
                        CurrencyIsoCode = contract_currency,
                        Main_Technology__c = parentContract.Technology__c,
                        Current_Contract__c = subContract.Id
                );

                if (plantDetails.haveBattery != null) {
                    meter.Battery__c = plantDetails.haveBattery;
                }
                if (plantDetails.plannedBatteryUsage != null) {
                    meter.Battery_Usage__c = plantDetails.plannedBatteryUsage;
                }
                if (plantDetails.installedBatteryCapacity != null) {
                    //battery capacity in kw
                    meter.Battery_Capacity__c = Decimal.valueOf(plantDetails.installedBatteryCapacity);
                }
                insert meter;

                Site_Role__c siteRole = new Site_Role__c(
                        RecordTypeId = msUtility.SITE_ROLE_CONTACT_REC_TYPE_ID,
                        Meter__c = meter.Id,
                        Contact__c = msUtility.getUserDetails().contact.Id,
                        Role__c = SITE_ROLE_CUS_PORTAL_ROLE,
                        Start_Date__c = Date.today(),
                        Country__c = contract_country,
                        CurrencyIsoCode = contract_currency
                );
                siteRole.name = siteRole.Id;
                insert  siteRole;

                Generation_Unit__c generationUnit = new Generation_Unit__c(
                        RecordTypeId = msUtility.GU_SOLAR_REC_TYPE_ID,
                        Name = plantDetails.eegSystemKey,
                        Unit_ID__c = plantDetails.eegSystemKey,
                        Installed_Capacity__c = convertKwtoMw(Decimal.valueOf(plantDetails.installedCapacityKw)),
                        Remote_Control_Solution__c = plantDetails.remoteControlSolution,
                        Module_Tracking__c = plantDetails.traceability,
                        Radio_Receiver_Installed__c = plantDetails.traceability,
                        Facility_Type__c = plantDetails.facilityType,
                        Commissioning_Date__c = plantDetails.commissioningDate,
                        Status__c = 'Active',
                        EEG_Eligibility_Start__c = plantDetails.eegEligibilityDate,
                        Site_Location_Street__c = plantDetails.street == null ? '' : plantDetails.street,
                        Site_Location_Postcode__c = plantDetails.postCode == null ? '' : plantDetails.postCode,
                        Site_Location_County__c = plantDetails.province == null ? '' : plantDetails.province,
                        Site_Location_Country__c = plantDetails.country == null || plantDetails.country == 'Deutschland'? 'Germany' : plantDetails.country,
                        Site_Location_City__c = plantDetails.city == null ? '' : plantDetails.city,
                        GPS_Location__Longitude__s = plantDetails.longitude,
                        GPS_Location__Latitude__s = plantDetails.latitude,
                        Country__c = contract_country,
                        CurrencyIsoCode = contract_currency
                );

                if(isDecimal(plantDetails.inclinationAngle)){
                    generationUnit.Module_Inclination__c =  Decimal.valueOf(plantDetails.inclinationAngle);
                }

                if(isDecimal(plantDetails.orientation)){
                    generationUnit.Module_Orientation__c =  Decimal.valueOf(plantDetails.orientation);
                }

                insert generationUnit;

                Generation_Unit_Ownership__c generationUnitOwnership = new Generation_Unit_Ownership__c(
                        Name = parentContract.Contract_Holder__r.Name,
                        Start_Date__c = Date.today(),
                        Asset_Owner__c = parentContract.Contract_Holder__c,
                        Generation_Unit__c = generationUnit.Id,
                        Country__c = contract_country,
                        CurrencyIsoCode = contract_currency
                );
                insert generationUnitOwnership;

                Meter2GenerationUnitRelationship__c meter2Gen = new Meter2GenerationUnitRelationship__c(
                        Name = 'M2G_' + generationUnit.Name + Date.today(),
                        Generator_Unit__c = generationUnit.Id,
                        Meter__c = meter.Id,
                        Valid_from__c = Date.today(),
                        Valid_to__c = Date.today().addDays(14),
                        Active__c = false,
                        Country__c = contract_country,
                        CurrencyIsoCode = contract_currency
                );
                insert meter2Gen;

                MeterRegistration__c meterReg = new MeterRegistration__c (
                        Name = 'MReg_' + meter.Id + parentContract.Name + '#' + Date.today(),
                        Contract__c = subContract.Id,
                        Meter__c = meter.Id,
                        Valid_from__c = plantDetails.meterRegistrationValidFrom,
                        Balancing_Circle__c = parentContract.Balancing_Circle__c,
                        Active__c = false,
                        Status__c = plantDetails.meterRegistrationStatus,
                        Country__c = contract_country,
                        CurrencyIsoCode = contract_currency
                );
                insert meterReg;

                return subContract;

            } else {
                throw new AuraHandledException(Label.Solar_Onboarding_Valid_Contract_not_found);
            }
        } catch (AuraHandledException ex) {
            Database.rollback(sp);
            throw ex;
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(Label.msServerErrorMessage);
        }
    }

    @AuraEnabled
    public static PlantsDatatable getPlantsDatatableInfos(String[] contractIds){
        PlantsDatatable datatableInfo = new PlantsDatatable();
        datatableInfo.attachmentInfos = getContractAttachmentsInfo(contractIds);
        datatableInfo.headerLabels = getDatatableHeaderLabels();
        return datatableInfo;
    }

    @AuraEnabled
    public static void generateContractDocument(Contract__c contract){
        if(contract != null){
            String sessionId = UserInfo.getSessionId();
            String serverUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/services/Soap/u/37.0/'+UserInfo.getOrganizationId();
            String fileNamePrefix = msUtility.getSolarOnboardingSettings().Contract_document_name_prefix__c;
            String fileName = String.join(new String[]{fileNamePrefix, contract.Name, String.valueOf(contract.End_Date__c),
                    contract.Formula_Conga_Contract__c == null ? '' : contract.Formula_Conga_Contract__c}, '_');
            String congaUrl = msUtility.getSolarOnboardingSettings().Conga_Composer_API_endpoint__c;
            congaUrl = String.format(congaUrl, new String[]{sessionId, serverUrl, contract.Id, EncodingUtil.urlEncode(fileName, 'UTF-8')});

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(congaUrl);
            req.setMethod('GET');
            //as recommended by CONGA
            req.setTimeout(60000);
            http.send(req);
        }
    }

    private static List<AttachmentInfo> getContractAttachmentsInfo(String[] contractIds){

        List<AttachmentInfo> attachmentInfos = new List<AttachmentInfo>();
        String fileNamePrefix = msUtility.getSolarOnboardingSettings().Contract_document_name_prefix__c;
        ContentDocumentLink[] docLinks = [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :contractIds];
        Map<Id, Id> contentDocumentsMap = new Map<Id, Id>();

        for (ContentDocumentLink link : docLinks) {
            if (link.ContentDocumentId != null) {
                contentDocumentsMap.put(link.ContentDocumentId, link.LinkedEntityId);
            }
        }

        if(contentDocumentsMap != null && contentDocumentsMap.size() > 0){
            ContentVersion[] conVersions = [SELECT Id, ContentDocumentId, CreatedDate FROM ContentVersion WHERE ContentDocumentId
                    IN :contentDocumentsMap.keySet() and Title LIKE :fileNamePrefix+'%' ORDER BY CreatedDate DESC];

            if(conVersions.size() > 0){
                for (ContentVersion cv : conVersions) {
                    AttachmentInfo attachmentInfo = new AttachmentInfo();
                    attachmentInfo.contentDocumentId = cv.ContentDocumentId;
                    attachmentInfo.linkedEntityId = contentDocumentsMap.get(cv.ContentDocumentId);
                    attachmentInfos.add(attachmentInfo);
                }
            }
        }

        return attachmentInfos;
    }

    private static Map<String, String> getDatatableHeaderLabels(){
        Map<String, String> labels = new Map<String, String>();
        labels.put('plantName', Label.msSolarOnboardingTableHeaderPlantName);
        labels.put('contractName', Label.msSolarOnboardingTableHeaderContractNumber);
        labels.put('mastrId', Label.msSolarOnboardingTableHeaderMaStDR_ID);
        labels.put('contractStatus', Label.msSolarOnboardingTableHeaderRequestStatus);
        labels.put('attachment', Label.msSolarOnboardingTableHeaderApprovalDocument);
        return labels;
    }

    private static Boolean isPlantExists(String mastrId){
        return [SELECT COUNT() FROM Meter__c WHERE Marktstammdatenregister_ID__c = :mastrId] > 0;
    }

    private static void createAccountCreationCase(Account account) {
        try {
            String queueName = msUtility.getSolarOnboardingSettings().Account_Creation_Queue_Name__c;
            List<QueueSobject> queueList = [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.DeveloperName = :queueName];

            if (queueList.size() > 0) {
                User user = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
                Case newCase = new Case(
                        ContactId = user.ContactId,
                        Subject = 'Approve new System Operator Account: ' + account.Name,
                        Description = 'Added new DSO: ' + account.Name,
                        RecordTypeId = msUtility.CASE_STANDARD_REC_TYPE_ID,
                        Origin = 'Web',
                        OwnerId = queueList.get(0).QueueId,
                        Case_Creator__c = UserInfo.getUserId(),
                        AccountId = account.Id,
                        Reason = 'Master Data Change'
                );
                insert newCase;
            } else {
                throw new AuraHandledException('Queue with name ' + queueName + ' is not found');
            }
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException(Label.msServerErrorMessage);
        }
    }

    private static Contract__c getWLParentContractOfCurrentUser() {

        if (wlParentContract == null) {
            List<Contract__c> contracts = msUtility.getUserDetails().contracts;
            Contract__c parentContract = null;
            for (Contract__c contract : contracts) {
                if (contract.Contract_Type_New__c == FRAMEWORK_AGREEMENT_CONTRACT_TYPE
                        && contract.Product_Type_New__c == WHITE_LBL_PROD_TYPE
                        && contract.Portal_PM__c == true) {
                    parentContract = [
                            SELECT
                                    Id,
                                    Name,
                                    Contract_Holder__c,
                                    Contract_Holder__r.Name,
                                    RecordTypeId,
                                    Product_Type_New__c,
                                    Workflow_Type__c,
                                    Technology__c,
                                    Start_Date__c,
                                    End_Date__c,
                                    Termination_Status__c,
                                    Termination_Notice_Period__c,
                                    Settlement_Model__c,
                                    Meter_Billing_Type__c,
                                    Bank_Account_Owner__c,
                                    Bank_Name__c,
                                    BIC_Code__c,
                                    IBAN__c,
                                    Balancing_Circle__c,
                                    Contract_Legal_Status__c,
                                    CurrencyIsoCode,
                                    Country__c,
                                    Formula_Conga_Contract__c,
                                    (SELECT Name, RecordTypeId, Start_Date__c, End_Date__c, Value__c, CurrencyIsoCode, Country__c
                                    FROM Pricing_Components__r
                                    WHERE RecordTypeId = :msUtility.PRICING_CMP_FIXED_FEE)
                            FROM Contract__c
                            WHERE Id = :contract.Id
                            LIMIT 1
                    ];
                }
            }

            wlParentContract = parentContract;
        }

        return wlParentContract;
    }

    public class PlantDetails {
        //Plant Info
        @AuraEnabled public String plantStatus { get; set; }
        @AuraEnabled public String mastrId { get; set; }
        @AuraEnabled public String plantName { get; set; }
        @AuraEnabled public String projectNumber { get; set; }
        @AuraEnabled public String meterRegistrationStatus { get; set; }
        @AuraEnabled public Date meterRegistrationValidFrom { get; set; }
        @AuraEnabled public Date contractStartDate { get; set; }
        @AuraEnabled public Date contractEndDate { get; set; }

        //Mains Connection
        @AuraEnabled public String marketLocationId { get; set; } //mAlo
        @AuraEnabled public String measurementLocationId { get; set; } //mElo
        @AuraEnabled public Boolean sharedMeteringPoint { get; set; }
        @AuraEnabled public String otherUsersOnSameMeter { get; set; }
        @AuraEnabled public String eegSystemKey { get; set; }
        @AuraEnabled public String networkOperator { get; set; }
        @AuraEnabled public String networkOperatorId { get; set; }
        @AuraEnabled public String otherNetworkOperator { get; set; }
        @AuraEnabled public String controlArea { get; set; }
        @AuraEnabled public String controlAreaId { get; set; }

        //Tech Specs
        @AuraEnabled public String installedCapacityKw { get; set; }
        @AuraEnabled public String remoteControlSolution { get; set; }
        @AuraEnabled public String inclinationAngle { get; set; }
        @AuraEnabled public String orientation { get; set; }
        @AuraEnabled public Boolean traceability { get; set; }
        @AuraEnabled public Boolean radioReceiverInstalled { get; set; }
        @AuraEnabled public String facilityType { get; set; }

        //Compensation Data
        @AuraEnabled public Date commissioningDate { get; set; }
        @AuraEnabled public Date eegEligibilityDate { get; set; }
        @AuraEnabled public String spvName { get; set; }

        //Geo Data
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String postCode { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String province { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }

        //battery info
        @AuraEnabled public Boolean haveBattery { get; set; }
        @AuraEnabled public String batteryManufacturer { get; set; }
        @AuraEnabled public String batteryModel { get; set; }
        @AuraEnabled public String installedBatteryCapacity { get; set; }
        @AuraEnabled public Date plannedBatteryUsage { get; set; }
        @AuraEnabled public String OtherBatteryInfos { get; set; }

    }

    public class PlantWrapper {

        public PlantWrapper() {
            yesNoRadioGroupOptions = new List<LabelValuePair>{
                    new LabelValuePair(Label.Solar_Onboarding_Yes_Label, 'true'),
                    new LabelValuePair(Label.Solar_Onboarding_No_Label, 'false')
            };

            plantStatusRadioGroupOptions = new List<LabelValuePair>{
                    new LabelValuePair(Label.Solar_Onboarding_In_Operation, PlantStatus.inOperation.name()),
                    new LabelValuePair(Label.Solar_Onboarding_In_Planning, PlantStatus.inPlanning.name())
            };

            tsoOptions = getTsoOptions();
            dsoOptions = getDsoOptions();
            remoteControlOptions = getPickListValues(Generation_Unit__c.Remote_Control_Solution__c);
            facilityTypeOptions = getPickListValues(Generation_Unit__c.Facility_Type__c);
            meterRegistrationStatusOptions = getMeterRegStatusOptions();
            inclinationAngleOptions = getInclinationAngleOptions().values();
            alignmentDegreeOptions = getAlignmentDegreeOptions().values();
        }

        @AuraEnabled public PlantDetails plant { get; set; }
        @AuraEnabled public List<LabelValuePair> yesNoRadioGroupOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> plantStatusRadioGroupOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> tsoOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> dsoOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> remoteControlOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> facilityTypeOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> meterRegistrationStatusOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> inclinationAngleOptions { get; set; }
        @AuraEnabled public List<LabelValuePair> alignmentDegreeOptions { get; set; }
        @AuraEnabled public Date minContractStartDate { get; set; }
        @AuraEnabled public Date maxContractEndDate { get; set; }
    }

    public enum PlantStatus {
        inOperation, inPlanning
    }

    public class LabelValuePair implements Comparable{

        public LabelValuePair() {
        }

        public LabelValuePair(String lbl, String val) {
            label = lbl;
            value = val;
        }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public Integer compareTo(Object compareTo){
            LabelValuePair compareToAcc = (LabelValuePair)compareTo;

            Integer returnValue = 0;

            if (label > compareToAcc.label) {
                returnValue = 1;
            } else if (label < compareToAcc.label) {
                returnValue = -1;
            }

            return returnValue;
        }
    }

    public class AttachmentInfo {
        @AuraEnabled public String contentDocumentId { get; set; }
        @AuraEnabled public String linkedEntityId { get; set; }
        @AuraEnabled public String attachmentUrl {
            get {return String.isBlank(contentDocumentId) ? '' : '../sfc/servlet.shepherd/document/download/'+contentDocumentId;}
            private set{attachmentUrl = value;}
        }
        @AuraEnabled public Boolean hasAttachments {
            get {return String.isBlank(contentDocumentId) ? false : true;}
            private set{hasAttachments = value;}
        }
        @AuraEnabled public Date createdDate {get; set;}
    }

    public class PlantsDatatable{
        @AuraEnabled public Map<String, String> headerLabels {get; set;}
        @AuraEnabled public List<AttachmentInfo> attachmentInfos {get; set;}
    }

    public static List<LabelValuePair> getPickListValues(SObjectField field) {
        List<LabelValuePair> options = new List<LabelValuePair>();
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : picklistEntries) {
            options.add(new LabelValuePair(f.getLabel(), f.getValue()));
        }
        return options;
    }

    public static List<LabelValuePair> getDsoOptions() {

        if(dsoOptions == null || dsoOptions.isEmpty()){
            List<LabelValuePair> options = new List<LabelValuePair>();
            for (Account acc : [SELECT Id, Name FROM Account WHERE RecordTypeId = :msUtility.ACCOUNT_SYS_OPERATOR_REC_TYPE_ID]) {
                options.add(new LabelValuePair(acc.Name, acc.Id));
            }

            options.sort();
            options.add(new LabelValuePair('Other', 'other'));
            dsoOptions = options;
        }

        return dsoOptions;
    }

    public static List<LabelValuePair> getTsoOptions() {
        List<LabelValuePair> tsoOptions = new List<LabelValuePair>();
        for (TSO__Mdt tso : [SELECT Label, Account_ID__c FROM TSO__Mdt ORDER BY Label ASC]) {
            tsoOptions.add(new LabelValuePair(tso.Label, tso.Account_ID__c));
        }
        return tsoOptions;
    }

    public static Map<String, LabelValuePair> getInclinationAngleOptions(){
        if(inclinationOptions == null || inclinationOptions.isEmpty()){
            Map<String, LabelValuePair> inclinationAngleOptions = new Map<String, LabelValuePair>();
            for (Solar_Module_Inclination_Mapping__Mdt item : [SELECT Label, Value__c, DeveloperName FROM Solar_Module_Inclination_Mapping__Mdt]) {
                String value = String.isEmpty(String.valueOf(item.Value__c)) ? item.Label : String.valueOf(item.Value__c);
                inclinationAngleOptions.put(item.DeveloperName.toLowerCase(), new LabelValuePair(item.Label, value));
            }
            inclinationOptions = inclinationAngleOptions;
        }
        return inclinationOptions;
    }

    public static Map<String, LabelValuePair> getAlignmentDegreeOptions(){
        if(alignmentOptions == null || alignmentOptions.isEmpty()){
            Map<String, LabelValuePair> alignmentDegreeOptions = new Map<String, LabelValuePair>();
            for (Solar_Module_Alignments_Mapping__Mdt item : [SELECT Label, Value__c, DeveloperName FROM Solar_Module_Alignments_Mapping__Mdt]) {
                String value = String.isEmpty(String.valueOf(item.Value__c)) ? item.Label : String.valueOf(item.Value__c);
                alignmentDegreeOptions.put(item.DeveloperName.toLowerCase(), new LabelValuePair(item.Label, value));
            }
            alignmentOptions = alignmentDegreeOptions;
        }
        return alignmentOptions;
    }

    public static List<LabelValuePair> getMeterRegStatusOptions() {
        List<LabelValuePair> mRegStatuses = new List<LabelValuePair>();
        for (String status : msUtility.getSolarOnboardingSettings().Meter_Registration_Status__c.split('\n')) {
            mRegStatuses.add(new LabelValuePair(status, status));
        }
        return mRegStatuses;
    }

    private static Id getPricingCmpIdByInstalledCapacity(Decimal capacity){
        List<Pricing_Cmp_by_Installed_Capacity__mdt> pc;
        pc = [SELECT From__c, To__c, Pricing_Component_Id__c FROM Pricing_Cmp_by_Installed_Capacity__mdt WHERE From__c <= :capacity AND To__c >= :capacity LIMIT 1];
        if(pc.isEmpty()){
            pc = [SELECT From__c, To__c, Pricing_Component_Id__c FROM Pricing_Cmp_by_Installed_Capacity__mdt WHERE From__c <= :capacity AND To__c = null LIMIT 1];
        }
        return pc.get(0).Pricing_Component_Id__c;
    }

    private static Decimal convertKwtoMw(Decimal capacityinKw){
        if(capacityinKw != null){
            return capacityinKw/1000;
        }else{
            return null;
        }
    }
    
    private static Boolean isDecimal(String str){
      Boolean isValidDecimal = false;
        if(str != null || !String.isEmpty(str)){
            try{
                Decimal.valueOf(str);
                isValidDecimal = true;
            }
            catch(TypeException e){
                isValidDecimal = false;
            }
        }
        return isValidDecimal;
    }
}