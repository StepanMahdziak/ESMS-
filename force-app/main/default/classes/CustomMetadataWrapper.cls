/*
    Created by RedTag129 on 07.12.2019
 */
public with sharing class CustomMetadataWrapper {
        public String authProvider;
        public String sitePath;
        public String sharePointUrl;
        public String controlledDocsFolder;
        public String generalDocsFolder;
        public String lockedDocsFolder;
        public String controlledDocField;
        public String generalDocField;  
        public String lockedDocField;
    
    
    public CustomMetadataWrapper(String authProviderParam,String sitePathParam,String sharePointUrlParam,String controlledDocsFolderParam,String generalDocsFolderParam, String lockedDocsFolderParam, String controlledDocFieldParam, String generalDocFieldParam, String lockedDocfieldParam){
        authProvider = authProviderParam;
        sitePath = sitePathParam;
        sharePointUrl = sharePointUrlParam;
        controlledDocsFolder = controlledDocsFolderParam;
        generalDocsFolder = generalDocsFolderParam;
        lockedDocsFolder = lockedDocsFolderParam;
        controlledDocField = controlledDocFieldParam;
        generalDocField = generalDocFieldParam;
        lockedDocField = lockedDocfieldParam;
    }

    public CustomMetadataWrapper() {}

 }