({
	doInit : function(component, event, helper) {
    var action = component.get("c.getDocumentList");
    action.setParams({
      parentId : component.get("v.recordId")
    });

          action.setCallback(this, function(response) {
              var state = response.getState();
              console.log('State:'+response.getState());
              console.log('Value:'+response.getReturnValue());
              if (state === "SUCCESS") {
                  var relatedList = JSON.parse(response.getReturnValue());
				component.set("v.docList",relatedList); 
                  if (relatedList){
                component.set("v.showList",true);   
                  }
                component.set("v.filteredDocList",relatedList);  
              }
              });
    	$A.enqueueAction(action);
  },
    
    doInit2 : function(component, event, helper) {
    var action = component.get("c.getTaskDocumentList");
    action.setParams({
      taskId : component.get("v.recordId")
    });

          action.setCallback(this, function(response) {
              var state = response.getState();
              console.log('State INIT2:'+response.getState());
              console.log('Value INIT2:'+response.getReturnValue());
              if (response.getReturnValue() && state === "SUCCESS") {
                  var relatedList = JSON.parse(response.getReturnValue());
				
                  component.set("v.docList",relatedList);    
                  if (relatedList){
                component.set("v.showList",true);   
                  }
                component.set("v.filteredDocList",relatedList);  
              }
              });
    	$A.enqueueAction(action);
  }

})