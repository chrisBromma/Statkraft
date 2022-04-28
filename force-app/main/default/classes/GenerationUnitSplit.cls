/**
 * Created by Steffen Naundorf on 13.08.2021.
 */

global without sharing class GenerationUnitSplit {
    public class FlowInputs {
        @InvocableVariable
        public String meterId;
    }

    @InvocableMethod
    public static void splitGenerationUnits(List<FlowInputs> request) {
                String meterId = request[0].meterId; //If you enter a meterId in the first line, it works only for this meter, if you don’t provide a meterId it runs for all irish meters (ofthe mentioned contracts)
        fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();
        Date today = Date.today();

        List<Meter2GenerationUnitRelationship__c>m2gs = [
                SELECT id, name, currencyisocode, meter__c, active__c, annual_production__c, country__c, generator_unit__c, installed_capacity__c, locked__c, valid_from__c, Meter__r.Name
                FROM Meter2GenerationUnitRelationship__c
                WHERE Meter__c = :meterId AND (
                        Valid_to__c >= :today
                        OR Valid_to__c = NULL
                )
                AND Generator_Unit__r.Number_of_Generators__c > 1
        ];

        Map<Id, Meter2GenerationUnitRelationship__c> guToM2G = new Map<Id, Meter2GenerationUnitRelationship__c>();
        Map<Id, Integer>numberOfGUPerMeter=new Map<Id, Integer>();
        Map<Id, Integer>nameIndexOfGU=new Map<Id, Integer>();

        for (Meter2GenerationUnitRelationship__c m2g : m2gs) {
            guToM2G.put(m2g.Generator_Unit__c, m2g);

            Integer numberOfGU=numberOfGUPerMeter.get(m2g.Meter__c);
            if(numberOfGU==null)numberOfGU=0;
            numberOfGU++;
            numberOfGUPerMeter.put(m2g.Meter__c, numberOfGU);
            nameIndexOfGU.put(m2g.Generator_Unit__c, numberOfGU);
        }

        List<Generation_Unit__c>gus = [
                SELECT id, name, currencyisocode, recordtypeid, annual_production__c, commissioning_date__c, country__c, current_meter__c, data_migration_id__c, description__c, efficiency__c, facility_type__c, gps_location__latitude__s, gps_location__longitude__s, gps_location__c, generator_type__c, installed_capacity__c, locked__c, manufacturer_number__c, maximum_daily_export__c, module_inclination__c, module_orientation__c, module_tracking__c, number_of_generators__c, power_reduction_period__c, power_reduction_remaining_capacity__c, remote_control_solution__c, remuneration_date__c, remuneration_details__c, site_location_city__c, site_location_country__c, site_location_county__c, site_location_postcode__c, site_location_street__c, solar_manufacturer__c, status__c, storage_capacity__c, subsidy_scheme__c, annual_reference_production__c, feed_in_tariff__c, generator_model__c, hub_height__c, lastsubmetervaluesmonthly__c, lastsubmetervaluesyearly__c, manufacturer__c, minimum_loadminimum_load__c, parasitic_load__c, portfolio_id__c, regulated_capacity__c, rotor_diameter__c, virtual_power_plant_date__c, p51_relevant__c, vpp_control_mode__c, daily_generation_limit__c, import_capacity__c, cert_of_structural_safety_valid_until__c, control_guard_treshold__c, downgrading_costs__c, p_rl_max__c, eeg_eligibility_start__c, in_operation__c, radio_receiver_installed__c, tr_id__c, mastr_id__c
                FROM Generation_Unit__c
                WHERE ID IN:guToM2G.keySet()
        ];

        for (Generation_Unit__c gu : gus) {
            Meter2GenerationUnitRelationship__c m2g = guToM2G.get(gu.Id);
            Decimal annualProductionRemaining = gu.Annual_Production__c;

            String namePrefix='';
            if(numberOfGUPerMeter.get(m2g.Meter__c)>1){
                namePrefix=nameIndexOfGU.get(gu.Id)+'.';
            }

            for (Integer i = 1; i < gu.Number_of_Generators__c; i++) {
                Generation_Unit__c newGu = gu.clone(false, true, false, false);
                newGu.Installed_Capacity__c = (gu.Installed_Capacity__c / gu.Number_of_Generators__c).setScale(5);
                newGu.Name = guToM2G.get(gu.Id).Meter__r.Name + ' Generation Unit ' + namePrefix+(i + 1);
                newGu.Portfolio_ID__c = null;
                newGu.Number_of_Generators__c = 1;
                newGu.Unit_ID__c=newGu.Name;

                Meter2GenerationUnitRelationship__c newM2g = guToM2G.get(gu.Id).clone(false, true, false, false);
                newM2g.Installed_Capacity__c = newGu.Installed_Capacity__c;
                newM2g.Valid_to__c = null;
                newM2g.Name = newGu.Name + ' #' + newM2g.Valid_from__c.format();

                if (annualProductionRemaining != null) {
                    newGu.Annual_Production__c = (gu.Annual_Production__c / gu.Number_of_Generators__c).setScale(4);
                    newM2g.Annual_Production__c = newGu.Annual_Production__c;
                    annualProductionRemaining = annualProductionRemaining - newGu.Annual_Production__c;
                }

                uow.registerNew(newGu);
                uow.registerNew(newM2g, Meter2GenerationUnitRelationship__c.Generator_Unit__c, newGu);
            }
            gu.Installed_Capacity__c = (gu.Installed_Capacity__c / gu.Number_of_Generators__c).setScale(5);
            gu.Name = guToM2G.get(gu.Id).Meter__r.Name + ' Generation Unit '+namePrefix+'1';
            gu.Number_of_Generators__c = 1;
            gu.Unit_ID__c=gu.Name;

            m2g.Installed_Capacity__c = gu.Installed_Capacity__c;
            m2g.Name = guToM2G.get(gu.Id).Meter__r.Name + ' Generation Unit '+namePrefix+'1 #' + m2g.Valid_from__c.format();
            m2g.Valid_to__c = null;
            if (annualProductionRemaining != null) {
                gu.Annual_Production__c = annualProductionRemaining;
                m2g.Annual_Production__c = gu.Annual_Production__c;
            }
            uow.registerUpsert(gu);
            uow.registerUpsert(m2g);

        }
        uow.commitWork();
    }
}