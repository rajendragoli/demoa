({
	getPtTypes : function(component, helper) {
        var action = component.get("c.getPtTypes");
        action.setCallback(this, function(data){
            var state = data.getState();
            if (state === "SUCCESS") {
                component.set("v.ptTypes", data.getReturnValue());
            } else if (state === "ERROR"){
                alert('Unable to Fetch Values');
            }
        })
		
	}
})