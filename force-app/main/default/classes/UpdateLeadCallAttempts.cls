public class UpdateLeadCallAttempts {
//Method to update lead call attempts when task status is changed to completed
public static void updateLeadCallAttemptonComplete(List<Task> InitialTaskCompleted) {
List<Lead> leadsToBeUpdatedonInitial = new List<Lead>();
Set<Id> leadIds = new Set<Id>();
//Collect all lead where Task is completed and Subject is Initial Task
for(Task t : InitialTaskCompleted) {
if(t.Subject == 'Initial Task' && t.Status == 'Completed') {
leadIds.add(t.whoId);
}
}
//Create a lead list with only those leads which are not contacted before
leadsToBeUpdatedonInitial = [Select Id, Status from Lead where Id in :leadIds AND Status = 'Open - Not Contacted'];
//Update all the lead to call attempt 1
for(Lead l : leadsToBeUpdatedonInitial) {
l.Call_Attempt__c = 'Call Attempt 1';
}
Update leadsToBeUpdatedonInitial;
}
}