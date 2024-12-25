import { api, LightningElement, track } from 'lwc';
import submitFormWithFile from "@salesforce/apex/onlineLeadFromController.submitFormWithFile";
import image1 from '@salesforce/resourceUrl/loanFormImage1';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OnlineLeadForm extends LightningElement {
    @track formData = {
        name: null,
        email: null,
        mobile: null
    };
    fileContent = '';
    fileName = '';
    @track selectedFiles = [];
    image1URL = image1;
    @track disableBtn=false;

    handleClick(event) {
        console.log('handleclikc called!');
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => validSoFar && inputCmp.checkValidity(), true);

        if (!allValid) {
            [...this.template.querySelectorAll('lightning-input')].forEach(inputCmp => inputCmp.reportValidity());
            return;
        }

        const payload = {
            ...this.formData,
            files: this.selectedFiles
            //fileName: this.fileName,
            //fileContent: this.fileContent,
        };
        //console.log('payload : '+JSON.stringify(this.selectedFiles));
        submitFormWithFile({ formData: payload})
            .then((res) => {
                console.log(res);
                this.showToast('Success', 'Form submitted successfully!', 'success');
                this.resetForm();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleFileUpload(event) {
       //const file = event.target.files[0];
        
        // if (file) {
        //     this.fileName = file.name;

        //     const reader = new FileReader();
        //     reader.onload = () => {
        //         this.fileContent = reader.result.split(',')[1]; // Get Base64 content
        //         this.disableBtn=false;
        //     };
        //     reader.readAsDataURL(file);
        // }
        this.selectedFiles=[];
        const files = event.target.files;
        this.disableBtn=true;
        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            this.selectedFiles.push({
                fileName: file.name,
                //size: file.size,
                //type: file.type,
                fileContent: null, // Will hold the base64 content
                //fileBlob: file      // File Blob for future use
            });
    
            // Optional: Read file content (e.g., for Base64 conversion)
            let buttonVisiblity=i!=files.length-1?true:false;
            this.readFile(file, i,buttonVisiblity);
        }
    }
    readFile(file, index,buttonVisiblity) {
        const reader = new FileReader();
        reader.onload = () => {
            this.selectedFiles[index].fileContent = reader.result.split(',')[1]; // Remove the Data URL prefix
            this.disableBtn=buttonVisiblity;
        };
        reader.onerror = (error) => {
            console.error('Error reading file:', error);
        };
        reader.readAsDataURL(file);
    }
    get areFileExist(){
        return this.selectedFiles.length>0;
    }
    handleInputChange(event) {
        const field = event.target.name;
        this.formData[field] = event.target.value;
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

    resetForm() {
        this.formData = { name: '', phone: '', email: '' };
        this.fileContent = '';
        this.fileName = '';
    }
}