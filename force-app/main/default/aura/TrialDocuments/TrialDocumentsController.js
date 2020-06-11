({	
    doInit : function(component, event, helper) {
        var objectName = component.get("v.sObjectName");        
        if (objectName == 'Task')
            helper.doInit2(component, event, helper);
        else
        helper.doInit(component, event, helper);
    },
    
    filterRecords : function(component, event, helper){
        debugger;
        var filteredValue = event.getSource().get("v.value");
        var docList = component.get("v.docList");
        if(filteredValue != null && filteredValue != undefined && filteredValue.trim()!="" && filteredValue.length > 2){
            var filteredDocList = [];
            docList.forEach(function(element){
                if((element.documentType != null &&  element.documentType.toLowerCase().includes(filteredValue.toLowerCase()))
                   || (element.documentTitle != null &&  element.documentTitle.toLowerCase().includes(filteredValue.toLowerCase()))
                  ){
                    filteredDocList.push(element);            
                }
            });
            component.set("v.filteredDocList",filteredDocList);
        }else{
            component.set("v.filteredDocList",docList);
        }
    },
    
})