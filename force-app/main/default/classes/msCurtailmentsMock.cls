/****************************************************************************************************
* Class msCurtailmentsMock
*
*   Create By	:   FlorianPusse (mindsquare GmbH)
*   Create Date	:   FlorianPusse
*   Description	:	TODO: Insert Description
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * FlorianPusse (mindsquare GmbH)		28.03.2019       	Init version.
*****************************************************************************************************/

public with sharing class msCurtailmentsMock {

    public static String createCurtailments(String bodyString, Datetime now) {
        bodyString = bodyString.replaceAll('begin', 'begin2').replaceAll('end', 'end2');
        System.debug(bodyString);
        Body body = (Body) System.JSON.deserializeStrict(bodyString, Body.Class);


        List<TimeSeries> timeSeries = new List<TimeSeries>();
        for (String path : body.names) {
            TimeSeries tmpSerie = new TimeSeries();
            tmpSerie.name = path;
            tmpSerie.values = new List<TimeEntry>();

            for (Integer i = -50; i < 25; i++) {
                TimeEntry tmpEntry = new TimeEntry();

                if (i < 0) {
                    tmpEntry.timeDate = now.addMinutes((i * 15) - 504000);
                } else {
                    tmpEntry.timeDate = now.addMinutes(i * 15);
                }


                if (math.mod(i, 3) == 0) {
                    tmpEntry.value = 'NaN';
                } else {
                    if (i < 0)tmpEntry.value = '' + (i * -1); else
                            tmpEntry.value = '' + i;

                }

                tmpEntry.metadata = new TimeChangeData();
                tmpEntry.metadata.modifiedDate = now;
                tmpEntry.metadata.modifiedUser = 'Me';

                tmpSerie.values.add(tmpEntry);
            }

            timeSeries.add(tmpSerie);
        }

        return JSON.serialize(timeSeries).replaceAll('begin2', 'begin').replaceAll('end2', 'end');
    }


    public class TimeEntry {
        @AuraEnabled Public Datetime timeDate { get; set; }
        @AuraEnabled Public String value { get; set; }
        @AuraEnabled Public TimeChangeData metadata { get; set; }
    }
    public class TimeChangeData {
        @AuraEnabled Public String modifiedUser { get; set; }
        @AuraEnabled Public Datetime modifiedDate { get; set; }
    }
    public class TimeSeries {
        @AuraEnabled Public String name { get; set; }
        @AuraEnabled Public List<TimeEntry> values { get; set; }
    }
    public class Body {
        @AuraEnabled Public List<String> names { get; set; }
        @AuraEnabled Public Datetime begin2 { get; set; }
        @AuraEnabled Public Datetime end2 { get; set; }
    }

}