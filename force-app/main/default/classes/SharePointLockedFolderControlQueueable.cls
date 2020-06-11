/*
    Created by RedTag129 
 */
public with sharing class SharePointLockedFolderControlQueueable implements Queueable,Database.AllowsCallouts {
    FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
    CustomMetadataWrapper metWrapper;
    ContentVersion cv;
    String docType;
    Id recordId;
    Id oldVersionId;
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
    Simploud__Controlled_Document__c oldObj;
    String fields;
    Map<String,String> fieldsMap;
    Map<String, String> mapFieldsWithType = new Map<String,String>();
    Map<String,String> mapFieldsFromSharePoint = new Map <String, String>();
    Set<String> setTypes = new Set<String>();




    public SharePointLockedFolderControlQueueable (Simploud__Controlled_Document__c obj) {
        revisionObj = new Simploud__Controlled_Document__c();
        revisionObj = obj;
        recordId = revisionObj.Id;
        Simploud__Controlled_Document__c oldObj=[SELECT Id,CheckDockType__c,Record_Version__c, Name FROM Simploud__Controlled_Document__c WHERE Id=:recordId];
        Id cdId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId].ContentDocumentId;
        cv = [SELECT Id,Title, FileExtension,ExternalDocumentInfo1, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :cdId];
        Simploud__Controlled_Document__c cdObj = new Simploud__Controlled_Document__c();
        cdObj = [SELECT Simploud__Status__c, Record_Version__c,Id, Name FROM Simploud__Controlled_Document__c WHERE Id =: recordId LIMIT 1];
        newTitle =cdObj.Name+' v'+Integer.valueof(cdObj.Record_Version__c)+' '+cdObj.Simploud__Status__c;

    }


    public void execute(QueueableContext context) {
        if(!Test.isRunningTest()){
        setCustomMetadata();
        checkTypeFolder();
        getMetadata(cv);
        getMetadataWithFields(cv);
        downloadCurrentFile(cv);
        uploadFileToSharePoint(cv);
        getMetadataLockedDocument(cv);
        getMetadataURI(cv);
        metadataPOSTLockedDocument();
        createLinkOnPrevVersion();  
        }
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
        FieldsMetadataWrapper wrapper;
        wrapper = FieldsMetadataWrapper.parse(response.getBody());
        for(FieldsMetadataWrapper.Results item : wrapper.d.results) {
            mapFieldsFromSharePoint.put(item.Title, item.StaticName);
            mapFieldsWithType.put(item.Title, item.TypeAsString);
            setTypes.add(item.TypeAsString);
        }
        
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
        path = fileWrapper.getURL(response.getBody());
        
    }





    //Download file from Controlled Documents
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

    }





   //Upload file to Locked Documents
    public void uploadFileToSharePoint(ContentVersion cv) {
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
    }

	

    public void getMetadataLockedDocument(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Type', 'application/json;odata=verbose');
        String url= metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+newFolder+'\''+')/Files(\''+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.'+cv.FileExtension+'\')';
        request.setEndpoint('callout:'+metWrapper.authProvider + url);
        Http http = new Http();
        HttpResponse response = http.send(request);
        System.debug('body >>>> '+response.getBody());
        lockedPath = fileWrapper.getLockedURL(response.getBody());
    }





    public void getMetadataURI(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Type','application/json;odata=verbose');
        String relative = lockedPath.substring(lockedPath.lastIndexOf('.sharepoint.com')+15).replace('"','');
        String encodedUrl = EncodingUtil.urlEncode(relative,'UTF-8').replace('+','%20');
        String relativeURL = metWrapper.sitePath+'_api/web/GetFileByServerRelativeUrl('+'\''+encodedUrl+'\')/ListItemAllFields';
        request.setEndpoint('callout:'+metWrapper.authProvider+relativeURL);
        Http http = new Http();
        HttpResponse response = http.send(request);
        id = fileWrapper.getID(response.getBody());
        guid = fileWrapper.getGUID(response.getBody());
        serverRedirectedEmbedUri = fileWrapper.getServerRedirectedEmbedUri(response.getBody());
        uri = fileWrapper.getURI(response.getBody());
        type = fileWrapper.getType(response.getBody());
    }



    public String getFieldsFromCustomMetadata(){
        String fieldSP;
        String fieldSF;
        fieldsMap = new Map<String,String>();
        String json='{"__metadata":{"type":'+type+'},';
        fields = metWrapper.controlledDocField;
        if (docType == 'Controlled%20Documents') {
            fields = metWrapper.controlledDocField;
        }else if (docType== 'General%20Documents') {
            fields = metWrapper.generalDocField;
        }

        List<String> rows = fields.split(';');


        for(String item:rows) {
            if(item.split(':').size()>0) {
                fieldSP = item.split(':')[0];
                fieldSF = item.split(':')[1];
                fieldsMap.put(fieldSP, fieldSF);
            }
        }

        String query='SELECT ';
        for(String field:fieldsMap.values()) {
            query+=field+', ';
        }
        SObject ob;
        query+='Id FROM Simploud__Controlled_Document__c WHERE Id=:recordId';
        //  query+='Id FROM Simploud__Controlled_Document__c WHERE Id=:oldVersionId';
        ob =(Simploud__Controlled_Document__c) Database.query(query);


        for(String key : mapFieldsWithType.keyset()) {
            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'DateTime') {
                json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+String.valueOf(fileWrapper.generateDate(date.valueOf(ob.get(fieldsMap.get(key)))))+'",';
            }
            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'MultiChoice') {
                json+= '"'+mapFieldsFromSharePoint.get(key)+'" : {"__metadata":{"type":"Collection(Edm.String)"},"results":'+fileWrapper.generateValueForMultiSelectUpdate(''+ob.get(fieldsMap.get(key) )+'')+'},';
            }

            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Choice'||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Number'||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Text' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Boolean' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'URL' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'File' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Guid' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Note') {

                if(!fieldsMap.get(key).contains('__r')) {
                    if(fieldsMap.get(key).contains('.')) {
                        if(fieldsMap.get(key).split('\\.').size() == 3) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).getSObject(fieldsMap.get(key).split('\\.')[1]).get(fieldsMap.get(key).split('\\.')[2])+'",';
                        }else {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject('Owner').get('Name')+'",';
                        }   
                    }
                }

                if(fieldsMap.get(key).contains('__r')) {
                    try{
                        if(fieldsMap.get(key).split('\\.').size() == 5){
                          json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).getSObject(fieldsMap.get(key).split('\\.')[1]).getSObject(fieldsMap.get(key).split('\\.')[2]).getSObject(fieldsMap.get(key).split('\\.')[3]).get(fieldsMap.get(key).split('\\.')[4])+'",';
    
                      }
                        if(fieldsMap.get(key).split('\\.')[1].contains('__r')) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).getSObject(fieldsMap.get(key).split('\\.')[1]).get(fieldsMap.get(key).split('\\.')[2])+'",';

                        } if(!fieldsMap.get(key).split('\\.')[1].contains('__r')) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).get(fieldsMap.get(key).split('\\.')[1])+'",';
                        }
                    }
                    catch(Exception e) {
                        if(e.getMessage().contains('Attempt to '))
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"Not specified",';
                    }

            // } if(!fieldsMap.get(key).contains('__r')) {
                }if(!fieldsMap.get(key).contains('.')) {
                    json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.get(fieldsMap.get(key))+'",';
                }

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
        Http http = new Http();
        HttpResponse response=http.send(request);
        if(response.getStatusCode() == 200) {
            System.debug(response.getBody());
        }
        else System.debug(response.getBody());
    }




    public void createLinkOnPrevVersion() {
        //Simploud__SimploudOrgSettings__c sett = new Simploud__SimploudOrgSettings__c();
        //sett = [SELECT Id,Simploud__IgnoreTriggers__c,Simploud__IgnoreConfigTrigger__c FROM Simploud__SimploudOrgSettings__c];
        Simploud__Controlled_Document__c cdObj = new Simploud__Controlled_Document__c();
        cdObj = [SELECT Simploud__Status__c, Record_Version__c,Id, Name FROM Simploud__Controlled_Document__c WHERE Id =: recordId LIMIT 1];
        //this ContentVetsion will go to Locked folder
        ContentVersion newExternalFile = new ContentVersion();
        newExternalFile.ExternalDataSourceId = [SELECT Id FROM ExternalDataSource WHERE DeveloperName = 'ESMS_SharePoint_via_Azure' LIMIT 1].Id;
        if(cv.FileExtension != 'pdf'){
            newExternalFile.ExternalDocumentInfo1 = serverRedirectedEmbedUri.replace('"','').replace('interactivepreview', 'view');
        }
        if(cv.FileExtension == 'pdf'){
            if(metWrapper.sitePath == '/sites/edmsclientdocs/'){
            String encodedFolderName = EncodingUtil.urlEncode(metWrapper.lockedDocsFolder,'UTF-8').replace('+','%20'); 
            String encodedTitle = EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20');
            String sitePath = EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' ).replace('+','%20');
            newExternalFile.ExternalDocumentInfo1 ='https://medtoxdataline.sharepoint.com/'+sitePath+encodedFolderName+'/Forms/AllItems.aspx?id='+sitePath+encodedFolderName+'%2F'+encodedTitle+'.pdf&parent='+encodedFolderName;
            }else{
                String folderName = 'ApprovedtoObsoleteDocuments';
                cv.ExternalDocumentInfo1 = 'https://medtoxdataline.sharepoint.com'+metWrapper.sitePath+folderName+'/Forms/AllItems.aspx?viewpath='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName+'&id='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName+'%2F'+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.pdf&parent='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName;

            }
        }
        newExternalFile.ExternalDocumentInfo2 = 'item:L3NpdGVzL2VkbXNjbGllbnRkb2Nz:6f4ce06a-ecd6-4a22-8710-c3e42f39bfd4:'+guid.replace('"','')+':'+id;
        newExternalFile.ContentLocation = 'E';
        newExternalFile.Title = cv.Title;
        newExternalFile.PathOnClient = newExternalFile.Title + '.' + cv.FileExtension;
        newExternalFile.Origin = 'H';

        //delete previous a ContentVersion from ControlledDocument Object
        try{
        List<ContentDocumentLink> oldCdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId =: revisionObj.Id LIMIT 1];
        //sett.Simploud__IgnoreTriggers__c = true;
        //sett.Simploud__IgnoreConfigTrigger__c=true;
       // update sett;

        delete oldCdl;
        }catch(Exception e) {
            if(e.getMessage().contains('Delete failed'))
                {
                    return;
                }
            }
       // sett.Simploud__IgnoreTriggers__c = false;
        //sett.Simploud__IgnoreConfigTrigger__c = false;
        //update sett;

        insert newExternalFile;
        // create a new link to  the ControlledDocumets object
        ContentDocumentLink cdl2 = new ContentDocumentLink();
        cdl2.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newExternalFile.Id LIMIT 1].ContentDocumentId;
        cdl2.LinkedEntityId = revisionObj.Id;
        cdl2.ShareType = 'I';
        insert cdl2;

    }


    


    public void setCustomMetadata(){
        String lockedFolder,controlledFolder,generalFolder;
        String controlledField, generalField, lockedField;
        SharePoint_API_Info__mdt info = [SELECT Auth_Provider__c,Site_Path__c FROM SharePoint_API_Info__mdt WHERE DeveloperName='Integration_settings' LIMIT 1];
        List<SharePointSettings__mdt> sett = [SELECT DeveloperName,Folder_Title__c,Fields__c FROM SharePointSettings__mdt LIMIT 3];
        for(SharePointSettings__mdt item:sett)
        {
            if(item.DeveloperName == 'Controlled_Documents') {
                controlledFolder = item.Folder_Title__c;
                controlledField = item.Fields__c;
            } else if(item.DeveloperName=='Locked_Documents')
                lockedFolder = item.Folder_Title__c;
                lockedField = item.Fields__c;

        }
        metWrapper = new CustomMetadataWrapper(info.Auth_Provider__c,info.Site_Path__c,controlledFolder,generalFolder,lockedFolder,controlledField, generalField, lockedField);
    }


    public void checkTypeFolder(){
        folder = metWrapper.controlledDocsFolder.replace(' ','%20');
        fields = metWrapper.controlledDocField;
        newFolder = metWrapper.lockedDocsFolder.replace(' ','%20');
        fields = metWrapper.lockedDocField;

    }

    public SharePointLockedFolderControlQueueable() {
        System.debug('----EMPTY CONSTRUCTOR----');
    }
  
}