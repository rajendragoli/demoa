({
	foregroundCall : function(component, event, helper) {
        component.set("v.backgroundFlag",false);
        helper.getAccCall(component,event,helper);
        helper.getConCall(component,event,helper);
		
	},
    
	backgroundCall : function(component, event, helper) {
        
        helper.setBackgroundCall(component,event,helper);
		
	},
    
    
})