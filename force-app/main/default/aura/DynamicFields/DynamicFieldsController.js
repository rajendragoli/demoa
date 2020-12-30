({
    doInit : function(component, event, helper) {
        //fetch business types from backend using apex controller
        helper.getPtTypes(component,helper);
    }
})