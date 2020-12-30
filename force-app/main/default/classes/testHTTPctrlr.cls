public class testHTTPctrlr {
    public testHTTPctrlr (){
        //HTTP Request Class
        HTTPRequest reqParam = New HTTPRequest();
        reqParam.setEndpoint(Label.testCalloutEndPoint);
        reqParam.setMethod('GET');
        
        //HTTP Response Class
        HTTP resParam = New HTTP();
		HTTPResponse response = resParam.send(reqParam);
        String strResponse = response.getBody();
        System.debug('Service Response is ---------->'+strResponse);
        
        lstWL = new List<wrapLeads>();
        
        //JSON Parsing
        JSONParser parsing = JSON.createParser(strResponse);
        
        List<String> LeadIds = new List<String>();
         while (parsing.nextToken() != null) {
            if ((parsing.getCurrentToken() == JSONToken.FIELD_NAME) && (parsing.getText() == 'id')) {
                // Get the value.
                parsing.nextToken();
                LeadIds.add(parsing.getText());
            }
            }
    }
    Public wrapLeads objWL{get;set;}
    Public List<wrapLeads> lstWL{get;set;}
    Public class wrapLeads{
        public string id{get;set;}
        public string name{get;set;}
        public string email{get;set;}
        public string address{get;set;}
        public string gender{get;set;}
        public string mobile{get;set;}
        
    }
}