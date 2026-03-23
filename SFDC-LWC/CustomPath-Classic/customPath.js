import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getPicklistWrap from '@salesforce/apex/COMM_Util.getPicklistWrap';

export default class LseCustomPath extends LightningElement {
    @api recordId;
    @api objectName;
    @api fieldName;

    selectedValue;
    pickList = [];

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

            // 각 Picklist 항목에 대해 스타일 클래스 설정
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

            // 선택된 항목 이전 단계는 완료 상태로 표시
            if (selectedIndex > 0) {
                for (let i = 0; i < selectedIndex; i++) {
                    itemsList[i].classList = 'slds-path__item slds-is-complete';
                }
            }
        }
        
        return itemsList;
    }
}
