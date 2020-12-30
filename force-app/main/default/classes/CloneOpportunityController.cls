public class CloneOpportunityController {

    /**
     * Build a query of createable fields and clone opportunity, then return unsaved clone to component
     * @param opportunityId : Opportunity Id to clone
     * @param fieldsJson : Values of fields as inputted by the user
     * @return String : Id of the cloned opp
     * */
    @AuraEnabled
    public static String cloneOpportunityFields(String opportunityId, String opportunityJson) {
        Opportunity clonedOppValues = (Opportunity)JSON.deserialize(opportunityJson, Opportunity.class);
        Map<String, Object> fieldsToValue = clonedOppValues.getPopulatedFieldsAsMap();
        String opportunityQuery = 'SELECT Id, ';

        if(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().size() > 1) {
            opportunityQuery += 'RecordTypeId, ';
        }

        //query all the fields in the page layout the user has filled out
        for( String fieldName : fieldsToValue.keySet() ) {
            if(!opportunityQuery.containsIgnoreCase(fieldName)) {
                opportunityQuery += fieldName + ', ';
            }
        }
        opportunityQuery = opportunityQuery.removeEnd(', ');

        opportunityQuery += ' FROM Opportunity WHERE Id = :opportunityId';
        //get and clone the opp so we can use getCloneSourceId and isClone on the new opp
        Opportunity originalOpp = Database.query(opportunityQuery);
        Opportunity newOpp = originalOpp.clone(false, true);

        //apply new field values to cloned opportunity
        for( String fieldName : fieldsToValue.keySet() ) {
            newOpp.put(fieldName, fieldsToValue.get(fieldName));
        }

        try {
            insert newOpp;
        }catch(Exception e){
            throwException(e.getMessage());
        }

        return newOpp.Id;
    }

    /**
     * Query opportunity line fields based on a fieldset, plus required fields we explicitly set
     * @param opportunityId : Opportunity Id which is the source for the lines
     * */
    @AuraEnabled
    public static List<OpportunityLineItem> getOpportunityLineItems(String opportunityId) {
        List<String> requiredSoqlFields = new List<String>{
                'Id', 'Product2Id', 'Product2.Name', 'PriceBookEntryId'
        };
        List<OpportunityLineItem> lstClonedLineItems = new List<OpportunityLineItem>();
        String lineItemQuery = 'SELECT ';

        //Get lines to query from the fieldset, unless it's in our required list, which we'll add later
        for (Schema.FieldSetMember f : SObjectType.OpportunityLineItem.FieldSets.Clone_Opportunity_Editable_Field_Set.getFields()) {
            if (!requiredSoqlFields.contains(f.getFieldPath())) {
                lineItemQuery += f.getFieldPath() + ', ';
            }
        }

        //Add in fields we require
        lineItemQuery += String.join(requiredSoqlFields, ',');
        lineItemQuery += ' FROM OpportunityLineItem WHERE OpportunityId = :opportunityId ORDER BY SortOrder';

        try {
            lstClonedLineItems = Database.query(lineItemQuery);
        }catch(Exception e){
            throwException('Error getting products: ' + e.getMessage());
        }

        return lstClonedLineItems;
    }

    /**
     * Generate all the details required by a lightning:datatable to display the columns in our fieldset, and pass it back jsonified
     * */
    @AuraEnabled
    public static String getFieldset(){
        Schema.DescribeSObjectResult res = OpportunityLineItem.sObjectType.getDescribe();

        String columnsJsonString = '';
        for (Schema.FieldSetMember f : SObjectType.OpportunityLineItem.FieldSets.Clone_Opportunity_Editable_Field_Set.getFields()) {
            if(f.getType() == Schema.DisplayType.Reference) {
                throwException('Fieldset error: Reference fields are incompatible.  Please remove or replace with a forumla');
            }
            String jsonPart = '{';
            jsonPart += '"label":"' + f.getLabel() + '",';
            jsonPart += '"type":"' + translateType(f.getType()) + '",';
            jsonPart += '"fieldName":"' + f.getFieldPath() + '"';
            if(res.fields.getMap().get(f.getFieldPath()).getDescribe().isCreateable()){
                jsonPart += ',"editable": "true"';
            }
            jsonPart += '},';
            columnsJsonString += jsonPart;
        }
        columnsJsonString = columnsJsonString.removeEnd(',');

        return '['+columnsJsonString+']';
    }

    /**
     * The type returned in a describe call doesn't match the allowed
     * values in Lightning Datatable column definitions, so translate them
     */
    @testVisible
    private static String translateType(Schema.DisplayType apexType){
        String ltngType;
        switch on apexType {
            when Boolean {
                ltngType = 'boolean';
            }
            when Currency {
                ltngType = 'currency';
            }
            when Date, DateTime, Time {
                ltngType = 'date';
            }
            when Email {
                ltngType = 'email';
            }
            when Address {
                ltngType = 'location';
            }
            when Integer, Double, Long {
                ltngType = 'number';
            }
            when Percent {
                ltngType = 'percent';
            }
            when Phone {
                ltngType = 'phone';
            }
            when URL {
                ltngType = 'url';
            }
            when else {
                ltngType = 'text';
            }
        }
        return ltngType;
    }

    /**
     * Clone opportunity line items, set values given in the datatable and attach to cloned opp
     * @param sourceOppId : Opportunity Id which is the source for cloning
     * @param clonedOppId : Opportunity Id we have already cloned, to attach lines to
     * @param lstLineItems : Products which are going to be cloned
     * @param changes : Changes to existing lines
     * */
    @AuraEnabled
    public static void cloneOpportunityLineItems( Id sourceOppId, Id clonedOppId, List<OpportunityLineItem>  lstLineItems, List<OpportunityLineItem>  changes ){
        SavePoint sp = Database.setSavepoint();
        Map<Id, OpportunityLineItem> changesMap = new Map<Id, OpportunityLineItem>();
        if(changes != null){
            changesMap.putAll(changes);
        }

        try {
            //update original lines with inline changes.
            //loop over changed fields and apply them to original lines
            for(OpportunityLineItem oli : lstLineItems){
                if(changesMap.containsKey(oli.Id)) {
                    //line has been changed in some way
                    OpportunityLineItem changedLine = changesMap.get(oli.Id);
                    //splits object into map of fieldName => fieldValue.
                    Map<String, Object> fieldsToValue = changedLine.getPopulatedFieldsAsMap();
                    for (String fieldName : fieldsToValue.keySet()) {
                        oli.put(fieldName, fieldsToValue.get(fieldName));
                    }
                }
            }

            // Query the opportunity line item fields from fieldset
            Set<String> setOpportunityProductFields = new Set<String>();
            Map<String, Schema.SObjectField> mapOpportunityProductFields = Schema.SObjectType.OpportunityLineItem.fields.getMap();
            for( Schema.FieldSetMember f : SObjectType.OpportunityLineItem.FieldSets.Clone_Opportunity_Field_Set.getFields() ) {
                if( mapOpportunityProductFields.get( f.getFieldPath() ).getDescribe().isCreateable() ) // Check if this field is createable for this user
                    setOpportunityProductFields.add( f.getFieldPath().toLowerCase() );
            }

            // manually add product2Id and PriceBookEntry fields
            setOpportunityProductFields.add( 'product2id' );
            setOpportunityProductFields.add( 'pricebookentryid' );

            // Check for the required fields on opportunity line item object
            // if they are not the part of the fieldset then add them in query explicitly
            for( String fieldName : mapOpportunityProductFields.keySet() ){
                Schema.DescribeFieldResult desribeResult = mapOpportunityProductFields.get( fieldName ).getDescribe();
                if( desribeResult.isCreateable() &&
                        !desribeResult.isNillable() &&
                        !desribeResult.isDefaultedOnCreate() &&
                        !setOpportunityProductFields.contains( fieldName.toLowerCase() ) ) { // Check if field is required and not a part of fieldset

                    setOpportunityProductFields.add( fieldName ); // Add to the query field list
                }
            }

            // Construct dynamic query from the fetched fields
            String queryForOppLineItem = 'SELECT ' + String.join( new List<String>(setOpportunityProductFields), ', ' ) +
                                            ' FROM OpportunityLineItem WHERE OpportunityId = \'' + sourceOppId + '\'';

            List<OpportunityLineItem> sourceOppLineItems = Database.query( queryForOppLineItem );

            // Create a map of OpportunityLineItem objects so we can get its fields
            Map<Id, OpportunityLineItem> mapOpportunityLineItems = new Map<Id, OpportunityLineItem>(lstLineItems);

            // Clone all the related opportunity products
            Schema.DescribeSObjectResult res = OpportunityLineItem.sObjectType.getDescribe();
            List<OpportunityLineItem> clonedOppLineItems = new List<OpportunityLineItem>();
            for( OpportunityLineItem oli : sourceOppLineItems ) {
                //only add lines we have in our map from the datatable - don't want to clone deleted lines
                if( mapOpportunityLineItems.containsKey( oli.Id ) ) {
                    OpportunityLineItem clonedOli = oli.clone( false, true, false, false );
                    clonedOli.OpportunityId = clonedOppId;

                    OpportunityLineItem changedLine = mapOpportunityLineItems.get(oli.Id);

                    Map<String, Object> fieldsToValue = changedLine.getPopulatedFieldsAsMap();
                    for (String fieldName : fieldsToValue.keySet()) {
                        if(res.fields.getMap().get(fieldName) != null && res.fields.getMap().get(fieldName).getDescribe().isCreateable()){
                            clonedOli.put(fieldName, fieldsToValue.get(fieldName));
                        }
                    }

                    clonedOppLineItems.add( clonedOli );
                }
            }

            insert clonedOppLineItems;
        }catch(Exception e) {
            Database.rollback(sp);
            throwException('Error cloning: ' + e.getMessage());
        }
    }

    /**
     * Throwing an AuraHandledException is good for Lightning but not for debugging and testing since
     * logs only show "Script-thrown Exception" instead of real exception message.
     * Fix this by manually setting the message to match that of the exception.
     *
     * @param message exception message to throw
     */
    private static void throwException(String message){
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        throw ahe;
    }
}