/**
 * Created by ChristianGottlieb on 20.02.2019.
 */

public without sharing class msSessionLoaderCmpController {
    @AuraEnabled
    public static Object getUserDetails(String portal) {
        try {
            Cache.Session.remove('local.PortalCache.userDetails');
        } catch (Cache.Session.SessionCacheException e) {
            System.debug(e.getMessage());
        }
        if(portal=='Customer Portal'){
            return msUtility.getUserDetails();
        }else if(portal=='Bryt'){
            return msBrytUtility.getUserDetails();
        }else{
            return null;
        }
    }
}