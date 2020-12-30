({
    /**
     * Prevent the event to override standard Save.
     * We don't want to edit this record
     * we want to perform an sobject clone
     * */
    createOpportunity : function(cmp, event, helper) {
        cmp.set("v.loading", true);
        event.preventDefault();
        var fields = event.getParam("fields");

        //pass populated field values to controller
        let action = cmp.get("c.cloneOpportunityFields");
        action.setParams({
            opportunityId: cmp.get("v.recordId"),
            opportunityJson: JSON.stringify(fields)
        });
        action.setCallback( this, function( response ) {
            cmp.set("v.loading", false);
            let state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.oppCreated', true);
                cmp.set('v.clonedOppId', response.getReturnValue());

                //get lines and populate table
                helper.getColumns(cmp);
                helper.getLineItems(cmp);
            }
            else if (state === "INCOMPLETE") {
                helper.handleErrors([{message: 'network error getting opportunity lines'}], cmp);
            }
            else if (state === "ERROR") {
                helper.handleErrors(response.getError(), cmp, 'info');
            }
        } );

        $A.enqueueAction(action);
    },

    /**
     * Perform selected action on row
     * */
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'delete':
                var rows = cmp.get('v.lstLineItems');
                var rowIndex = rows.indexOf(row);
                rows.splice(rowIndex, 1);
                cmp.set('v.lstLineItems', rows);
                break;
        }
    },

    /**
     * datatable doesn't show Cancel or Save buttons until changes are made
     * but what if we don't want to make changes, and clone the lines as they are?
     * We show a copy of that button bar.  If changes are made, hide it because
     * the standard one will appear
     * */
    hideManualSaveBtn : function (cmp){
        cmp.set("v.changesMade", true);
    },

    /**
     * Clone opportunity line items with given values from the datatable
     * */
    cloneLines : function(cmp, event, helper) {
        cmp.set("v.loading", true);
        cmp.set('v.draftValues', event.getParam('draftValues'));
        helper.cloneOpportunityProducts( cmp );
    },

    /**
     * Call to go to the cloned opp
     * */
    navigateToRecord : function(cmp, event, helper){
        helper.navigateToClonedOpp(cmp);
    },

    /**
     * Close the modal window and destroy the component
     * */
    cancelClone : function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        cmp.destroy();
    }
})