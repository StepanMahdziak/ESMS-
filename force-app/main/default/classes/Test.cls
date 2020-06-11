/*
    Created by RedTag129 on 12.08.2019
    Updated by RedTag129 on 11.12.2019
 */
public with sharing class SharePointVersionControlQueueable implements Queueable,Database.AllowsCallouts {
        FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
        CustomMetadataWrapper metWrapper;
        ContentVersion cv;
        String docType;
        Id recordId;
        id oldVersionId;
        String folder;
        String newTitle;
        String newFolder;
        String path;
        String lockedPath;
        String id;
        String guid;
        String serverRedirectedEmbedUri;
        String uri;
        String type;
        Blob data;
        Simploud__Controlled_Document__c revisionObj;
        Simploud__Controlled_Document__c  oldObj;
        String fields;
        Map<String,String> fieldsMap;
        Map<String, String> mapFieldsWithType = new Map<String,String>();
        Map<String,String> mapFieldsFromSharePoint = new Map <String, String>();
        Set<String> setTypes = new Set<String>();

    public SharePointVersionControlQueueable(Simploud__Controlled_Document__c obj) {
        revisionObj = new Simploud__Controlled_Document__c();
        revisionObj = obj;
        recordId = revisionObj.Id;
        oldVersionId=revisionObj.Simploud__Previous_Version__c;
        Simploud__Controlled_Document__c oldObj=[SELECT Id,Name FROM Simploud__Controlled_Document__c WHERE Id=:oldVersionId];
        Id cdId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :oldVersionId].ContentDocumentId;
        cv = [SELECT Title, FileExtension, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :cdId];
        newTitle = revisionObj.Name+' v'+Integer.valueof(revisionObj.Simploud__Version__c)+' '+revisionObj.Simploud__Status__c; 
  

        oldObj =[SELECT Id,Simploud__Status__c  FROM Simploud__Controlled_Document__c WHERE Id=:revisionObj.Simploud__Previous_Version__c];
       
      
    }
    
    
    
    public void execute(QueueableContext context) {
             // for(Simploud__Controlled_Document__c cdObj: cdObj.values()){
            //     recordId = cdObj.Id;
            //     try{
            //    // Simploud__Controlled_Document__c oldObj=[SELECT Id,Simploud__Status__c FROM Simploud__Controlled_Document__c WHERE Id=:cdObj.Simploud__Previous_Version__c];
            //     Id cdId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId].ContentDocumentId;
            //     cv = [SELECT Title,FileExtension,VersionData,ExternalDataSourceId,ExternalDocumentInfo1,ExternalDocumentInfo2 FROM ContentVersion WHERE ContentDocumentId = :cdId];
            //     cv.Title = cdObj.Name+' v'+Integer.valueof(cdObj.Simploud__Version__c)+' '+cdObj.Simploud__Status__c; 
            //     }catch(Exception e ){
            //          if(e.getMessage().contains('List has no rows'))
            //     {
            //         return;
            //     }
            // }
            setCustomMetadata();
            checkTypeFolder();
            getMetadata(cv);
            getMetadataWithFields(cv);
            downloadCurrentFile(cv);

            UploadFileToSharePoint(cv);
            getMetadataLockedDocument(cv);
            getMetadataURI(cv);
            metadataPOSTLockedDocument();
            createLinkOnPrevVersion();


    // }
    }

     public void getMetadataWithFields(ContentVersion cv) {
                HttpRequest request = new HttpRequest();
                request.setMethod('GET');
                request.setHeader('Accept','application/json;odata=verbose');
                request.setHeader('Content-Type','application/json;odata=verbose');
                 String url = metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+folder+'\''+')/fields';
                request.setEndpoint('callout:'+metWrapper.authProvider+url);
                Http http = new Http();
                HttpResponse response = http.send(request);
                System.debug(response.getBody());
                FieldsMetadataWrapper wrapper;
                wrapper = FieldsMetadataWrapper.parse(response.getBody());
                    for(FieldsMetadataWrapper.Results item : wrapper.d.results){
                            mapFieldsFromSharePoint.put(item.Title, item.StaticName);
                            mapFieldsWithType.put(item.Title, item.TypeAsString);
                            setTypes.add(item.TypeAsString);
                    }
                if(response.getStatusCode() == 200) {
                    System.debug(response.getBody());
                }
                else System.debug(response.getStatusCode());
        }


    public void getMetadata(ContentVersion cv) {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Accept','application/json;odata=verbose');
            request.setHeader('Content-Type','application/json;odata=verbose');
            String url = metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+folder+
            '\''+')/Files(\''+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.'+cv.FileExtension+'\')';
                request.setEndpoint('callout:'+metWrapper.authProvider+url);
                Http http = new Http();
                HttpResponse response = http.send(request);
                System.debug(response.getBody());
                path = fileWrapper.getURL(response.getBody());
                if(response.getStatusCode() == 200) {
                    System.debug(response.getBody());
                }
                else System.debug(response.getStatusCode());
    }





    //Download file from Controlled
    public void downloadCurrentFile(ContentVersion cv) {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Accept', 'multipart/form-data');
            request.setHeader('Content-Type', 'application/json;odata=verbose');
            String relative = path.substring(path.lastIndexOf('.sharepoint.com')+15).replace('"','');
            String encodedUrl = EncodingUtil.urlEncode(relative,'UTF-8').replace('+','%20');
            String url = metWrapper.sitePath+'_api/web/GetFileByServerRelativeUrl('+'\''+encodedUrl+'\')/$value';
            request.setEndpoint('callout:'+metWrapper.authProvider+url);
            Http http = new Http();
            HttpResponse response = http.send(request);
            data = response.getBodyAsBlob();
            system.debug(data);
        
    }
  



    
    //Upload file to LockedDocuments
    public void UploadFileToSharePoint(ContentVersion cv) {
            System.debug('upload file to Locked Document>>>>>');
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('Accept','application/json;odata=verbose');
            request.setHeader('Content-Type','multipart/form-data');
            request.setHeader('Content-Length',String.valueOf(data.size()));
            String url = metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+newFolder+'\''+')/Files/add(name='+'\''+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.'+cv.FileExtension+ '\',overwrite=true)';
            request.setEndpoint('callout:'+metWrapper.authProvider+url);
            request.setBodyAsBlob(data);
            Http http = new Http();
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200) {
                  System.debug(response.getBody());
                }
            else  System.debug(response.getStatusCode());
            
    }
     public void UploadFileToSP(ContentVersion cv) {
            System.debug('upload file to Locked Document>>>>>');
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('Accept','application/json;odata=verbose');
            request.setHeader('Content-Type','multipart/form-data');
            request.setHeader('Content-Length',String.valueOf(data.size()));
            String url = metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+folder+'\''+')/Files/add(name='+'\''+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.'+cv.FileExtension+ '\',overwrite=true)';
            request.setEndpoint('callout:'+metWrapper.authProvider+url);
            request.setBodyAsBlob(data);
            Http http = new Http();
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200) {
                  System.debug(response.getBody());
                }
            else  System.debug(response.getStatusCode());
            
    }
       
            
    public void getMetadataLockedDocument(ContentVersion cv) {
            System.debug('Get metadata from Locked Document>>>>>>');
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Accept', 'application/json;odata=verbose');
            request.setHeader('Content-Type', 'application/json;odata=verbose');
            String url= metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+newFolder+'\''+')/Files(\''+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.'+cv.FileExtension+'\')';
            request.setEndpoint('callout:'+metWrapper.authProvider + url);
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug('-------Locked document metadata-------'+response.getBody());
            System.debug(response.getBody());
            lockedPath = fileWrapper.getLockedURL(response.getBody());
            if(response.getStatusCode() == 200) {
                    System.debug(response.getBody());
                }
            else System.debug(response.getStatusCode());
    }



     

    public void getMetadataURI(ContentVersion cv) {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Accept','application/json;odata=verbose');
            request.setHeader('Content-Type','application/json;odata=verbose');
            String relative = lockedPath.substring(lockedPath.lastIndexOf('.sharepoint.com')+15).replace('"','');
            System.debug(relative);
            String encodedUrl = EncodingUtil.urlEncode(relative,'UTF-8').replace('+','%20');
            String relativeURL = metWrapper.sitePath+'_api/web/GetFileByServerRelativeUrl('+'\''+encodedUrl+'\')/ListItemAllFields';
            request.setEndpoint('callout:'+metWrapper.authProvider+relativeURL);
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug(response.getBody());
            id = fileWrapper.getID(response.getBody());
            guid = fileWrapper.getGUID(response.getBody());
            serverRedirectedEmbedUri = fileWrapper.getServerRedirectedEmbedUri(response.getBody());
            System.debug('getServerRedirectedEmbedUri ' + serverRedirectedEmbedUri);
            uri = fileWrapper.getURI(response.getBody());
            type = fileWrapper.getType(response.getBody());
            if(response.getStatusCode() == 200) {
                System.debug(response.getBody());
            }
            else System.debug(response.getStatusCode());
           
    }
   


  public String getFieldsFromCustomMetadata(){
             String fieldSP;
             String fieldSF;
             fieldsMap = new Map<String,String>();
             String json='{"__metadata":{"type":'+type+'},';
              fields = metWrapper.controlledDocField;
             if (docType == 'Controlled%20Documents'){
                 fields = metWrapper.controlledDocField;
             }else if (docType== 'General%20Documents'){
                  fields = metWrapper.generalDocField;
             }
			 
             List<String> rows = fields.split(';');
             

                for(String item:rows){
                    if(item.split(':').size()>0){
                    fieldSP = item.split(':')[0];
                    fieldSF = item.split(':')[1];	
                    fieldsMap.put(fieldSP, fieldSF);
                    }
                }

                String query='SELECT ';
                for(String field:fieldsMap.values()){
                    query+=field+', ';
                } 
                             SObject ob;              
                             query+='Id FROM Simploud__Controlled_Document__c WHERE Id=:recordId';
                             ob =(Simploud__Controlled_Document__c) Database.query(query);
                                     

                            for(String key : mapFieldsWithType.keyset()){
                                if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'DateTime'){
                                    json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+String.valueOf(fileWrapper.generateDate(date.valueOf(ob.get(fieldsMap.get(key)))))+'",'; 
                                } 
                                if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'MultiChoice'){
                                    json+= '"'+mapFieldsFromSharePoint.get(key)+'" : {"__metadata":{"type":"Collection(Edm.String)"},"results":'+fileWrapper.generateValueForMultiSelectUpdate(''+ob.get(fieldsMap.get(key) )+'')+'},';
                                } 
                                   
                                if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Choice'||
                                        fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Number'|| 
                                        fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Text' ||
                                        fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Boolean' || 
                                        fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'File' || 
                                        fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'URL' || 
                                        fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Guid' || 
                                        fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Note') {
                                if(fieldsMap.get(key).contains('__r')){
                                        json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).get(fieldsMap.get(key).split('\\.')[1])+'",';
                                    } else     
                                        json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.get(fieldsMap.get(key))+'",'; 
                                    }
                                        
                            }
                       
                json+= +'}';
                        
            Integer index=json.lastIndexOf(',');
            json=json.left(index)+json.right(json.length()-index-1);    
        return json;

        }
    
    public void metadataPOSTLockedDocument() {
        HttpRequest request=new HttpRequest();
        String url = uri.substring(uri.lastIndexOf('.sharepoint.com')+15).replace('"','');
        System.debug(url);
        String uri = EncodingUtil.urlEncode(url,'UTF-8');
        request.setEndpoint('callout:'+metWrapper.authProvider+url);
        request.setMethod('POST');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Type','application/json;odata=verbose');
        request.setHeader('X-Http-Method','MERGE');
        request.setHeader('If-Match','*');
        request.setBody(
        getFieldsFromCustomMetadata()
        );
        System.debug(request.getBody());
        System.debug(request.getEndpoint());
        Http http = new Http();
        HttpResponse response=http.send(request);
        System.debug(response);
    }
   

    

    public void createLinkOnPrevVersion() {
        Simploud__SimploudOrgSettings__c sett = new Simploud__SimploudOrgSettings__c();
        sett = [SELECT Id,Simploud__IgnoreTriggers__c,Simploud__IgnoreConfigTrigger__c FROM Simploud__SimploudOrgSettings__c];


        ContentVersion newExternalFile = new ContentVersion();
        newExternalFile.ExternalDataSourceId = [SELECT Id FROM ExternalDataSource WHERE DeveloperName = 'ESMS_SharePoint_via_Azure' LIMIT 1].Id;
        newExternalFile.ExternalDocumentInfo1 = serverRedirectedEmbedUri.replace('"','');
        newExternalFile.ExternalDocumentInfo2 = 'item:L3NpdGVzL2VkbXNjbGllbnRkb2Nz:6f4ce06a-ecd6-4a22-8710-c3e42f39bfd4:'+guid.replace('"','')+':'+id;
        system.debug('Info1:'+newExternalFile.ExternalDocumentInfo1+'Info2:'+newExternalFile.ExternalDocumentInfo2);

        newExternalFile.ContentLocation = 'E';
        newExternalFile.Title = cv.Title;
        newExternalFile.PathOnClient = newExternalFile.Title + '.' + cv.FileExtension;
        newExternalFile.Origin = 'H';



        if ([SELECT Id,Title FROM ContentVersion WHERE Title = :newExternalFile.Title].isEmpty()) {

            List<ContentDocumentLink> oldCdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            sett.Simploud__IgnoreTriggers__c = true;
            //sett.Simploud__IgnoreConfigTrigger__c=true;
            update sett;

            delete oldCdl;

            sett.Simploud__IgnoreTriggers__c = false;
            //sett.Simploud__IgnoreConfigTrigger__c = false;
            update sett;

            insert newExternalFile;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
        cdl.LinkedEntityId = revisionObj.Id;
        cdl.ShareType = 'I';
        insert cdl;

        
        ContentDocumentLink cdl2 = new ContentDocumentLink();
        cdl2.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newExternalFile.Id LIMIT 1].ContentDocumentId;
        cdl2.LinkedEntityId = oldObj.Id;
        cdl2.ShareType = 'I';
        insert cdl2;
        }
        else {
            List<ContentDocumentLink> oldCdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            sett.Simploud__IgnoreTriggers__c = true;
            update sett;
            delete oldCdl;
            sett.Simploud__IgnoreTriggers__c = false;
            update sett;

            ContentDocumentLink cdl = new ContentDocumentLink();
            ContentVersion cvToRelink=new ContentVersion();
            cvToRelink= [SELECT Id,Title FROM ContentVersion WHERE Title = :newExternalFile.Title];
            cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvToRelink.Id LIMIT 1].ContentDocumentId;
            cdl.LinkedEntityId = revisionObj.Id;
            cdl.ShareType = 'I';
            insert cdl;

        }
    }
        public void setCustomMetadata(){
            String lockedFolder,controlledFolder,generalFolder;
            String  controlledField, generalField, lockedField;
            SharePoint_API_Info__mdt info = [SELECT Auth_Provider__c,Site_Path__c FROM SharePoint_API_Info__mdt WHERE DeveloperName='Integration_settings' LIMIT 1];
            List<SharePointSettings__mdt> sett = [SELECT DeveloperName,Folder_Title__c,Fields__c FROM SharePointSettings__mdt LIMIT 3];
            for(SharePointSettings__mdt item:sett)
            {
                if(item.DeveloperName == 'Controlled_Documents'){
                    controlledFolder = item.Folder_Title__c;
                    System.debug('controlledFolder>>>>' + controlledFolder);
                    controlledField = item.Fields__c;
                      } else if(item.DeveloperName=='Locked_Documents')
                            lockedFolder = item.Folder_Title__c;
                            lockedField = item.Fields__c;
                            System.debug('`>>>>' + lockedFolder);
            
        }
            metWrapper = new CustomMetadataWrapper(info.Auth_Provider__c,info.Site_Path__c,controlledFolder,generalFolder,lockedFolder,controlledField, generalField, lockedField);
    }


    public void checkTypeFolder(){
           folder = metWrapper.controlledDocsFolder.replace(' ','%20');
           fields = metWrapper.controlledDocField;
                      newFolder = metWrapper.lockedDocsFolder.replace(' ','%20');
                      fields = metWrapper.lockedDocField;
                      System.debug('fields>>>' + fields);
        
    }

    public SharePointVersionControlQueueable() {
        System.debug('----EMPTY CONSTRUCTOR----');
    }

}