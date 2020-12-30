trigger DoNotDeleteAccountHavingRelatedContact on Account (before delete)  
{  
    List<Account> accList = new List<Account>();  
    Set<id> accIdSet = new Set<id>();  
    for(Account acc : Trigger.old)  
    {  
        accIdSet.add(acc.id);  
    }  

    Map<Id, Account> accts = new Map<Id, Account>([Select Id, (Select Id from Opportunities where StageName != 'Close Won') from Account where id in :accIdSet]);

    for(Account acc : Trigger.old)
    {
        if(accts.get(acc.id).contacts.size()>0)
        {
            acc.adderror('Account cannot be deleted');
            }
        }                                       

}