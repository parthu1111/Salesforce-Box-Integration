import { api, LightningElement, track } from 'lwc';
import submitFormWithFile from "@salesforce/apex/onlineLeadFromController.submitFormWithFile";
import image1 from '@salesforce/resourceUrl/loanFormImage1';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyRecaptcha from '@salesforce/apex/onlineLeadFromController.verifyCaptcha';
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

    //@api formToken;
    @track isValidReCAPTCHA = false;


    connectedCallback() {
        document.addEventListener("grecaptchaVerified",this.boundGrecaptchaVerifiedHandler.bind(this));

        document.addEventListener("grecaptchaError", this.boundGrecaptchaErrorHandler.bind(this));
    }

    renderedCallback() {
        //document.dispatchEvent(new CustomEvent("grecaptchaExecute", {"detail": {action: "LOGIN"}}));
    }

    disconnectedCallback() {
        document.removeEventListener("grecaptchaVerified", this.boundGrecaptchaVerifiedHandler);
        document.removeEventListener("grecaptchaError", this.boundGrecaptchaErrorHandler);
    }

    boundGrecaptchaVerifiedHandler(e) {
        verifyRecaptcha({ record: null, //TODO: map UI fields to sobject
            recaptchaResponse: e.detail.response})
            .then((result)=> {
                console.log(result);
                //document.dispatchEvent(new Event("grecaptchaReset"));
                //alert(result);
                if(result=="Success"){
                    console.log("recaptcha verified");
                    this.handleSubmitForm();
                    this.isValidReCAPTCHA=true;
                }
                else{
                    console.log("recaptcha not verified");
                    this.isValidReCAPTCHA=false;
                    this.disableBtn=false;
                }
                
            })
            .catch(error => {
                this.disableBtn=false;
                console.log(error);
            });
    }
    boundGrecaptchaErrorHandler(e) {
        console.log("something wrong with recaptcha");
    }
    
    handleClick(event) {
        console.log('handleclikc called!');
        this.disableBtn=true;
        console.log("validtion flag : "+this.isValidReCAPTCHA);
        if(this.isValidReCAPTCHA==false){
            document.dispatchEvent(new CustomEvent("grecaptchaExecute", {"detail": {action: "LOGIN"}}));
        }
        else{
            this.handleSubmitForm();
        }
        
    }

    handleSubmitForm() {
        this.disableBtn=true;
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => validSoFar && inputCmp.checkValidity(), true);

        if (!allValid) {
            [...this.template.querySelectorAll('lightning-input')].forEach(inputCmp => inputCmp.reportValidity());
            this.disableBtn=false;
            return;
        }
        //console.log(this.selectedFiles);
        console.log(this.selectedFiles.length);
        if(this.selectedFiles.length==0){
            const fileInput = this.template.querySelector('[data-id="fileInput"]');
            fileInput.setCustomValidity('pls select valid files.');
            fileInput.reportValidity();
            this.disableBtn=false;
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
                console.error('Error in submitting form:', error.body.message);
                this.showToast('Error', 'something went wrong!', 'error');
            })
            .finally(() => {
                this.disableBtn=false;
            });
    }


    handleFileUpload(event) {
        this.selectedFiles=[];
        const files = event.target.files;
        const fileInput=event.target;
        //reset validation.
        fileInput.setCustomValidity('');
        fileInput.reportValidity();
        this.disableBtn=true;
        let totalProcessFiles=0;
        let totalFiles=files.length;
        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            console.log(file);
            
            const now = new Date();
            if (file.size > 50 * 1024 * 1024) {
                this.showToast('Error', 'File size cannot exceed 50MB', 'error');
                this.selectedFiles=[];
                this.disableBtn=false;
                return;
            }
            this.selectedFiles.push({
                fileName: file.name,
                //size: file.size,
                //type: file.type,
                fileContent: null, // Will hold the base64 content
                //fileBlob: file      // File Blob for future use
            });
    
            // Optional: Read file content (e.g., for Base64 conversion)
            let buttonVisiblity=i!=files.length-1?true:false;
            this.readFile(file, i,()=>{
                totalProcessFiles++;
                if(totalProcessFiles==totalFiles){
                    this.disableBtn=false;
                }
            });
        }
    }
    readFile(file, index,callback) {
        const reader = new FileReader();
        reader.onload = () => {
            this.selectedFiles[index].fileContent = reader.result.split(',')[1]; // Remove the Data URL prefix
            //this.selectedFiles[index].fileContent = reader.result;
            //console.log(JSON.stringify(this.selectedFiles[index]));
            //console.log(this.selectedFiles[index].fileContent.length);
            callback();
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
        this.selectedFiles = [];
    }

   
}