// Class to receive SMS in Salesforce and save it as an Activity on Contact. I have kept
// this code simple as we just want to focus on how to receive SMS in Salesforce
// In an actual implmentation you would want to think about the following also
// 1. Ensure that the incoming SMSes are from an authorized system
// 2. Add error handling if the contact is not found based on the phone number
@RestResource(urlMapping='/receiveSMS/*')
global class receiveSMS {
    @HttpGet
    global static void saveSMS() {

       // Store the request received
       RestRequest req = RestContext.request;
       
       // Store the HTTP parameters received in a Map
       Map<String, String> smsParams = req.params ;
 
       String fromMobile ;
       String msgBody ;
       Contact contactRecord;
       
       // Extract SMS Sender's phone number and store it in a variable
       if (smsParams.containsKey('From')){
           fromMobile = smsParams.get('From') ;
       }

       // Extract the body of SMS and store it in a variable
       if (smsParams.containsKey('Body')){
          msgBody = smsParams.get('Body') ;
       }

       // Identify the contact based on Sender's phone number
       contactRecord = [Select Id from Contact where MobilePhone = :fromMobile LIMIT 1];
       
       // Create an Activity record on Contact            
       Task newTask = new Task();
       newTask.WhoId = contactRecord.Id ;
       newTask.Subject = 'SMS Received';
       newTask.priority= 'Normal' ;
       newTask.status = 'Completed';
       newTask.description = msgBody ;
       newTask.ActivityDate = System.today() ;
       insert newtask;
       
       // Set the response values for Web Service
       RestContext.response.statusCode = 200;
       RestContext.response.addHeader('Content-Type', 'text/plain');
       RestContext.response.responseBody = Blob.valueOf('Thanks, We have received your SMS and will get back to you soon') ;
    }
}