public class Practice{
//Method to update lead call attempts when task status is changed to completed
public static void updateLeadCallAttemptonComplete(List<Task> InitialTaskCompleted) {
List<Lead> leadsToBeUpdatedonInitial = new List<Lead>();
List<Lead> leadsToBeUpdatedonAttempt2 = new List<Lead>();
List<Lead> leadsToBeUpdatedonAttempt3 = new List<Lead>();
List<Lead> leadsToBeUpdatedonAttempt4 = new List<Lead>();
List<Lead> leadsToBeUpdatedonAttempt5 = new List<Lead>();
Set<Id> leadIds = new Set<Id>();
//Collect all lead where Task is completed and Subject is Initial Task
for(Task t : InitialTaskCompleted) {
if(t.Subject == 'Call Attempt 1' && t.Status == 'Completed') {
leadIds.add(t.whoId);
}else if(t.Subject == 'Call Attempt 2' && t.Status == 'Completed') {
leadIds.add(t.whoId);
}else if(t.Subject == 'Call Attempt 3' && t.Status == 'Completed') {
leadIds.add(t.whoId);
}else if(t.Subject == 'Call Attempt 4' && t.Status == 'Completed') {
leadIds.add(t.whoId);
}else if(t.Subject == 'Call Attempt 5' && t.Status == 'Completed') {
leadIds.add(t.whoId);
}
}
//Create a lead list with only those leads which are not contacted before
leadsToBeUpdatedonInitial = [Select Id, Status from Lead where Id in :leadIds AND Status = 'Open - Not Contacted' AND Call_Attempt__c = 'None'];
leadsToBeUpdatedonAttempt2 = [Select Id, Status from Lead where Id in :leadIds AND Status = 'Open - Not Contacted' AND Call_Attempt__c = 'Call Attempt 1'];
leadsToBeUpdatedonAttempt3 = [Select Id, Status from Lead where Id in :leadIds AND Status = 'Open - Not Contacted' AND Call_Attempt__c = 'Call Attempt 2'];
leadsToBeUpdatedonAttempt4 = [Select Id, Status from Lead where Id in :leadIds AND Status = 'Open - Not Contacted' AND Call_Attempt__c = 'Call Attempt 3'];
leadsToBeUpdatedonAttempt5 = [Select Id, Status from Lead where Id in :leadIds AND Status = 'Open - Not Contacted' AND Call_Attempt__c = 'Call Attempt 4'];
    
//Update all the lead to call attempt 1
for(Lead l : leadsToBeUpdatedonInitial) {
l.Call_Attempt__c = 'Call Attempt 1';
}
    for(lead l : leadsToBeUpdatedonAttempt2) {
        l.Call_Attempt__c = 'Call Attempt 2';
    }
    for(lead l : leadsToBeUpdatedonAttempt3) {
        l.Call_Attempt__c = 'Call Attempt 3';
    }
    for(lead l : leadsToBeUpdatedonAttempt4) {
        l.Call_Attempt__c = 'Call Attempt 4';
    }
    for(lead l : leadsToBeUpdatedonAttempt5) {
        l.Call_Attempt__c = 'Call Attempt 5';
    }
Update leadsToBeUpdatedonInitial;
Update leadsToBeUpdatedonAttempt2;
Update leadsToBeUpdatedonAttempt3;
Update leadsToBeUpdatedonAttempt4;
Update leadsToBeUpdatedonAttempt5;
}
}