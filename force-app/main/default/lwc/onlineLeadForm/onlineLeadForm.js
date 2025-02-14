import { api, LightningElement, track } from 'lwc';
import getFolderID from "@salesforce/apex/onlineLeadFromController.getFolderID";
import image1 from '@salesforce/resourceUrl/loanFormImage1';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyRecaptcha from '@salesforce/apex/onlineLeadFromController.verifyCaptcha';
import getToken from '@salesforce/apex/boxFormHelperMethods.getToken';
import sendEmail from '@salesforce/apex/boxFormHelperMethods.sendEmail';
import getBackupFolder from '@salesforce/apex/boxFormHelperMethods.getBackupFolder';
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
    @track disableBtn = false;

    //@api formToken;
    @track isValidReCAPTCHA = false;


    connectedCallback() {
        document.addEventListener("grecaptchaVerified", this.boundGrecaptchaVerifiedHandler.bind(this));

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
        verifyRecaptcha({
            record: null, //TODO: map UI fields to sobject
            recaptchaResponse: e.detail.response
        })
            .then((result) => {
                console.log(result);
                //document.dispatchEvent(new Event("grecaptchaReset"));
                //alert(result);
                if (result == "Success") {
                    console.log("recaptcha verified");
                    this.handleSubmitForm();
                    this.isValidReCAPTCHA = true;
                }
                else {
                    console.log("recaptcha not verified");
                    this.isValidReCAPTCHA = false;
                    this.disableBtn = false;
                }

            })
            .catch(error => {
                this.disableBtn = false;
                console.log(error);
            });
    }
    boundGrecaptchaErrorHandler(e) {
        console.log("something wrong with recaptcha");
    }

    handleClick(event) {
        console.log('handleclikc called!');
        this.disableBtn = true;
        console.log("validtion flag : " + this.isValidReCAPTCHA);
        if (this.isValidReCAPTCHA == false) {
            document.dispatchEvent(new CustomEvent("grecaptchaExecute", { "detail": { action: "LOGIN" } }));
        }
        else {
            this.handleSubmitForm();
        }

    }

    async handleSubmitForm() {
        try {
            this.disableBtn = true;
            const allValid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputCmp) => validSoFar && inputCmp.checkValidity(), true);

            if (!allValid) {
                [...this.template.querySelectorAll('lightning-input')].forEach(inputCmp => inputCmp.reportValidity());
                this.disableBtn = false;
                return;
            }
            //console.log(this.selectedFiles);
            console.log(this.selectedFiles.length);
            if (this.selectedFiles.length == 0) {
                const fileInput = this.template.querySelector('[data-id="fileInput"]');
                fileInput.setCustomValidity('pls select valid files.');
                fileInput.reportValidity();
                this.disableBtn = false;
                return;
            }
            const payload = {
                ...this.formData
                //files: this.selectedFiles
                //fileName: this.fileName,
                //fileContent: this.fileContent,
            };

            try {
                // Fetch folder IDs and perform actions
                const [res, backupFolderId] = await Promise.all([
                    getFolderID({ formData: payload }),
                    getBackupFolder({ name: this.formData.name, email: this.formData.email })
                ]);
                console.log("folder response");
                
                console.log(JSON.stringify(res));
                console.log(res.folderId);
                let folderID=res.folderId;
                //console.log('Folder ID:', folderID);
                console.log('Backup Folder ID:', backupFolderId);

                const token = await getToken();
                console.log('Token:', token);

                if (!token) throw new Error('Error obtaining token');
                if (!folderID || !backupFolderId) throw new Error('Error obtaining folder IDs');

                // // Upload files and send email
                // this.uploadFilesToBox(folderID, token);
                // this.uploadFilesToBox(backupFolderId, token);

                try {
                    await Promise.all([
                        this.uploadFilesToBox(folderID, token), // Upload to main folder
                        this.uploadFilesToBox(backupFolderId, token) // Upload to backup folder
                    ]);
                } catch (error) {
                    console.log('Error uploading files:', error);
                    
                    //console.error('Error during file upload:', error);
                    throw error;
                }

                try{
                    //await sendEmail({ email: this.formData.email, customerFolderId: folderID });
                    if(res.loanId!=null && res.loanId!=''){
                        await sendEmail({ loanId: res.loanId, customerFolderId: folderID });
                    }
                }
                catch(error){
                    //console.error('Error sending email:', error);
                    throw error;
                }
                this.showToast('Success', 'Form submitted successfully!', 'success');
                this.resetForm();
            } catch (error) {
                //console.error('Error in form submission:', error);
                throw error;
            }
        } catch (error) {
            console.error('Unexpected error:', error.message);
            this.handleError(error, 'Unexpected error occurred.');
        } finally {
            this.disableBtn = false;
        }

    }



    get areFileExist() {
        return this.selectedFiles.length > 0;
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

    handleFileUpload(event) {
        this.selectedFiles = [];
        const files = event.target.files;
        const fileInput = event.target;
        //reset validation.
        fileInput.setCustomValidity('');
        fileInput.reportValidity();
        this.disableBtn = true;
        let totalProcessFiles = 0;
        let totalFiles = files.length;
        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            console.log(file);

            const now = new Date();
            if (file.size > 50 * 1024 * 1024) {
                this.showToast('Error', 'File size cannot exceed 50MB', 'error');
                this.selectedFiles = [];
                this.disableBtn = false;
                return;
            }
            const formattedDateTime = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}-${String(now.getMinutes()).padStart(2, '0')}-${String(now.getSeconds()).padStart(2, '0')}`;
            // Append datetime to the file name
            const updatedFileName = `${file.name.split('.').slice(0, -1).join('.')}-${formattedDateTime}.${file.name.split('.').pop()}`;

            this.selectedFiles.push({
                fileName: updatedFileName,
                fileType: file.type,
                //size: file.size,
                //type: file.type,
                fileContent: null, // Will hold the base64 content
                //fileBlob: file      // File Blob for future use
            });

            // Optional: Read file content (e.g., for Base64 conversion)
            let buttonVisiblity = i != files.length - 1 ? true : false;
            this.readFile(file, i, () => {
                totalProcessFiles++;
                if (totalProcessFiles == totalFiles) {
                    this.disableBtn = false;
                }
            });
        }
    }
    readFile(file, index, callback) {
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

    // async uploadFilesToBox(folderId, accessToken) {
    //     try {
    //         if (accessToken != null && folderId != null) {
                
    //             for (let i = 0; i < this.selectedFiles.length; i++) {
    //                 const file = this.selectedFiles[i];
    //                 console.log("Uploading file: " + file.fileName);
    //                 const formData = new FormData();
    //                 formData.append('attributes', JSON.stringify({
    //                     name: file.fileName,
    //                     parent: { id: folderId }
    //                 }));
    //                 // Convert the base64 file content to a Blob
    //                 const fileBlob = this.base64ToBlob(file.fileContent, file.fileType);
    //                 formData.append('file', fileBlob, file.fileName);
    //                 // Upload the file to Box
    //                 try{
    //                     await this.uploadToBox(formData, accessToken);
    //                 }catch(err){
    //                     throw err;
    //                 }
    //             }
    //         }
    //     }
    //     catch (error) {
    //         //console.log(error);
    //         throw error;
    //     }
    // }

    // async uploadToBox(formData, accessToken) {
    //     try {
    //         const response = await fetch('https://upload.box.com/api/2.0/files/content', {
    //             method: 'POST',
    //             headers: {
    //                 //'Authorization': `Bearer ${accessToken}`
    //             },
    //             body: formData
    //         });
    
    //         console.log('HTTP Status Code:', response.status); // Log status code
    
    //         if (response.status === 201) {
    //             const data = await response.json(); // Parse JSON if status is 201
    //             if (data.entries != null && data.entries.length > 0 && data.entries[0].id) {
    //                 console.log('File uploaded successfully:', data);
    //             } else {
    //                 console.error('Error uploading file:', data);
    //             }
    //         } else {
    //             throw new Error(`HTTP Error: ${response.status} ${response.statusText}`);
    //         }
    //     } catch (error) {
    //         console.log('Error in uploadToBox:', error.message);
    //         throw error; // Propagate the error to the caller
    //     }
    // }

    uploadFilesToBox(folderId, accessToken) {
        return new Promise((resolve, reject) => {
            try {
                if (accessToken != null && folderId != null) {
                    let uploadPromises = [];
    
                    for (let i = 0; i < this.selectedFiles.length; i++) {
                        const file = this.selectedFiles[i];
                        console.log("Uploading file: " + file.fileName);
    
                        const formData = new FormData();
                        formData.append('attributes', JSON.stringify({
                            name: file.fileName,
                            parent: { id: folderId }
                        }));
    
                        // Convert the base64 file content to a Blob
                        const fileBlob = this.base64ToBlob(file.fileContent, file.fileType);
                        formData.append('file', fileBlob, file.fileName);
    
                        // Push the Promise to the array
                        uploadPromises.push(this.uploadToBox(formData, accessToken));
                    }
    
                    // Wait for all file uploads to finish
                    Promise.all(uploadPromises)
                        .then(() => {
                            resolve('All files uploaded successfully');
                        })
                        .catch((error) => {
                            reject(`Error uploading files: ${error.message}`);
                        });
                } else {
                    reject('Invalid access token or folder ID');
                }
            } catch (error) {
                reject(`Error in uploadFilesToBox: ${error.message}`);
            }
        });
    }
    
    uploadToBox(formData, accessToken) {
        return new Promise((resolve, reject) => {
            try {
                fetch('https://upload.box.com/api/2.0/files/content', {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${accessToken}`
                    },
                    body: formData
                })
                    .then(response => {
                        console.log('HTTP Status Code:', response.status); // Log status code
    
                        if (response.status === 201) {
                            response.json().then((data) => {
                                if (data.entries != null && data.entries.length > 0 && data.entries[0].id) {
                                    console.log('File uploaded successfully:', data);
                                    resolve(); // Resolve the promise if the file is uploaded successfully
                                } else {
                                    reject('Error uploading file: No valid entry returned');
                                }
                            });
                        } else {
                            reject(`HTTP Error: ${response.status} ${response.statusText}`);
                        }
                    })
                    .catch(error => {
                        reject(`Error in uploadToBox: ${error}`);
                    });
            } catch (error) {
                reject(`Error in uploadToBox: ${error.message}`);
            }
        });
    }
    base64ToBlob(base64, mimeType) {
        try {
            // Ensure the Base64 string is properly padded
            base64 = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, '=');

            // Decode Base64 to binary
            const byteCharacters = atob(base64);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);

            // Create and return Blob
            return new Blob([byteArray], { type: mimeType });
        } catch (error) {
            console.error('Error converting Base64 to Blob:', error);
            throw error;
        }
    }

    handleError(error, message) {
        //console.error('Error details:', error);
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

}