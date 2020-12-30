({
    getAccCall : function(component,event,helper) {
        
        try
        {
            var action = component.get("c.getAccount");
            action.setCallback(this, function(response) {
                if(response.getState() == 'SUCCESS')
                {
                    component.set('v.accMessageHolder',response.getReturnValue());
                    
                    if(component.get("v.backgroundFlag"))
                    {
                        helper.getConCall(component,event,helper);
                        component.set('v.accMessageHolder1',response.getReturnValue());
                    } 
                }
            });
            if(component.get("v.backgroundFlag"))
                action.setBackground();
            
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('Exception '+e);
        }
    },
    getConCall : function(component,event,helper) {
        
        try
        {
            var action = component.get("c.getContact");
            action.setCallback(this, function(response) {
                if(response.getState() == 'SUCCESS')
                {
                    component.set('v.conMessageHolder',response.getReturnValue());
                    if(component.get("v.backgroundFlag"))
                    {
                        component.set('v.conMessageHolder1',response.getReturnValue());
                    } 
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('Exception '+e);
        }
    },
    
    setBackgroundCall: function(component,event,helper) {
        
        component.set("v.backgroundFlag",true);
        helper.getAccCall(component,event,helper);
        
    },
})