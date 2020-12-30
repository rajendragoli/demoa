public with sharing class Pagination {


    Public Integer noOfRecords{get; set;}
    Public Integer size{get;set;}    
    public Integer inputText1{get;set;}
    
    public ApexPages.StandardSetController setCon {
    
        get{
            if(setCon == null){
            
                size = 20;
                string queryString = 'Select Id, Name, LastActivityDate, CreatedDate from Lead where LastActivityDate >=NEXT_N_DAYS:5';
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
           
        }set;  
    }
 
   
    
    Public List<Lead> getLeads(){
        List<Lead> leadList = new List<Lead>();
        for(Lead L : (List<Lead>)setCon.getRecords())
            leadList.add(L);
        return leadList;
    }
     
    public pageReference refresh() {
        setCon = null;
        getLeads();
        setCon.setPageNumber(1);
        return null;
    }
     
    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }
  
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
  
    public void first() {
        setCon.first();
    }
  
    public void last() {
        setCon.last();
    }
  
    public void previous() {
        setCon.previous();
    }
  
    public void next() {
        setCon.next();
    }
}