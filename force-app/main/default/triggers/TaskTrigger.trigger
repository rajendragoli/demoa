//Trigger to execute after update
trigger TaskTrigger on Task (after update) {
if(Trigger.isAfter){
if(Trigger.isUpdate){
Practice.updateLeadCallAttemptonComplete(Trigger.New);
}
}
}