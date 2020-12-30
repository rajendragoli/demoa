@isTest
private class CloneOpportunityControllerTest {

    @testSetup
    static void setupTestData(){
        // Get the pricebook id
        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(
                Name = 'Product X',
                ProductCode = 'Pro-X',
                isActive = true
        );
        insert prod;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prod.Id,
                UnitPrice = 100.00,
                IsActive = true
        );
        insert pbEntry;

        //create account
        Account endUserAcc = new Account(Name = 'Test End User');
        insert endUserAcc;

        Opportunity opp = new Opportunity(Name = 'Test End User - test product - 1', AccountId = endUserAcc.Id,
                StageName = 'New', CloseDate = System.today().addDays(1));

        insert opp;

        //create your opportunity line item
        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 5,
                PricebookEntryId = pbEntry.Id,
                UnitPrice = pbEntry.UnitPrice

        );
        insert oli;
    }

    /**
     * Pass empty opportunity object to controller.  This will cause an exception when cloning
     */
    @isTest
    static void cloneOpportunityFields_Test_Fail(){
        system.assertEquals(1, [SELECT count() from opportunity]);
        Opportunity sourceOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Opportunity copyOpp = new Opportunity();
        Boolean errorThrown = false;

        Test.startTest();
        try {
            CloneOpportunityController.cloneOpportunityFields(sourceOpp.Id, JSON.serialize(copyOpp));
        }
        catch(AuraHandledException e) {
            errorThrown = true;
        }
        Test.stopTest();

        system.assertEquals(true, errorThrown);
        system.assertEquals(1, [SELECT count() from opportunity]);
    }

    @isTest
    static void cloneOpportunityFields_Test_Pass(){
        system.assertEquals(1, [SELECT count() from opportunity]);
        Opportunity sourceOpp = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity LIMIT 1];
        Opportunity copyOpp = sourceOpp.clone(false, true);
        copyOpp.StageName = 'Closed Won';

        Test.startTest();
        CloneOpportunityController.cloneOpportunityFields(sourceOpp.Id, JSON.serialize(copyOpp));
        Test.stopTest();

        system.assertEquals(2, [SELECT count() from opportunity]);
    }

    @isTest
    static void getOpportunityLineItems_Test(){
        Opportunity sourceOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityLineItem> queriedLines;
        Test.startTest();

        queriedLines = CloneOpportunityController.getOpportunityLineItems(sourceOpp.Id);

        Test.stopTest();

        system.assertEquals(1, queriedLines.size());
    }

    @isTest
    static void getFieldset_Test() {
        String jsonResult;

        Test.startTest();

        jsonResult = CloneOpportunityController.getFieldset();

        Test.stopTest();

        //assert > 2 chars because function wraps result in square brackets so there'll always be at least two
        system.assert(jsonResult.length() > 2);
    }

    @isTest
    static void translateType_Test(){
        List<Schema.DisplayType> apexTypeList = new List<Schema.DisplayType>{
                Schema.DisplayType.Boolean, Schema.DisplayType.Currency, Schema.DisplayType.Date,
                Schema.DisplayType.Email, Schema.DisplayType.Address, Schema.DisplayType.Integer,
                Schema.DisplayType.Percent, Schema.DisplayType.Phone, Schema.DisplayType.URL, Schema.DisplayType.Picklist
        };

        for(Schema.DisplayType apexType : apexTypeList){
            system.assertNotEquals(null, CloneOpportunityController.translateType(apexType));
        }
    }

    @isTest
    static void cloneOpportunityLineItems_Test() {
        Opportunity sourceOpp = [SELECT Id, AccountId, Name, CloseDate, StageName FROM Opportunity LIMIT 1];
        Opportunity copyOpp = sourceOpp.clone(false, true);
        copyOpp.StageName = 'Closed Won';

        insert copyOpp;

        List<OpportunityLineItem> sourceOppLines = [
                SELECT Id, Product2Id, UnitPrice, Quantity
                FROM OpportunityLineItem
                WHERE OpportunityId = :sourceOpp.Id
        ];

        List<OpportunityLineItem> changedLine = new List<OpportunityLineItem>{
                new OpportunityLineItem(
                        Id = sourceOppLines[0].Id,
                        Quantity = (sourceOppLines[0].Quantity + 1)
                )
        };

        Test.startTest();

        CloneOpportunityController.cloneOpportunityLineItems(sourceOpp.Id, copyOpp.Id, sourceOppLines, changedLine);

        Test.stopTest();

        List<OpportunityLineItem> clonedLines = [
                SELECT Id, Product2Id, UnitPrice, Quantity
                FROM OpportunityLineItem
                WHERE OpportunityId = :copyOpp.Id
        ];

        //re-query source lines because original list has been changed by cloneOpportunityLineItems call
        sourceOppLines = [
                SELECT Id, Product2Id, UnitPrice, Quantity
                FROM OpportunityLineItem
                WHERE OpportunityId = :sourceOpp.Id
        ];

        system.assertEquals(1, clonedLines.size());
        system.assertEquals(sourceOppLines[0].Product2Id, clonedLines[0].Product2Id);
        system.assertEquals(sourceOppLines[0].UnitPrice, clonedLines[0].UnitPrice);
        system.assertEquals((sourceOppLines[0].Quantity + 1), clonedLines[0].Quantity);
    }
}