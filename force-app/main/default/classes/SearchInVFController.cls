public class SearchInVFController {
    public list <Account> acc {get;set;}
    public String searchKey {get;set;}
    public SearchInVFController( ) {
    }

    public void search(){
        string searchquery='select Name,id from account where name like \'%'+searchKey+'%\' Limit 10';
        acc= Database.query(searchquery);
    }

    public void clear(){
        acc.clear();
    }
}