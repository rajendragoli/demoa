public with sharing class ptPicklistRet {
    @AuraEnabled
    public static List<Patients__c > getPtTypes(){
        return [Select Id, Pt_Picklist__c FROM Patients__c ];
    }
}