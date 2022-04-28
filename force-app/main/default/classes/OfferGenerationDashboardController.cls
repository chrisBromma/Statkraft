/**
 * Created by Steffen Naundorf on 09.09.2021.
 */

global without sharing class OfferGenerationDashboardController implements Database.Batchable<SObject> {
    private static Id OPPORTUNITY_RECORD_TYPE_ID_UPSTREAM_EXTENSION_PPA =
            Application.RecordTypes.byDeveloperName('Opportunity', 'PPA_Extension').Id;
    private static Id OFFER_RECORD_TYPE_ID_UPSTREAM_EXTENSION_PPA =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Extension').Id;
    private static Id OFFER_RECORD_TYPE_ID_UPSTREAM_NEGOTIATION_PPA =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Negotiation').Id;

    @AuraEnabled
    global static List<Report> getReports() {
        List<Report> reports = [
                SELECT Id, Name, FolderName, Format
                FROM Report
                WHERE Format = 'Tabular'
                AND FolderName = 'Offer Generation Dashboard'
        ];
        return reports;
    }

    @AuraEnabled
    global static ReportWrapper getReportMetadata(String reportId) {
        ReportWrapper result = new ReportWrapper();
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);

        //Get Columns
        Map<String, Reports.DetailColumn> metadata = results.getReportExtendedMetadata().getDetailColumnInfo();
        List<Reports.DetailColumn> columns = metadata.values();
        Map<String, Integer> fieldToIndex = new Map<String, Integer>();
        for (Integer i = 0; i < columns.size(); i++) {
            fieldToIndex.put(columns[i].getName(), i);
        }

        //Get Data
        Map<String, Reports.ReportFactWithDetails> factWithDetails = (Map<String, Reports.ReportFactWithDetails>) results.getFactMap();
        List<Reports.ReportDetailRow> rows = factWithDetails.get('T!T').getRows();
        List<Id> contractIds = new List<Id>();

        for (Integer i = 0; i < rows.size(); i++) {
            Reports.ReportDetailRow row = rows[i];
            DataRow dataRow = new DataRow();

            List<Reports.ReportDataCell> cells = row.getDataCells();
            for (Integer j = 0; j < cells.size(); j++) {
                Reports.DetailColumn tempColumn = columns[j];
                if (i == 0) {
                    HeaderCell tempHead = new HeaderCell();
                    tempHead.label = tempColumn.getLabel();
                    result.head.add(tempHead);
                }
                DataCell tempCell = new DataCell();
                tempCell.fieldLabel = tempColumn.getLabel();
                tempCell.fieldName = tempColumn.getName();
                tempCell.valueLabel = cells[j].getLabel();
                dataRow.search += cells[j].getLabel().toLowerCase();

                if (j == 0) {
                    dataRow.contractId = String.valueOf(cells[j].getValue());
                    contractIds.add(dataRow.contractId);
                }

                dataRow.data.add(tempCell);
            }
            result.data.add(dataRow);
        }

        Map<Id, Contract__c> contracts = new Map<Id, Contract__c>([
                SELECT Id, Name, Negotiating_Party__r.Owner.Name, Contract_Type_New__c, Product_Type_New__c, Owner.Name
                FROM Contract__c
                WHERE Id IN:contractIds
        ]);
        for (DataRow row : result.data) {
            Contract__c contract = contracts.get(row.contractId);
            if (contract.Negotiating_Party__r != null) {
                row.ownerName = contract.Negotiating_Party__r.Owner.Name.toLowerCase();
            }
            row.contractType = contract.Contract_Type_New__c;
            row.productType = contract.Product_Type_New__c;
            row.workflowType = 'Amendment';
        }
        if (result.data != null && result.data.size() != 0) {
            result.defaultContractType = result.data[0].contractType;
        }

        return result;
    }

    @AuraEnabled
    global static Boolean createOffers(List<DataRow> selectedRows, String opportunityMiddleName) {
        Integer dataMigrationIndex = getDataMigrationId() + 1;
        Map<Id, DataRow>contractIdToRow = new Map<Id, DataRow>();

        List<Id>contractIds = new List<Id>();
        for (DataRow row : selectedRows) {
            contractIds.add(row.contractId);
            contractIdToRow.put(row.contractId, row);
        }

        List<Contract__c> contracts = [
                SELECT Id,Name, Start_Date__c, Contract_Type_New__c, Product_Type_New__c, Negotiating_Party__c,
                        Negotiating_Party__r.Name, Negotiating_Party__r.OwnerId, Negotiating_Party__r.count_of_active_Contracts__c,
                        Contract_Holder__c, Alternative_Contract_Name__c, Legal_Capacity__c, Third_Party_Contract__c,
                        Termination_Status__c, REMIT_delegated_reporting__c, AGB_version__c, Technology__c, End_Date__c,
                        Black_Label__c, Contracted_Annual_Production__c, Billing_Model_Redispatch__c
                FROM Contract__c
                WHERE Id IN:contractIds
        ];

        Account statkraft = [
                SELECT Id, Name
                FROM Account
                WHERE Name = 'Statkraft Markets GmbH'
                OR Data_Migration_ID__c = 'NCD_DM_ID_ACC_6819'
                LIMIT 1
        ];
        Map<Id, Pricing_Component__c>contractIdToPC = getPricingComponents(contractIds, contractIdToRow);
        Map<Id, SK_Security__c>contractIdToGuarantee = getGuarantees(contractIds);
        Map<Id, Meter__c>contractIdToMeter = getMeters(contractIds);
        Map<Id, Offer__c>contractIdToOffer = getOldOffer(contractIds);
        Map<Id, Id> contractIdToBTR = getBTR(contractIds);

        Map<Id, OfferGenerationWrapper> generationWrappersByNegParty = new Map<Id, OfferGenerationWrapper>();

        Logger.info('Start Generation');

        for (Contract__c contract : contracts) {
            Pricing_Component__c pc = contractIdToPC.get(contract.Id);
            SK_Security__c guarantee = contractIdToGuarantee.get(contract.Id);
            Meter__c meter = contractIdToMeter.get(contract.Id);
            Offer__c oldOffer = contractIdToOffer.get(contract.Id);


            OfferGenerationWrapper generationWrapper = generationWrappersByNegParty.get(contract.Negotiating_Party__c);
            if (generationWrapper == null) {
                generationWrapper = new OfferGenerationWrapper();
                generationWrapper.offers = new List<Offer__c>();
                Opportunity opportunity = new Opportunity();
                opportunity.RecordTypeId = OPPORTUNITY_RECORD_TYPE_ID_UPSTREAM_EXTENSION_PPA;
                opportunity.AccountId = contract.Negotiating_Party__c;
                opportunity.OwnerId = contract.Negotiating_Party__r.OwnerId;
                opportunity.Opportunity_Size__c = contract.Negotiating_Party__r.count_of_active_Contracts__c > 1 ? 'Portfolio' : 'Einzelanlage';
                if (opportunityMiddleName != null) {
                    opportunity.Name = 'Renegotiation_opportunity_' + opportunityMiddleName + '_' + contract.Negotiating_Party__r.Name + '_' + (Date.today().year() + 1);
                } else {
                    opportunity.Name = 'Renegotiation_opportunity_' + contract.Negotiating_Party__r.Name + '_' + (Date.today().year() + 1);
                }

                opportunity.StageName = 'Analysis';
                opportunity.Type = 'Existing business';
                opportunity.CloseDate = Date.newInstance(Date.today().year(), 10, 31);
                opportunity.Description = 'Auto-generated ' + Date.today().format();
                opportunity.Country__c = 'Germany';
                opportunity.Features__c = 'Renegotiation';
                opportunity.Contract_Start_Date__c = contract.End_Date__c.addDays(1);
                opportunity.Contract_Type_New__c = contract.Contract_Type_New__c;
                opportunity.Product_Type_New__c = contract.Product_Type_New__c;
                opportunity.Workflow_Type__c = 'Amendment';
                generationWrapper.opportunity = opportunity;
                //Logger.info('Generated Opportunity: ' + JSON.serializePretty(opportunity));
            }

            Offer__c offer = new Offer__c();
            offer.RecordTypeId = OFFER_RECORD_TYPE_ID_UPSTREAM_EXTENSION_PPA;
            offer.Status__c = 'Analysis';
            offer.Contract_Type_New__c = contractIdToRow.get(contract.Id).contractType;
            offer.Product_Type_New__c = contractIdToRow.get(contract.Id).productType;
            offer.Workflow_Type__c = contractIdToRow.get(contract.Id).workflowType;
            if (offer.Workflow_Type__c == 'Replacement') {
                offer.RecordTypeId = OFFER_RECORD_TYPE_ID_UPSTREAM_NEGOTIATION_PPA;
                offer.Status__c = 'Document Generation';
            }
            offer.Base_Contract__c = contract.Id;
            offer.Offer_Annual_Production__c = contract.Contracted_Annual_Production__c;
            offer.Contract_Holder__c = contract.Contract_Holder__c;
            offer.Technology__c = translateTechnology(contract.Technology__c);
            offer.Site_Name__c = contract.Alternative_Contract_Name__c;
            offer.Contract_Start_Date_Offer__c = contractIdToRow.get(contract.Id).newOfferStartDate;
            offer.Contract_End_Date_Offer__c = contractIdToRow.get(contract.Id).newOfferEndDate;
            offer.Black_Label__c = contract.Black_Label__c;
            offer.Offer_Installed_Capacity__c = contract.Legal_Capacity__c;
            offer.Third_Party_Contract__c = contract.Third_Party_Contract__c;
            offer.Resulting_Termination_Status__c = 'Automatic yearly extension';
            offer.Description__c = 'Auto-generated ' + Date.today().format();
            offer.Data_Migration_ID__c = 'Re-Neg' + Date.today().year() + '_' + dataMigrationIndex;
            offer.REMIT_Delegated_Reporting__c = contract.REMIT_delegated_reporting__c;
            offer.Country__c = 'Germany';
            offer.AGB_version__c = contract.AGB_version__c;
            offer.Penalty__c = 'Missing Live Data;Wrong Downregulation;Wrong Availability';
            offer.Billing_Model_Redispatch__c = contract.Billing_Model_Redispatch__c;
            offer.EIV__c = statkraft.Id;
            offer.BTR__c = contractIdToBTR.get(contract.Id);
            if (offer.BTR__c == null) {
                offer.BTR__c = statkraft.Id;
                offer.BTR_Role__c = true;
            }
            if (pc != null) {
                offer.Current_Risk_Premium__c = pc.Risk_Premium__c;
                offer.Index_Price__c = pc.Index_Price__c;
                offer.X51_Compensation_4_1__c = pc.X51_Compensation_3_1__c;
                offer.X51_Compensation_4_2__c = pc.X51_Compensation_4_2__c;
                offer.Settlement_Model__c = pc.Settlement_Model__c;
                offer.Shared_Meter__c = pc.Shared_Meter__c;
                offer.Settlement_Submodel__c = pc.Settlement_SubModel__c;
                offer.Meter_Billing_Type__c = pc.Meter_Billing_Type__c;
            } else {
                //Logger.warn('Contract has no Pricing Component');
            }

            if (guarantee != null) {
                offer.Security_Number__c = guarantee.Id;
                offer.Security_End_Date__c = guarantee.SK_End_Date__c.addYears(1);
                offer.Security_Amount_New__c = guarantee.SK_Notional_Amount__c;
                offer.Security_type__c = guarantee.SK_Guarantee_Record_Type__c;
            } else {
                //Logger.warn('Contract has no Guarantee');
            }

            if (meter != null) {
                offer.Balancing_Model_Redispatch__c = meter.Balancing_Model_Redispatch__c;
                offer.Signal_Routing_Redispatch__c = meter.Signal_Routing_Redispatch__c;
            } else {
                //Logger.warn('Contract has no Meter');
            }

            if (oldOffer != null) {
                offer.Facility_Description__c = oldOffer.Facility_Description__c;
            } else {
                //Logger.warn('Contract has no old Offer');
            }

            //Logger.info('Generated Offer: ' + JSON.serializePretty(offer));


            generationWrapper.offers.add(offer);
            generationWrappersByNegParty.put(contract.Negotiating_Party__c, generationWrapper);
            dataMigrationIndex++;
        }
        System.debug(Limits.getCpuTime());
        try {
            insertGenerationWrappers(generationWrappersByNegParty);
        } catch (Exception e) {
            Logger.error('Saving failed: ' + e.getMessage());
            Logger.saveLog('Offer Generation Dashboard');
            return false;
        }

        Logger.saveLog('Offer Generation Dashboard');
        return true;
    }

    private static String translateTechnology(String technology) {
        switch on technology {
            when 'Wind Offshore' {
                return 'Wind';
            }
            when 'Wind Onshore' {
                return 'Wind';
            }
            when 'Hydro' {
                return 'Hydro';
            }
            when 'Solar' {
                return 'Solar';
            }
            when else {
                return null;
            }
        }
    }

    private static Integer getDataMigrationId() {
        String prefix = 'Re-Neg' + Date.today().year() + '_';
        String prefixWithWildcard = prefix + '%';
        Integer lastIndex = 0;
        List<Offer__c> existingOffers = [SELECT Data_Migration_ID__c FROM Offer__c WHERE Data_Migration_ID__c LIKE :prefixWithWildcard];
        for (Offer__c offer : existingOffers) {
            Integer index = Integer.valueOf(offer.Data_Migration_ID__c.substring(offer.Data_Migration_ID__c.indexOf(prefix) + prefix.length()));
            if (index > lastIndex) {
                lastIndex = index;
            }
        }
        return lastIndex;
    }
    private static Map<Id, Pricing_Component__c> getPricingComponents(List<Id>contractIds, Map<Id, DataRow>contractIdToRow) {
        List<Pricing_Component__c> pricingComponents = [
                SELECT Id, Risk_Premium__c, Index_Price__c, X51_Compensation_3_1__c, X51_Compensation_4_2__c,
                        Settlement_Model__c, Shared_Meter__c, Settlement_SubModel__c, Meter_Billing_Type__c, Contract__c,
                        RecordType.DeveloperName, Billing_Model_Redispatch__c
                FROM Pricing_Component__c
                WHERE Contract__c IN:contractIds AND Active__c = TRUE
        ];

        Map<Id, Pricing_Component__c>contractIdToPC = new Map<Id, Pricing_Component__c>();
        for (Pricing_Component__c pc : pricingComponents) {
            DataRow row = contractIdToRow.get(pc.Contract__c);
            if ((row.productType == 'Fixed Price w/GOO' || row.productType == 'Fixed Price w/o GOO')
                    && pc.RecordType.DeveloperName == 'Fixed_Energy_Price') {
                contractIdToPC.put(pc.Contract__c, pc);
            } else if (row.productType != 'Fixed Price w/GOO' && row.productType != 'Fixed Price w/o GOO'
                    && pc.RecordType.DeveloperName == 'Floating_Energy_Price') {
                contractIdToPC.put(pc.Contract__c, pc);
            }

        }
        return contractIdToPC;
    }


    private static Map<Id, Meter__c> getMeters(List<Id>contractIds) {
        List<MeterRegistration__c> registrations = [
                SELECT Id, Contract__c, Meter__c
                FROM MeterRegistration__c
                WHERE Contract__c IN:contractIds AND Active__c = TRUE
        ];
        Map<Id, Id>meterIdToContractId = new Map<Id, Id>();
        List<Id> meterIds = new List<Id>();
        for (MeterRegistration__c tempRegistration : registrations) {
            meterIdToContractId.put(tempRegistration.Meter__c, tempRegistration.Contract__c);
            meterIds.add(tempRegistration.Meter__c);
        }
        List<Meter__c> meters = [
                SELECT Id, Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
                FROM Meter__c
                WHERE Id IN:meterIds
        ];

        Map<Id, Meter__c>contractIdToMeter = new Map<Id, Meter__c>();
        for (Meter__c meter : meters) {
            contractIdToMeter.put(meterIdToContractId.get(meter.Id), meter);
        }
        return contractIdToMeter;
    }
    private static Map<Id, Offer__c> getOldOffer(List<Id>contractIds) {
        List<Offer__c> offers = [
                SELECT Id, CreatedDate, Facility_Description__c, Resulting_Contract__c
                FROM Offer__c
                WHERE Resulting_Contract__c IN:contractIds AND Status__c = 'Closed Won'
        ];

        Map<Id, Offer__c>contractIdToOffer = new Map<Id, Offer__c>();
        for (Offer__c offer : offers) {
            Offer__c offerOld = contractIdToOffer.get(offer.Resulting_Contract__c);
            if (offerOld == null || offerOld.CreatedDate < offer.CreatedDate) {
                contractIdToOffer.put(offer.Resulting_Contract__c, offer);
            }
        }
        return contractIdToOffer;
    }

    private static Map<Id, SK_Security__c> getGuarantees(List<Id>contractIds) {
        List<SK_Security__c> guarantees = [
                SELECT Id, CreatedDate, SK_Contract__c, SK_End_Date__c, SK_Notional_Amount__c, SK_Guarantee_Record_Type__c
                FROM SK_Security__c
                WHERE SK_Contract__c IN:contractIds AND (SK_Status__c = 'Guarantee Issued' OR SK_Status__c = 'Expiring')
        ];

        Map<Id, SK_Security__c>contractIdToGuarantee = new Map<Id, SK_Security__c>();
        for (SK_Security__c guarantee : guarantees) {
            SK_Security__c guaranteeOld = contractIdToGuarantee.get(guarantee.SK_Contract__c);
            if (guaranteeOld == null || guaranteeOld.CreatedDate < guarantee.CreatedDate) {
                contractIdToGuarantee.put(guarantee.SK_Contract__c, guarantee);
            }
        }
        return contractIdToGuarantee;
    }
    private static Map<Id, Id> getBTR(List<Id>contractIds) {
        List<Site_Role__c> siteRoles = [
                SELECT Id, Account__c, Meter__r.Current_Contract__c
                FROM Site_Role__c
                WHERE Meter__r.Current_Contract__c IN:contractIds
                AND Account__c != NULL
                AND Role__c = 'BTR'
                AND Active__c = TRUE
        ];

        Map<Id, Id>contractIdToBTR = new Map<Id, Id>();
        for (Site_Role__c siteRole : siteRoles) {
            contractIdToBTR.put(siteRole.Meter__r.Current_Contract__c, siteRole.Account__c);
        }
        return contractIdToBTR;
    }


    public static void insertGenerationWrappers(Map<Id, OfferGenerationWrapper> generationWrappers) {
        List<List<OfferGenerationWrapper>> listContainer = new List<List<OfferGenerationWrapper>>();
        Integer batchSize = 20;

        Integer listCounter = 0;
        listContainer.add(new List<OfferGenerationWrapper>());
        for (Integer i = 0; i < generationWrappers.values().size(); i++) {
            if (i != 0 && Math.mod(i, batchSize) == 0) {
                listCounter++;
                listContainer.add(new List<OfferGenerationWrapper>());
            }
            listContainer[listCounter].add(generationWrappers.values()[i]);
        }
        String logId = Logger.getTransactionId();
        for (Integer i = 0; i < listContainer.size(); i++) {
            OfferGenerationDashboardController myBatchObject = new OfferGenerationDashboardController(listContainer.get(i), logId);
            Database.executeBatch(myBatchObject);
        }
    }


    List<OfferGenerationWrapper> listContainer;
    String parentLogId;
    public OfferGenerationDashboardController(List<OfferGenerationWrapper> listContainer, String logId) {
        this.listContainer = listContainer;
        this.parentLogId = logId;
    }
    public OfferGenerationDashboardController() {
    }

    public Iterable<SObject> start(Database.BatchableContext BC) {
        // To insert a lot of records, we use create multiple instances of this class.
        // We don't iterate over the following list. It is just a workaround to be able to use batch functionality
        List<SObject> dummyList = new List<SObject>();
        dummyList.add(new Offer__c());
        return dummyList;
    }

    public void execute(Database.BatchableContext param1, List<SObject> param2) {
        Logger.setParentLogTransactionId(this.parentLogId);
        Logger.info('Start Insertion for batch');

        for (OfferGenerationWrapper generationWrapper : listContainer) {
            fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();

            try {
                uow.registerNew(generationWrapper.opportunity);

                for (Offer__c offer : generationWrapper.offers) {
                    uow.registerNew(offer, Offer__c.Opportunity__c, generationWrapper.opportunity);

                    Contract__c baseContract = new Contract__c();
                    baseContract.Id = offer.Base_Contract__c;
                    baseContract.Offer_generated_for_Year__c = offer.Contract_Start_Date_Offer__c.year();
                    uow.registerDirty(baseContract);

                    Logger.info('Offer to be created for Contract: ' + offer.Base_Contract__c);
                }

                uow.commitWork();
                Logger.info('Creation of previous offers were successfull');
            } catch (Exception e) {
                Logger.error('Creation failed');
                Logger.error(e.getMessage());
            }
        }
        Logger.saveLog('Offer Generation Dashboard: Batch');
    }

    public void finish(Database.BatchableContext param1) {
    }


    public class fieldEntry {
        @AuraEnabled public String field { get; set; }
        @AuraEnabled public Integer numberOfRecords { get; set; }
    }
    global class OfferGenerationWrapper {
        @AuraEnabled public Opportunity opportunity { get; set; }
        @AuraEnabled public List<Offer__c> offers { get; set; }

    }
    global class DataCell {
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String valueLabel { get; set; }
        @AuraEnabled public Object value { get; set; }
    }
    global class DataRow {
        @AuraEnabled public List<DataCell> data { get; set; }
        @AuraEnabled public Boolean selected { get; set; }
        @AuraEnabled public Boolean show { get; set; }
        @AuraEnabled public String contractId { get; set; }
        @AuraEnabled public String ownerName { get; set; }
        @AuraEnabled public Contract__c contract { get; set; }
        @AuraEnabled public Boolean available { get; set; }
        @AuraEnabled public String search { get; set; }
        @AuraEnabled public Boolean changedStartDate { get; set; }
        @AuraEnabled public Boolean changedEndDate { get; set; }
        @AuraEnabled public Boolean changedWorkflowType { get; set; }
        @AuraEnabled public Boolean changedContractType { get; set; }
        @AuraEnabled public Boolean changedProductType { get; set; }
        @AuraEnabled public Date newOfferStartDate { get; set; }
        @AuraEnabled public Date newOfferEndDate { get; set; }
        @AuraEnabled public String workflowType { get; set; }
        @AuraEnabled public String productType { get; set; }
        @AuraEnabled public String contractType { get; set; }

        public DataRow() {
            data = new List<DataCell>();
            available = true;
            search = '';
            selected = false;
            changedStartDate = false;
            changedEndDate = false;
            changedWorkflowType = false;
            changedContractType = false;
            changedProductType = false;
            newOfferStartDate = Date.newInstance(Date.today().year() + 1, 1, 1);
            newOfferEndDate = Date.newInstance(Date.today().year() + 1, 12, 31);
        }
    }
    global class HeaderCell {
        @AuraEnabled public String label { get; set; }
    }
    global class PicklistOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        public PicklistOption(String labelIn, String valueIn) {
            label = labelIn;
            value = valueIn;
        }
    }
    global class ReportWrapper {
        @AuraEnabled public List<DataRow> data { get; set; }
        @AuraEnabled public List<HeaderCell> head { get; set; }
        @AuraEnabled public Date defaultStartDate { get; set; }
        @AuraEnabled public Date defaultEndDate { get; set; }
        @AuraEnabled public String defaultWorkflowType { get; set; }
        @AuraEnabled public String defaultProductType { get; set; }
        @AuraEnabled public String defaultContractType { get; set; }
        @AuraEnabled public List<PicklistOption> contractTypes { get; set; }
        @AuraEnabled public List<PicklistOption> workflowTypes { get; set; }
        @AuraEnabled public List<PicklistOption> productTypes { get; set; }

        public ReportWrapper() {
            head = new List<HeaderCell>();
            data = new List<DataRow>();
            defaultStartDate = Date.newInstance(Date.today().year() + 1, 1, 1);
            defaultEndDate = Date.newInstance(Date.today().year() + 1, 12, 31);

            contractTypes = new List<PicklistOption>();
            Schema.DescribeFieldResult contractTypesFieldResult = Contract__c.Contract_Type_New__c.getDescribe();
            for (Schema.PicklistEntry f : contractTypesFieldResult.getPicklistValues()) {
                contractTypes.add(new PicklistOption(f.getLabel(), f.getValue()));
            }
            defaultContractType = contractTypes[0].value;

            workflowTypes = new List<PicklistOption>();
            Schema.DescribeFieldResult workflowTypesFieldResult = Contract__c.Workflow_Type__c.getDescribe();
            for (Schema.PicklistEntry f : workflowTypesFieldResult.getPicklistValues()) {
                workflowTypes.add(new PicklistOption(f.getLabel(), f.getValue()));
            }
            defaultWorkflowType = 'Amendment';

            productTypes = new List<PicklistOption>();
            Schema.DescribeFieldResult productTypesFieldResult = Contract__c.Product_Type_New__c.getDescribe();
            for (Schema.PicklistEntry f : productTypesFieldResult.getPicklistValues()) {
                productTypes.add(new PicklistOption(f.getLabel(), f.getValue()));
            }
            defaultProductType = productTypes[0].value;
        }
    }
}