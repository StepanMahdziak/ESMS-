import { LightningElement, wire, track, api } from 'lwc';
import retriveFilesFromControlledDocumentsById from '@salesforce/apex/PreviewComponentController.retriveFilesFromControlledDocumentsById';
import getControlledDocumentsById from '@salesforce/apex/PreviewComponentController.getControlledDocumentsById';
import getTrainingMaterialsById from '@salesforce/apex/PreviewComponentController.getTrainingMaterialsById';
import retriveFilesFromTrainingMtById from '@salesforce/apex/PreviewComponentController.retriveFilesFromTrainingMtById';
import { NavigationMixin } from 'lightning/navigation';

export default class FilePrivew extends NavigationMixin(LightningElement) {
    @track files =[];
    @track controlledDocuments =[];
    @track trainingMaterials = [];
    @track activeSectionMessage = '';
    @track showControlledDocuments;
    @track showTrainingMaterials;
    @track showFiles;
    @track showTMFile;
    @api recordId;
   

   
    @wire(retriveFilesFromControlledDocumentsById, {taskId:'$recordId' })
    filesData({data, error}) {
        if(data) {
            if(data.length > 0)
            this.showFiles = true;
            this.files = data;
            
        }   
        else if(error) {
            window.console.log('error ===> '+JSON.stringify(error));
        }
    }

    @wire(getControlledDocumentsById, {taskId:'$recordId' })
    docData({data, error}) {
        if(data) {
            if(data.length > 0)
            this.showControlledDocuments = true;
            this.controlledDocuments = data;  
            console.log('this.this.documents >> ' +  this.controlledDocuments );

        }   
        else if(error) {
            window.console.log('error ===> '+JSON.stringify(error));
        }
    }

    @wire(getTrainingMaterialsById, {taskId:'$recordId' })
    trainingMtData({data, error}) {
        if(data) {
            if(data.length > 0)
            this.showTrainingMaterials = true;
            this.trainingMaterials = data;
            console.log('this.trainingTrails>> ' +  this.trainingMaterials);
            window.console.log('trainingTrails>> ' +  data.Course_length_hours__c[0]);

        }   
        else if(error) {
            window.console.log('error ===> '+JSON.stringify(error));
        }
    }

    @wire(retriveFilesFromTrainingMtById, {taskId:'$recordId' })
    trainingMtRetriveFile({data, error}) {
        if(data) {
            if(data.length > 0)
            this.showTMFile = true;
            this.trainingMaterialsFile = data;
            console.log('this.trainingTrails>> ' +  this.trainingMaterialsFile);
        }   
        else if(error) {
            window.console.log('error ===> '+JSON.stringify(error));
        }
    }



    filePreview(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {   
                selectedRecordId:event.currentTarget.dataset.id
            }
          })
    }

    redirect(event){
        var fileId = event.currentTarget.dataset.id;
        this.files.forEach( ef => {
            if(fileId == ef.ContentDocumentId){
                if(ef.FileExtension == 'pdf'){
                    var url = ef.ExternalDocumentInfo1;
                    window.open(url, '_blank');
                 }
                    if(ef.FileExtension != 'pdf'){
                    var url = ef.ExternalDocumentInfo1.replace('edit', 'view');
                    window.open(url, '_blank');
                 }
            }
        });
       
    }

    handleToggleSection(event) {
        this.activeSectionMessage =
            'Open section name:  ' + event.detail.openSections;
    }


   

//   renderedCallback() {
//     const style = document.createElement('style');
//     style.innerText = `c-file-Preview .slds-accordion__summary-action {
//         display: inline-flex;
//         flex-grow: 1;
//         align-items: center;
//         min-width: 0;
//         color: white;
//         font-size: 1.75rem;
//         font-weight: 300;   
//         background-color: rgb(112, 110, 107);
//         line-height:1.25;
//         pointer-events: none;
//     }`;
//     this.template.querySelector('lightning-accordion-section').appendChild(style);
// }
}   