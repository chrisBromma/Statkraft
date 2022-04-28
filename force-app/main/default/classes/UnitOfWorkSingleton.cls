public without sharing class UnitOfWorkSingleton {
    public static Map<String, fflib_SObjectUnitOfWork> instanceMap = new Map<String, fflib_SObjectUnitOfWork>();

    public static fflib_SObjectUnitOfWork getInstance(String instanceName) {
        if (instanceMap.get(instanceName) == null) {
            refreshInstance(instanceName);
        }
        return instanceMap.get(instanceName);
    }
    public static fflib_SObjectUnitOfWork getInstance() {
        return getInstance(null);
    }

    public static fflib_SObjectUnitOfWork refreshInstance(String instanceName) {
        fflib_SObjectUnitOfWork uowTemp = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();
        instanceMap.put(instanceName, uowTemp);
        return uowTemp;
    }
    public static fflib_SObjectUnitOfWork refreshInstance() {
        return refreshInstance(null);
    }
}