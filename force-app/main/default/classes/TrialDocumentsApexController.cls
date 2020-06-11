/**
* @author Sagie Twig
* Following class serve back-end for document preview component
*/
public with sharing class  TrialDocumentsApexController {
    
    
    /**
* Provide content document id for link generation
* @param  parentId [ Trial Id ]
* @return          [ JSON String { responseType, data, msg } ]
*/
    @AuraEnabled
    public static String getDocumentList(Id parentId){
        
        List<Simploud__Trial_Item__c> ti = new List<Simploud__Trial_Item__c>();
        ti = [ SELECT Controlled_Document__c FROM Simploud__Trial_Item__c WHERE Simploud__Trial__c =:  parentId AND Controlled_Document__c != null];
        List<string> parentIdSet = new List<string>();
        if (!ti.isEmpty())
        {
            for (Simploud__Trial_Item__c item : ti)
                parentIdSet.add(item.Controlled_Document__c);
        }
        system.debug('trial items: ' + ti);
        
        List<Simploud__Controlled_Document__c> gd = new  List<Simploud__Controlled_Document__c>();
        gd = [SELECT Id,Name,Simploud__Document_Type__c, (SELECT ContentDocumentId, LinkedEntityId, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.ExternalDocumentInfo1, ContentDocument.Title
                                                          FROM ContentDocumentLinks 
                                                          WHERE LinkedEntityId IN: parentIdSet)
              FROM Simploud__Controlled_Document__c 
              WHERE Id IN :parentIdSet 
              ORDER BY Simploud__Document_Type__c ASC];        
        List<TrialDocumnetWrapper> trialDocs = new List<TrialDocumnetWrapper>();
        
        if(gd.isEmpty())
            return null;
        
        else
        {
            for (Simploud__Controlled_Document__c item : gd)
            {
                if(item.ContentDocumentLinks.size() > 0)
                {
                    for (ContentDocumentLink cdl :item.ContentDocumentLinks )
                    {
                        TrialDocumnetWrapper trialDoc = new TrialDocumnetWrapper();
                        String extLink = cdl.ContentDocument.LatestPublishedVersion.ExternalDocumentInfo1;
                        trialDoc.fileLink ='/sfc/servlet.shepherd/document/download/'+ cdl.ContentDocumentId ;
                        trialDoc.documentTitle = item.Name;
                        trialDoc.documentType = item.Simploud__Document_Type__c;
                        trialDoc.contentId = cdl.ContentDocumentId;
                        trialDoc.fileTitle = cdl.ContentDocument.Title;
                        trialDoc.fileExt = cdl.ContentDocument.FileExtension;
                        if (extLink != null)
                        {
                            trialDoc.fileLink = extLink;
                        }
                        trialDocs.add(trialDoc);
                    }
                }              
                
            }
        }
        system.debug('trial docs: ' + trialDocs);
        if(trialDocs.isEmpty())
            return null;
        else 
            return JSON.Serialize(trialDocs);
        
    }
    
    /**
* Provide content document id for link generation
* @param  parentId [ Task Id ]
* @return          [ JSON String { responseType, data, msg } ]
*/
    @AuraEnabled
    public static String getTaskDocumentList(Id taskId){
        string returnValue;
        List<Task> trainingTask = new List<Task>();
        trainingTask = [SELECT Id, WhatId FROM Task WHERE Id =: taskId];
        
        List<Simploud__Training_Material__c> trainList = new List<Simploud__Training_Material__c>();
        String trainId = trainingTask[0].WhatId;
        String trialId;
        if (trainId != null)
            trainList = [SELECT Id, Name, Trial__c FROM Simploud__Training_Material__c WHERE Id =: trainId];
        else
            return null;
        if (!trainList.isEmpty())
            trialId = trainList[0].Trial__c;
        else
            return null;
        if (trialId!=null)
            returnValue = getDocumentList(trialId);
        else 
            return null;
        
        system.debug('ReturnValue: '+returnValue);
        return returnValue;
        
    }
    
}