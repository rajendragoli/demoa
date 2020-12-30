public with sharing class trysobj {
    public void updateRecord(Id recordId, String fieldName, Object newFieldValue) {
        sObject sObj = recordId.getSobjectType().newSObject(recordId);
        system.debug('Before updating record is: ' +sObj);
        sObj.put(fieldName, newFieldValue);
        Update sObj;
        system.debug('Updated Record is:' +sObj);
    }
}