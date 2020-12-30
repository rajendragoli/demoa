public class ForeandBackgroundAction {

@AuraEnabled
    public static string getAccount()
    {
    String accName = ([SELECT Id, Name from Account Limit 1].size()!=0)? [SELECT Id, Name from Account Limit 1].name: 'No records found on Account Obj';
    return accName;
    }
    
@AuraEnabled
    public static string getContact()
    {
    String conLastName = ([SELECT Id, Name from Contact where Lastname!=null Limit 1].size()!=0)? [SELECT Id, Lastname from Contact where Lastname!=null Limit 1].Lastname: 'No records found on Contact Obj';
    return conLastName;
    }    
    
}