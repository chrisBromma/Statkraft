/**
 * Created by Fabian on 08.01.2019.
 */

public with sharing class msBrytHowDoYouStackUpBEC {

    @AuraEnabled
    public static List<Pricing_Component__c> getPc(String selectedContract) {
        List<Pricing_Component__c> pc = new List<Pricing_Component__c>();
        msBrytUtility.checkObjectAccess(selectedContract);
        pc = msBrytWhatYouHaveDoneBackendController.queryPricingComponents(selectedContract);

        return pc;
    }

    @AuraEnabled
    public static List<Object> getSeriesForChart(String [] selectedProduct, String startDate, String endDate) {
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        Integer length = selectedProduct.size();
        if (length > 40) {
            length = 40;
        }
        String products = '';
        for (Integer i = 0; i <= length - 1; i++) {
            String tmp = selectedProduct[i];
            tmp = tmp.replace(' ', '_').toLowerCase();
            if (tmp.length() == 4) {
                tmp = tmp.substring(2, 4);
                tmp = 'cal_' + tmp;
            }
            String p = '"' + apiSettings.BrytHowDoYouStackUpPath__c + tmp + '_base",';
            products = products + p;
        }

        // probably wrong
        startDate = startDate.substring(0, 19);
        endDate = endDate.substring(0, 19);
        String beginS = '"begin": "' + startDate + 'Z",';
        String endS = '"end": "' + endDate + 'Z"';

        String endpoint = apiSettings.Time_Series_Endpoint_Read__c;
        String body = '{"names":[' + products + '],' + beginS + endS + '}';
        String method = 'POST';
        HttpResponse response = msUtility.getHttp(endpoint, body, method);
        if (response.getStatus() == 'OK' && response.getStatusCode() == 200) {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
            return results;
        } else {
            return new List<Object>();
            //throw new AuraHandledException('Something went wrong: error code '+response.getStatusCode()+' | ' +response.getBody());
        }
    }
    @AuraEnabled
    public static Wrapper getWrapper(String selectedContract, String[] selectedProduct, String startDate, String endDate) {
        Wrapper wrapper = new Wrapper();
        msBrytUtility.checkObjectAccess(selectedContract);

        List<Object> api = new List<Object>();
        api.add(getSeriesForChart (selectedProduct, startDate, endDate));
        wrapper.api = api;
        List<Object> pc = new List<Object>();
        pc.add(getPc(selectedContract));
        wrapper.pc = pc;

        return wrapper;
    }
    public class Wrapper {
        @AuraEnabled public List<Object> pc { get; set; }
        @AuraEnabled public List<Object> api { get; set; }
    }
}