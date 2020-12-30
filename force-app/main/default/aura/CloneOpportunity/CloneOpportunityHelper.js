({
    /**
     * Get the columns to display in the datatable from the fieldset
     * */
    getColumns : function( cmp ) {
        // Get columns from the fieldset
        let action = cmp.get("c.getFieldset");

        action.setCallback( this, function( response ) {
            let state = response.getState();
            if (state === "SUCCESS") {
                var fieldSetArray = JSON.parse(response.getReturnValue());

                //define action column
                var actions = {
                    type: 'action', typeAttributes: {
                        rowActions: [
                            { label: 'Delete', name: 'delete' }
                        ]
                    }
                };

                //push actions to into the first column
                fieldSetArray.unshift(actions);
                cmp.set("v.fieldsetColumns", fieldSetArray);
            }
            else if (state === "INCOMPLETE") {
                this.handleErrors([{message: 'network error getting opportunity lines'}], cmp);
            }
            else if (state === "ERROR") {
                this.handleErrors(response.getError(), cmp, 'info');
            }
        } );

        $A.enqueueAction(action);
    },

    /**
     * Get the list of the products from the source opportunity
     * */
    getLineItems : function( cmp ) {
        let action = cmp.get("c.getOpportunityLineItems");
        action.setParams({
            opportunityId: cmp.get('v.recordId')
        });

        action.setCallback( this, function( response ) {
            let state = response.getState();
            if (state === "SUCCESS") {
                var lines = response.getReturnValue();
                if(!lines.length){
                    //If there are no lines to clone, show a message then navigate to the cloned opportunity
                    this.handleErrors([{message: 'Opportunity has no products'}], cmp, 'info' , this.navigateToClonedOpp);
                }
                cmp.set( "v.lstLineItems", lines );
            }
            else if (state === "INCOMPLETE") {

            }
            else if (state === "ERROR") {
                this.handleErrors(response.getError(), cmp);
            }
        } );

        $A.enqueueAction(action);
    },

    /**
     * Clone source opportunity lines and override with values from the datatable
     * */
    cloneOpportunityProducts: function( cmp ) {
        let action = cmp.get("c.cloneOpportunityLineItems");
        action.setParams({
            sourceOppId: cmp.get("v.recordId"),
            clonedOppId: cmp.get("v.clonedOppId"),
            lstLineItems: cmp.get("v.lstLineItems"),
            changes: cmp.get("v.draftValues")
        });

        action.setCallback( this, function( response ) {
            cmp.set("v.loading", false);
            let state = response.getState();
            if (state === "SUCCESS") {
                this.navigateToClonedOpp(cmp);
            }
            else if (state === "INCOMPLETE") {
                this.handleErrors([{message: 'Unable to create the opportunity - network error'}], cmp);
            }
            else if (state === "ERROR") {
                this.handleErrors(response.getError(), cmp);
            }

        } );

        $A.enqueueAction(action);
    },

    /**
     * Go to the cloned opp
     * */
    navigateToClonedOpp : function( cmp ) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": cmp.get('v.clonedOppId')
        });
        navEvt.fire();
    },

    /**
     * Display errors or information windows.  Can't use Toast
     * because there's a Salesforce bug which causes them to appear
     * behind modal windows
     * */
    handleErrors: function(errors, cmp, type, onclose){
        let variant = 'error';
        let message = 'Unknown error';

        if(type){
            variant = type;
        }

        if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
        }

        let msgParams = {
            "variant": "error",
            "header": "Information",
            "message": message
        };

        if(onclose){
           msgParams.closeCallback = function(){ onclose(cmp) };
        }

        cmp.find('notifLib').showNotice(msgParams);

        console.error(message);
    }
})