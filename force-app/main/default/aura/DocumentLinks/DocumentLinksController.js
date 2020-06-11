({
    init : function(component, event, helper) {
        var actionInit = component.get("c.getAffectedRecords");
        
        actionInit.setParams({
            parentId  : component.get("v.recordId")
        });
        
        actionInit.setCallback(this, function(resp){
            var response = JSON.parse(resp.getReturnValue());
            console.log( 'RESPONSE: ', component.get("v.recordId"));
            
            if (response && response.length > 0) {
                component.set("v.availableList",response);
            } else {
                console.log('response.message' + resp.getReturnValue())
                helper.showWarningToast(component, event, helper, "Warning", resp.getReturnValue());
                $A.get("e.force:closeQuickAction").fire();
            }
            
        });
        $A.enqueueAction(actionInit);
    },
    
    buttonClick: function(component, event, helper){
        var updateLinks = component.get("c.updateDocLinks");
        updateLinks.setParams({
            aiString :  JSON.stringify(component.get("v.availableList"))
        });
        
        updateLinks.setCallback(this, function(resp){
            var response = resp.getReturnValue();
            if (response && response == "Success") {
                
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Updated successfully",
                    "message": "All affected items have been re-linked to the effecive version"
                });
                // Update the UI: close panel, show toast, refresh account page
                resultsToast.fire();
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('response.message' + response.message)
                helper.showWarningToast(component, event, helper, "Warning", response);
                $A.get("e.force:closeQuickAction").fire();
            }
            
        });
        $A.enqueueAction(updateLinks);
        
    },
    
    
})