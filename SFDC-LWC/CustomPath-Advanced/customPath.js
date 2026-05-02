/**
 * @description       : 
 * @author            : SFDC-Hermes
 * @group             : 
 * @last modified on  : 2026-04-19
 * @last modified by  : SFDC-Hermes
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2026-04-19   SFDC-Hermes   Initial Version
 **/
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue as getRecordFieldValue } from 'lightning/uiRecordApi';
import getPicklistWrapWire from '@salesforce/apex/COMM_Util.getPicklistWrapWire';

import { CurrentPageReference } from 'lightning/navigation';

export default class CustomPath extends LightningElement {
    @api recordId;
    @api objectName;
    @api fieldName;
    @api errorValue;
    @api endValue;
    @api replaceToValue;
    @api booleanValue;
    @api booleanPickValue;
    @api replaceFromValue;

    showSpinner = false;
    selectedValue;
    pickList = [];
    recordBooleanValue;
    pickValue;
    
    @wire(CurrentPageReference)
    pageRef;

    get fieldsToQuery() {
        const fields = [];
        if (this.objectName && this.fieldName) {
            fields.push(`${this.objectName}.${this.fieldName}`);
        }
        if (this.objectName && this.booleanValue) {
            fields.push(`${this.objectName}.${this.booleanValue}`);
        }
        return fields;
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldsToQuery' })
    wiredRecord({ error, data }) {
        if (data) {
            if (this.fieldName && data.fields && data.fields[this.fieldName]) {
                this.pickValue = data.fields[this.fieldName].value;
                this.selectedValue = data.fields[this.fieldName].value;
            }
            if (this.booleanValue && data.fields && data.fields[this.booleanValue]) {
                this.recordBooleanValue = data.fields[this.booleanValue].value;
            }
            this.processPickList();
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    connectedCallback() {
        this.fetchPicklistOptions();
    }

    endValues = [];
    booleanPickValues = [];
    originalPickList = []; 

    async fetchPicklistOptions() {
        try {
            if (this.pageRef) {
                const state = this.pageRef.attributes;
                this.recordId = state.recordId;
            }

            const picklistResult = await getPicklistWrapWire({ objectName: this.objectName, fieldName: this.fieldName });
            this.originalPickList = picklistResult ? [...picklistResult] : [];
            
            if(this.endValue){
                this.endValues = this.endValue
                    .split(',')
                    .map(v => v.trim())
                    .filter(v => v.length > 0);
            }

            if(this.booleanPickValue){
                this.booleanPickValues = this.booleanPickValue
                    .split(',')
                    .map(v => v.trim())
                    .filter(v => v.length > 0);
            }

            this.processPickList();
        } catch (error) {
            console.error('Error in fetchPicklistOptions:', error);
        }
    }

    processPickList() {
        if (!Array.isArray(this.originalPickList) || this.originalPickList.length === 0) {
            return;
        }

        if (this.booleanPickValue && (!this.booleanPickValues || this.booleanPickValues.length === 0)) {
            this.booleanPickValues = this.booleanPickValue
                .split(',')
                .map(v => v.trim())
                .filter(v => v.length > 0);
        }

        this.pickList = [...this.originalPickList];

        if (this.booleanValue && this.booleanPickValue && this.replaceFromValue && Array.isArray(this.pickList)) {
            const replaceIndex = this.pickList.findIndex(item => item && item.value === this.replaceFromValue);
            if (replaceIndex >= 0) {
                if (Array.isArray(this.booleanPickValues) && this.booleanPickValues.length >= 2) {
                    if (this.pickValue === this.replaceFromValue) {
                        this.pickList.splice(replaceIndex, 1);
                        const boolStr = String(this.recordBooleanValue).toLowerCase();
                        const isTrue = (this.recordBooleanValue === true) || (boolStr === 'true') || (boolStr === '1') || (boolStr === 'y');
                        const selectedBoolValue = isTrue ? this.booleanPickValues[1] : this.booleanPickValues[0];
                        const booleanOption = { label: selectedBoolValue, value: selectedBoolValue };
                        this.pickList.splice(replaceIndex, 0, booleanOption);
                        this.pickValue = selectedBoolValue;
                        this.selectedValue = selectedBoolValue;
                    }
                }
            }
        }
        
        if(this.endValues.length > 0){
            if(this.endValues.includes(this.pickValue)){
                this.endValues = this.endValues.filter(val => val !== this.pickValue);
                this.pickList = this.pickList.filter(item => !this.endValues.includes(item.value));
            }
        }

        if(this.replaceFromValue && this.replaceToValue) {
            if (Array.isArray(this.pickList)) {
                    this.pickList = this.pickList.filter(item => item && item.value !== this.replaceToValue);
                } else {
                    this.pickList = [];
                }
            if(this.pickValue === this.replaceToValue){
                this.pickList = this.pickList.map(item => {
                    if (item.value === this.replaceFromValue) {
                        return { ...item, label: this.replaceToValue, value: this.replaceToValue };
                    }
                    return item;
                });
            }
        }
    }


    get errorValues() {
        if (!this.errorValue) {
            return [];
        }
        return this.errorValue
            .split(',')
            .map(v => v.trim())
            .filter(v => v.length > 0);
    }

    get booleanValues() {
        if (!this.booleanValue) {
            return [];
        }
        return this.booleanValue
            .split(',')
            .map(v => v.trim())
            .filter(v => v.length > 0);
    }

    get picklistValues() {
        let itemsList = [];
        if (!this.selectedValue && this.pickValue) {
                this.selectedValue = this.pickValue;
        }     
        if (Array.isArray(this.pickList)) {
            let selectedUpTo = 0;
            const errors = this.errorValues;
            const isSelectedError = this.selectedValue && errors.includes(this.selectedValue);
            if(!isSelectedError){
                this.pickList.forEach((picklistEntry, index) => {
                let classList = 'slds-path__item slds-is-incomplete';
                if (picklistEntry.value === this.selectedValue) {
                    classList = 'slds-path__item slds-is-current slds-is-active';
                    selectedUpTo = index;
                }
                
                itemsList.push({
                    pItem: picklistEntry,
                    classList: classList
                });
            });

                if (selectedUpTo > 0) {
                    for (let i = 0; i < selectedUpTo; i++) {
                        itemsList[i].classList = 'slds-path__item slds-is-complete';
                    }
                }
        
                if(this.pickValue && errors.includes(this.pickValue)){
                    for (let i = 0; i < selectedUpTo; i++) {
                        itemsList[i].classList = 'slds-path__item slds-is-incomplete';
                    }

                }
            }else {
                this.pickList.forEach((picklistEntry, index) => {
                let classList = 'slds-path__item slds-is-incomplete';
                if (picklistEntry.value === this.selectedValue) {
                    classList = 'slds-path__item slds-is-current slds-is-lost';
                }
                
                itemsList.push({
                    pItem: picklistEntry,
                    classList: classList
                });
            });
            }
            
            return itemsList;
        }
    }
}