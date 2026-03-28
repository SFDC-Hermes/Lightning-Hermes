import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getPicklistWrap from '@salesforce/apex/COMM_Util.getPicklistWrap';

export default class LseCustomPath extends LightningElement {
    @api recordId;
    @api objectName;
    @api fieldName;

    selectedValue;
    pickList = [];

    showSpinner = false;

    get fieldsToQuery() {
        if (this.objectName && this.fieldName) {
            return [`${this.objectName}.${this.fieldName}`];
        }
        return [];
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldsToQuery' })
    wiredRecord({ error, data }) {
        if (data) {
            if (this.fieldName && data.fields && data.fields[this.fieldName]) {
                this.selectedValue = data.fields[this.fieldName].value;
            }
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    connectedCallback() {
        this.fetchPicklistOptions();
    }

    async fetchPicklistOptions() {
        try {
            const picklistResult = await getPicklistWrap({ 
                objectName: this.objectName, 
                fieldName: this.fieldName 
            });
            this.pickList = picklistResult ? [...picklistResult] : [];
        } catch (error) {
            console.error('Error in fetchPicklistOptions:', error);
        }
    }

    get picklistValues() {
        let itemsList = [];
        
        if (Array.isArray(this.pickList)) {
            let selectedIndex = -1;

            this.pickList.forEach((picklistEntry, index) => {
                let classList = 'slds-path__item slds-is-incomplete';
                
                if (picklistEntry.value === this.selectedValue) {
                    classList = 'slds-path__item slds-is-current slds-is-active';
                    selectedIndex = index;
                }
                
                itemsList.push({
                    pItem: picklistEntry,
                    classList: classList
                });
            });

            if (selectedIndex > 0) {
                for (let i = 0; i < selectedIndex; i++) {
                    itemsList[i].classList = 'slds-path__item slds-is-complete';
                }
            }
        }
        
        return itemsList;
    }
}
