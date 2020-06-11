/**
* @author Sagie Twig
* The apex controller for handling the status flow settings component including path settings and training status settings
*/

public with sharing class  DocumentRelationship {
    
    @AuraEnabled
    public static String getAffectedRecords (Id parentId)
    {
        List<AffectedItem> aiList = new List<AffectedItem>();
        Simploud__Controlled_Document__c currentDoc = [Select Id, Simploud__Version__c ,Document__c,Simploud__Previous_Version__c, Simploud__Status__c From Simploud__Controlled_Document__c 
                                                       Where Id =: parentId Limit 1];
        String effectiveId;
        String obsoleteId;
        String docNumber = currentDoc.Document__c;
        String docStatus = currentDoc.Simploud__Status__c;
        if (docStatus == 'Effective')
        {
            AffectedItem aItem = new AffectedItem();
            effectiveId = currentDoc.Id;
            obsoleteId =  currentDoc.Simploud__Previous_Version__c;
        }        
        else if (docStatus == 'Cancelled' || docStatus == 'Obsolete' )
        {
            obsoleteId = currentDoc.Id;
            List<Simploud__Controlled_Document__c> docList = new List<Simploud__Controlled_Document__c>();
            docList = [Select Id, Simploud__Version__c	,Document__c, Simploud__Status__c , CreatedDate From Simploud__Controlled_Document__c 
                       Where Document__c =: docNumber AND Simploud__Status__c = 'Effective'];
            
            if (!docList.isEmpty())
            {
                effectiveId = docList[0].Id;
            }
        }
        
        if (effectiveId == null || obsoleteId == null)
        {
            return 'No Applicable Documents Available';
        }
        else
        {
            
            List<Simploud__Trial__c> trialList = new List<Simploud__Trial__c>();
            trialList = [Select ID, Name, RecordingreportingInstruction__c,  Controlled_Document__c,  Privacy_Statement__c 
                         From Simploud__Trial__c WHERE RecordingreportingInstruction__c =: obsoleteId OR 
                         Controlled_Document__c =: obsoleteId OR Privacy_Statement__c =: obsoleteId];
            
            if (!trialList.isEmpty())
            {
                for (Simploud__Trial__c trial_i: trialList)
                {
                    if (trial_i.RecordingreportingInstruction__c != null && trial_i.RecordingreportingInstruction__c == obsoleteId)
                    {
                        AffectedItem aItem = new AffectedItem();
                        aItem.objectLabel = 'Trial';
                        aItem.recordId = trial_i.Id;
                        aItem.recordName = trial_i.Name;
                        aItem.linkingField = 'Client Recording & Reporting Instruction' ; 
                        aItem.linkingFieldName = 'RecordingreportingInstruction__c';
                        aItem.obsoleteId = obsoleteId;
                        aItem.effectiveId = effectiveId;
                        aiList.add(aItem);
                        system.debug('aItem === '+aItem);
                    }
                    else if (trial_i.Controlled_Document__c != null && trial_i.Controlled_Document__c == obsoleteId)
                    {
                        AffectedItem aItem = new AffectedItem();
                        aItem.objectLabel = 'Trial';
                        aItem.recordId = trial_i.Id;
                        aItem.recordName = trial_i.Name;
                        aItem.linkingField = 'Sponsor Specific Instructions' ;  
                        aItem.linkingFieldName = 'Controlled_Document__c'; 
                        aItem.obsoleteId = obsoleteId;
                        aItem.effectiveId = effectiveId;
                        aiList.add(aItem);
                        system.debug('aItem === '+aItem);
                    }
                    else if (trial_i.Privacy_Statement__c != null && trial_i.Privacy_Statement__c == obsoleteId)
                    {
                        AffectedItem aItem = new AffectedItem();
                        aItem.objectLabel = 'Trial';
                        aItem.recordId = trial_i.Id;
                        aItem.recordName = trial_i.Name;
                        aItem.linkingField = 'Privacy Statement' ;    
                        aItem.linkingFieldName = 'Privacy_Statement__c'; 
                        aItem.obsoleteId = obsoleteId;
                        aItem.effectiveId = effectiveId;
                        aiList.add(aItem);
                        system.debug('aItem === '+aItem);
                    }
                }
            }
            
            List<Account> accountList = new  List<Account>();
            accountList = [Select ID,Name, Client_Recording_Reporting_Instruction__c ,  Controlled_Document__c,  Privacy_Statement__c 
                           From Account WHERE Client_Recording_Reporting_Instruction__c =: obsoleteId OR 
                           Controlled_Document__c =: obsoleteId OR Privacy_Statement__c =: obsoleteId];
            if (!accountList.isEmpty())
            {
                for (Account account_i: accountList)
                {
                    if (account_i.Client_Recording_Reporting_Instruction__c != null && account_i.Client_Recording_Reporting_Instruction__c == obsoleteId)
                    {
                        AffectedItem aItem = new AffectedItem();
                        aItem.objectLabel = 'Account';
                        aItem.recordId = account_i.Id;
                        aItem.recordName = account_i.Name;
                        aItem.linkingField = 'Client Recording & Reporting Instruction' ;  
                        aItem.linkingFieldName = 'Client_Recording_Reporting_Instruction__c';  
                        aItem.obsoleteId = obsoleteId;
                        aItem.effectiveId = effectiveId;
                        aiList.add(aItem);
                        system.debug('aItem === '+aItem);
                    }
                    else if (account_i.Controlled_Document__c != null && account_i.Controlled_Document__c == obsoleteId)
                    {
                        AffectedItem aItem = new AffectedItem();
                        aItem.objectLabel = 'Account';
                        aItem.recordId = account_i.Id;
                        aItem.recordName = account_i.Name;
                        aItem.linkingField = 'Sponsor Specific Instructions' ;
                        aItem.linkingFieldName = 'Controlled_Document__c';     
                        aItem.obsoleteId = obsoleteId;
                        aItem.effectiveId = effectiveId;
                        aiList.add(aItem);
                        system.debug('aItem === '+aItem);
                    }
                    else if (account_i.Privacy_Statement__c != null && account_i.Privacy_Statement__c == obsoleteId)
                    {
                        AffectedItem aItem = new AffectedItem();
                        aItem.objectLabel = 'Account';
                        aItem.recordId = account_i.Id;
                        aItem.recordName = account_i.Name;
                        aItem.linkingField = 'Privacy Statement' ;   
                        aItem.linkingFieldName = 'Privacy_Statement__c';    
                        aItem.obsoleteId = obsoleteId;
                        aItem.effectiveId = effectiveId;
                        aiList.add(aItem);
                        system.debug('aItem === '+aItem);
                    }
                }
            }
            
            List<Simploud__Document_Item__c> docItemList = new  List<Simploud__Document_Item__c>();
            docItemList = [Select Id, Name, Linked_Document__c From Simploud__Document_Item__c WHERE Linked_Document__c =: obsoleteId ];
            if (!docItemList.isEmpty())
            {
                for (Simploud__Document_Item__c doc_i: docItemList)
                {
                    AffectedItem aItem = new AffectedItem();
                    aItem.objectLabel = 'Document';
                    aItem.recordId = doc_i.Id;
                    aItem.recordName = doc_i.Name;
                    aItem.linkingField = 'Linked Document' ;   
                    aItem.linkingFieldName = 'Linked_Document__c';  
                    aItem.obsoleteId = obsoleteId;
                    aItem.effectiveId = effectiveId;
                    aiList.add(aItem);
                    system.debug('aItem === '+aItem);
                }
            }
            
            List<Simploud__Trial_Item__c> trialItemList = new  List<Simploud__Trial_Item__c>();
            trialItemList = [Select Id, Name, Controlled_Document__c From Simploud__Trial_Item__c WHERE Controlled_Document__c =: obsoleteId ];
            if (!trialItemList.isEmpty())
            {
                for (Simploud__Trial_Item__c doc_i: trialItemList)
                {
                    AffectedItem aItem = new AffectedItem();
                    aItem.objectLabel = 'Trial Document';
                    aItem.recordId = doc_i.Id;
                    aItem.recordName = doc_i.Name;
                    aItem.linkingField = 'Trial Document' ;   
                    aItem.linkingFieldName = 'Controlled_Document__c';  
                    aItem.obsoleteId = obsoleteId;
                    aItem.effectiveId = effectiveId;
                    aiList.add(aItem);
                    system.debug('aItem === '+aItem);
                }
            }       
            
            List<Simploud__Training_Item__c> trainingItemList = new  List<Simploud__Training_Item__c>();
            trainingItemList = [Select Id, Name, Controlled_Document__c From Simploud__Training_Item__c WHERE Controlled_Document__c =: obsoleteId ];
            if (!trainingItemList.isEmpty())
            {
                for (Simploud__Training_Item__c doc_i: trainingItemList)
                {
                    AffectedItem aItem = new AffectedItem();
                    aItem.objectLabel = 'Training Document';
                    aItem.recordId = doc_i.Id;
                    aItem.recordName = doc_i.Name;
                    aItem.linkingField = 'Training Document' ;   
                    aItem.linkingFieldName = 'Controlled_Document__c';  
                    aItem.obsoleteId = obsoleteId;
                    aItem.effectiveId = effectiveId;
                    aiList.add(aItem);
                    system.debug('aItem === '+aItem);
                }
            }
            
            if (aiList.isEmpty())
                return 'No Items Affected';
            else return JSON.serialize(aiList);
            
        }
        
    }
    
    @AuraEnabled
    public static String updateDocLinks (String aiString )
    {
        
        List<AffectedItem> aiList = (List<AffectedItem>)JSON.deserialize(aiString, List<AffectedItem>.class);
        List<Simploud__Trial__c> trialList = new List<Simploud__Trial__c>();
        List<Account> accountList = new  List<Account>();
        List<Simploud__Document_Item__c> docList = new  List<Simploud__Document_Item__c>();
        List<Simploud__Trial_Item__c> trialItemList = new  List<Simploud__Trial_Item__c>();
        List<Simploud__Training_Item__c> trainingItemList = new  List<Simploud__Training_Item__c>();
        
        system.debug('aiList.length'+aiList.size());
        for (AffectedItem ai : aiList)
        {
            system.debug('ai'+ai);
            if (ai.objectLabel == 'Trial')
            {
                Simploud__Trial__c trial_i = new Simploud__Trial__c();
                trial_i.Id = ai.recordId;
                trial_i.put(ai.linkingFieldName,ai.effectiveId);
                trialList.add(trial_i);
                system.debug('Trial ===' + trial_i);
            }
            else if (ai.objectLabel == 'Account')
            {
                Account account_i = new Account();
                account_i.Id = ai.recordId;
                account_i.put(ai.linkingFieldName,ai.effectiveId);
                accountList.add(account_i);
                system.debug('Account ===' + account_i);
            }
            else if (ai.objectLabel == 'Document')
            {
                Simploud__Document_Item__c doc_i = new Simploud__Document_Item__c();
                doc_i.Id = ai.recordId;
                doc_i.put(ai.linkingFieldName,ai.effectiveId);
                docList.add(doc_i);
                system.debug('Doc ===' + doc_i);
            }
            
            else if (ai.objectLabel == 'Trial Document')
            {
                Simploud__Trial_Item__c doc_i = new Simploud__Trial_Item__c();
                doc_i.Id = ai.recordId;
                doc_i.put(ai.linkingFieldName,ai.effectiveId);
                trialItemList.add(doc_i);
                system.debug('Doc ===' + doc_i);
            }
            
            else if (ai.objectLabel == 'Training Document')
            {
                Simploud__Training_Item__c doc_i = new Simploud__Training_Item__c();
                doc_i.Id = ai.recordId;
                doc_i.put(ai.linkingFieldName,ai.effectiveId);
                trainingItemList.add(doc_i);
                system.debug('Doc ===' + doc_i);
            }
        }
        
        try
        {
            if (!trialList.isEmpty()) 
            {
                update trialList;
            }
            if (!accountList.isEmpty()) 
            {
                update accountList;
            }
            if (!docList.isEmpty()) 
            {
                update docList;
            }
            
            if (!trialItemList.isEmpty()) 
            {
                update trialItemList;
            }
            if (!trainingItemList.isEmpty()) 
            {
                update trainingItemList;
            }
            return 'Success';
        }
        catch (exception e)
        {
            return 'The records were not update due to '+string.valueOf(e);
        }
        
    }
    
    public class AffectedItem {
        public String objectLabel { get; set;}
        public String recordId { get; set; }
        public String recordName { get; set;}
        public String linkingField { get; set;}  
        public String linkingFieldName { get; set;} 
        public String obsoleteId { get; set;}
        public String effectiveId { get; set;}
        public String comments { get; set;}
    }
}