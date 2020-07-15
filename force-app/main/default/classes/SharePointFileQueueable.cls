/*
    Created by RedTag129 on 12.08.2019
    Updated by RedTag129 on 11.12.2019
 */
public with sharing class SharePointFileQueueable implements Queueable,Database.AllowsCallouts {
    FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
    CustomMetadataWrapper metWrapper;
    String folder;
    ContentVersion cv;
    String docType;
    Id LinkedEntity;
    String id;
    String guid;
    String serverRedirectedEmbedUri;
    String uri;
    String type;
    String path;
    List<ContentVersion> cvLst = new List<ContentVersion>();
    String fields;
    Map<String,String> fieldsMap;
    Map<String, String> mapFieldsWithType = new Map<String,String>();
    Map<String,String> mapFieldsFromSharePoint = new Map <String,String>();
    Set<String> setTypes = new Set<String>();
    String externalFilePath;



    public void execute(QueueableContext context){
        Set<Id> obIds = new Set<Id>();
        for(ContentVersion cv : cvLst) {
            if(cv.ContentDocumentId!= null) {
                obIds.add(cv.ContentDocumentId);
            }
        }
        List<ContentVersion> cvList = [SELECT Id,Title,FileExtension,ContentSize,
                                       VersionData,ContentDocumentId,ExternalDataSourceId,
                                       ExternalDocumentInfo1,ExternalDocumentInfo2
                                       FROM ContentVersion WHERE ContentDocumentId IN :obIds];
        for(ContentVersion cv: cvList) {
            if(cv.ExternalDataSourceId == null && cv.ExternalDocumentInfo1 == null && cv.ExternalDocumentInfo2 == null) {
                setCustomMetadata();
                defineDocType(cv);
                if ( docType == Constants.CONTROLLED_DOC_TYPE ||  docType == Constants.GENERAL_DOC_TYPE ) {
                    if(!Test.isRunningTest()) {
                        UploadFileToSharePoint(cv);
                        getMetadata(cv);
                        getMetadataWithFields(cv);
                        getMetadataURI(cv);
                        getFieldsFromCustomMetadata();
                        fileCheckOut(cv);
                        if(docType == Constants.CONTROLLED_DOC_TYPE) {
                            metadataPOSTControlledDocument();

                        } if(docType == Constants.GENERAL_DOC_TYPE) {
                            metadataPOSTGeneralDocument();

                        }

                       fileCheckIn(cv);
                        CreateExternalCV(cv);
                    }
                    else {System.debug('Wrong docType');}
                }
                else {
                    System.debug('---------File is already an external one--------');
                }
            }
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

    public void defineDocType(ContentVersion cv) {
        list<ContentDocumentLink> oblList = [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId =: cv.ContentDocumentId];
        for(ContentDocumentLink obl:oblList) {
            String entityType = obl.LinkedEntityId.getSobjectType().getDescribe().getLabelPlural();
            if(entityType != 'Users') {
                docType = entityType.replace(' ','%20');
                LinkedEntity = obl.LinkedEntityId;
            }
            if(docType == Constants.CONTROLLED_DOC_TYPE) {
                folder = metWrapper.controlledDocsFolder.replace(' ','%20');
                fields = metWrapper.controlledDocField;
            }
            if(docType == Constants.GENERAL_DOC_TYPE) {
                folder = metWrapper.generalDocsFolder.replace(' ','%20');
                fields = metWrapper.generalDocField;
            }
            if(docType == Constants.LOCKED_DOC_TYPE) {
                folder = metWrapper.lockedDocsFolder.replace(' ','%20');
                fields = metWrapper.lockedDocField;
            }
        }
    }



    public void UploadFileToSharePoint(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        Blob data = cv.VersionData;
        request.setMethod('POST');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Type','multipart/form-data');
        request.setHeader('Content-Length',String.valueOf(data.size()));
        String url = metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+folder+'\''+')/Files/add(name='+'\''+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.'+cv.FileExtension+ '\',overwrite=true)';

        request.setEndpoint('callout:'+metWrapper.authProvider+url);
        request.setBodyAsBlob(data);
        Http http = new Http();
        HttpResponse response = http.send(request);
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

    public void getMetadataURI(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Type','application/json;odata=verbose');
        String relative = path.substring(path.lastIndexOf('.sharepoint.com')+15).replace('"','');
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



    public void fileCheckOut(ContentVersion cv){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Length','0');
        request.setHeader('Accept','application/json;odata=verbose');
        String relative = path.substring(path.lastIndexOf('.sharepoint.com')+15).replace('"','');
        String encodedUrl = EncodingUtil.urlEncode(relative,'UTF-8').replace('+','%20');
        String relativeURL = metWrapper.sitePath+'_api/web/GetFileByServerRelativeUrl('+'\''+encodedUrl+'\')/CheckOut()';
        request.setEndpoint('callout:'+metWrapper.authProvider+relativeURL);
        Http http = new Http();
        HttpResponse response = http.send(request);
    }

    public String getFieldsFromCustomMetadata(){
        String fieldSP;
        String fieldSF;
        fieldsMap = new Map<String,String>();
        String json='{"__metadata":{"type":'+type+'},';
        List<String> rows = fields.split(';');

        for(String item:rows) {
            if(item.split(':').size()>0) {
                fieldSP = item.split(':')[0];
                fieldSF = item.split(':')[1];
                fieldsMap.put(fieldSP, fieldSF);
            }
        }

        String query='SELECT ';
        String query2='SELECT ';
        for(String field:fieldsMap.values()) {
            query+=field+', ';
            query2+=field+', ';
        }
        SObject ob;
        if(docType == Constants.GENERAL_DOC_TYPE) {
            query2+='Id FROM Simploud__General_Document__c WHERE Id=:LinkedEntity';
            ob =(Simploud__General_Document__c) Database.query(query2);

        }
        if (docType == Constants.CONTROLLED_DOC_TYPE || docType == Constants.LOCKED_DOC_TYPE) {
            query+='Id FROM Simploud__Controlled_Document__c WHERE Id=:LinkedEntity';
            ob =(Simploud__Controlled_Document__c) Database.query(query);
        }


        for(String key : mapFieldsWithType.keyset()) {
            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'DateTime') {
                json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+String.valueOf(fileWrapper.generateDate(date.valueOf(ob.get(fieldsMap.get(key)))))+'",';
            }
            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'MultiChoice') {
                json+= '"'+mapFieldsFromSharePoint.get(key)+'" : {"__metadata":{"type":"Collection(Edm.String)"},"results":'+fileWrapper.generateValueForMultiSelectUpdate(''+ob.get(fieldsMap.get(key) )+'')+'},';
            }

            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.CHOICE_TYPE||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.NUMBER_TYPE||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.TEXT_TYPE||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.BOOLEAN_TYPE ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.URL_TYPE ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.FILE_TYPE ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.GUID_TYPE ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == Constants.NOTE_TYPE) {

                if(!fieldsMap.get(key).contains('__r')) {
                    if(fieldsMap.get(key).contains('.')) {
                        if(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT).size() == 3) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[0]).getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[1]).get(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[2])+'",';
                        }else {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject('Owner').get('Name')+'",';
                        }

                    }
                }
                if(fieldsMap.get(key).contains('__r')) {
                    try{
                        if(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT).size() == 5) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[0]).getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[1]).getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[2]).getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[3]).get(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[4])+'",';

                        }
                        if(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[1].contains('__r')) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[0]).getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[1]).get(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[2])+'",';

                        } if(!fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[1].contains('__r')) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[0]).get(fieldsMap.get(key).split(Constants.SPLIT_BY_DOT)[1])+'",';
                        }
                    }
                    catch(Exception e) {
                        if(e.getMessage().contains('Attempt to '))
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"Not specified",';
                    }

                } if(!fieldsMap.get(key).contains('.')) {
                    json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.get(fieldsMap.get(key))+'",';
                }
            }

        }

        json+= +'}';
        Integer index=json.lastIndexOf(',');
        json=json.left(index)+json.right(json.length()-index-1);
        return json;

    }

    public void fileCheckIn(ContentVersion cv){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Length','0');
        String relative = path.substring(path.lastIndexOf('.sharepoint.com')+15).replace('"','');
        externalFilePath = relative;
        String encodedUrl = EncodingUtil.urlEncode(relative,'UTF-8').replace('+','%20');
        String relativeURL = metWrapper.sitePath+'_api/web/GetFileByServerRelativeUrl('+'\''+encodedUrl+'\')/CheckIn()';
        request.setEndpoint('callout:'+metWrapper.authProvider+relativeURL);
        Http http = new Http();
        HttpResponse response = http.send(request);
    }


    public void metadataPOSTControlledDocument() {
        HttpRequest request = new HttpRequest();
        String relative = uri.substring(uri.lastIndexOf('.sharepoint.com')+15).replace('"','');
        String URI = EncodingUtil.urlEncode(relative,'UTF-8');
        request.setEndpoint('callout:'+metWrapper.authProvider+relative);
        request.setMethod('POST');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Type','application/json;odata=verbose');
        request.setHeader('X-Http-Method','MERGE');
        request.setHeader('If-Match','*');
        request.setBody(
            getFieldsFromCustomMetadata()
            );
        Http http = new Http();
        HttpResponse response = http.send(request);
    }



    public void metadataPOSTGeneralDocument() {
        HttpRequest request = new HttpRequest();
        String relative = uri.substring(uri.lastIndexOf('.sharepoint.com')+15).replace('"','');
        String URI = EncodingUtil.urlEncode(relative,'UTF-8');
        request.setEndpoint('callout:'+metWrapper.authProvider + relative);
        request.setMethod('POST');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Type','application/json;odata=verbose');
        request.setHeader('X-Http-Method','MERGE');
        request.setHeader('If-Match','*');
        request.setBody(
            getFieldsFromCustomMetadata()
            );
        Http http = new Http();
        HttpResponse response = http.send(request);
    }


    public void CreateExternalCV(ContentVersion cv){
        String sharePointURL = metWrapper.sharePointUrl;
        ContentVersion newExternalFile = new ContentVersion();
        newExternalFile.ExternalDataSourceId = [SELECT Id FROM ExternalDataSource WHERE DeveloperName = 'ESMS_SharePoint_via_Azure' LIMIT 1].Id;
        if(docType == Constants.CONTROLLED_DOC_TYPE) {
            if(cv.FileExtension == 'pdf') {
                if(metWrapper.sitePath == Constants.EDMS_PATH) {
                    String encodedUrl = EncodingUtil.urlEncode(externalFilePath,'UTF-8').replace('+','%20');
                    String encodeDockType =  EncodingUtil.urlEncode(metWrapper.controlledDocsFolder,'UTF-8').replace('+','%20');
                    String encodedSitePath = EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' );
                    newExternalFile.ExternalDocumentInfo1 = sharePointURL+'/'+encodedSitePath+encodeDockType+'/Forms/AllItems.aspx'+'?id='+encodedUrl+'&parent='+encodeDockType;
                }else {
                    String sitePath = metWrapper.sitePath;
                    String encodedSitePath = EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' );
                    String folderName = 'DrafttoDraftApprovalDocuments';
                    String encodedUrl = EncodingUtil.urlEncode(externalFilePath,'UTF-8').replace('+','%20');
                    newExternalFile.ExternalDocumentInfo1 = sharePointURL+sitePath+folderName+'/Forms/AllItems.aspx'+'?viewpath='+encodedSitePath+'%2F'+folderName+'&id='+encodedUrl+'&parent='+encodedSitePath+'%2F'+folderName;

                }
            } if(cv.FileExtension != 'pdf') {
                newExternalFile.ExternalDocumentInfo1 = serverRedirectedEmbedUri.replace('"','').replace('interactivepreview', 'edit');
            }

        }
        else {
            newExternalFile.ExternalDocumentInfo1 = serverRedirectedEmbedUri.replace('"','');
        }
        newExternalFile.ExternalDocumentInfo2 = Constants.EXTERNAL_DOC_INFO_ID+guid.replace('"','')+':'+id;
        newExternalFile.ContentLocation = 'E';
        newExternalFile.Title = cv.Title;
        newExternalFile.PathOnClient = cv.Title+'.'+ cv.FileExtension;
        newExternalFile.Origin = 'H';
        ContentDocument obToDelete = [SELECT Id FROM ContentDocument WHERE Id =:cv.ContentDocumentId];
        delete obToDelete;
        insert newExternalFile;
        ContentDocumentLink obl = new ContentDocumentLink();
        obl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:newExternalFile.Id LIMIT 1].ContentDocumentId;
        obl.LinkedEntityId = LinkedEntity;
        obl.ShareType = 'I';
        insert obl;

    }


    public void setCustomMetadata(){
        String lockedFolder,controlledFolder,generalFolder;
        String controlledField, generalField, lockedField;
        SharePoint_API_Info__mdt info = [SELECT Auth_Provider__c,Site_Path__c,SharePoint_URL__c FROM SharePoint_API_Info__mdt WHERE DeveloperName='Integration_settings' LIMIT 1];
        List<SharePointSettings__mdt> sett=[SELECT DeveloperName,Folder_Title__c,Fields__c FROM SharePointSettings__mdt LIMIT 3];
        for(SharePointSettings__mdt item:sett)
        {
            if(item.DeveloperName == 'Controlled_Documents' ) {
                controlledFolder = item.Folder_Title__c;
                controlledField = item.Fields__c;
            }
            if(item.DeveloperName=='General_Documents') {
                generalFolder = item.Folder_Title__c;
                generalField = item.Fields__c;
            }
            if(item.DeveloperName=='Locked_Documents') {
                lockedFolder = item.Folder_Title__c;
                lockedField = item.Fields__c;
            }
            metWrapper = new CustomMetadataWrapper(
                info.Auth_Provider__c,
                info.Site_Path__c,
                info.SharePoint_URL__c,
                controlledFolder,
                generalFolder,
                lockedFolder,
                controlledField,
                generalField,
                lockedField);
        }
    }
    public SharePointFileQueueable(List<ContentVersion> cvLst){
        this.cvLst = cvLst;
    }

    public SharePointFileQueueable(){
        System.debug('Empty constructor');
    }
}