public class getContacts {
    public static List<Contact> getContactsList() { 
        List<Contact> somelist = [Select Id, Name FROM Contact];
        return somelist;
    }
}