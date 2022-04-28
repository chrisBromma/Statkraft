/**
 * Created by u52448 on 23.02.2021.
 */

@isTest
global class MockMastrWebService implements WebServiceMock {

    Boolean isValidMastrId;
    global MockMastrWebService(Boolean isValidMastrId){
        this.isValidMastrId = isValidMastrId;
    }

    global void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {

        if (soapAction == 'GetEinheitSolar') {
            msSolarOnboardingMastrSoapService.GetEinheitSolarAntwort solarPlant = new msSolarOnboardingMastrSoapService.GetEinheitSolarAntwort();
            if(isValidMastrId){
                solarPlant.EinheitBetriebsstatus = 'inBetrieb';
                solarPlant.EinheitMastrNummer = 'SEE906895175599';
                solarPlant.NameStromerzeugungseinheit ='Mühlplatz_Test';
                solarPlant.Bruttoleistung = '20.52';
                solarPlant.HauptausrichtungNeigungswinkel = 'Grad20Bis40';
                solarPlant.Hauptausrichtung = 'Sued';
                solarPlant.Inbetriebnahmedatum = Date.valueOf('2008-02-15T00:00:00.000Z');
                solarPlant.Strasse='';
                solarPlant.Postleitzahl='06618';
                solarPlant.Ort='Naumburg';
                solarPlant.Bundesland='SachsenAnhalt';
                solarPlant.Land='Deutschland';
                solarPlant.Laengengrad=0;
                solarPlant.Breitengrad=0;
                response.put('response_x', solarPlant);
            }
            else{
                solarPlant = null;
            }
        }

        if (soapAction ==  'GetAnlageEegSolar') {
            msSolarOnboardingMastrSoapService.GetAnlageEegSolarAntwort eeg_response_x = new msSolarOnboardingMastrSoapService.GetAnlageEegSolarAntwort();
            if(isValidMastrId){
                eeg_response_x.AnlagenschluesselEeg = 'E4048801EE00158000700101009999001';
                response.put('response_x', eeg_response_x);
            }
            else{
                eeg_response_x = null;
            }
        }

        if (soapAction ==  'GetLokationStromErzeuger') {
            msSolarOnboardingMastrSoapService.GetLokationStromErzeugerAntwort location_response_x = new msSolarOnboardingMastrSoapService.GetLokationStromErzeugerAntwort();
            if(isValidMastrId){
                location_response_x.Netzanschlusspunkte = null;
                response.put('response_x', location_response_x);
            }
            else{
                location_response_x = null;
            }
        }
    }
}