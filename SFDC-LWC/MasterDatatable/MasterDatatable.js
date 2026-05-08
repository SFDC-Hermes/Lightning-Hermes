import getRecordName from '@salesforce/apex/COMM_Utility.getRecordName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import {LightningElement, api , track, wire } from 'lwc';

export default class MasterDatatable extends LightningElement {
    @api columns;
    @api objectApiName; 
    @api picklistFieldApiName; 

    @track _tableData = []; 
    @track saveDraftValues = [];
    @track pickListOptions;

    @api
    get tableData() {
        return this._tableData;
    }
    
    set tableData(value) {
        if (value) {
            this.processData(value);
        } else {
            this._tableData = [];
        }
    }
}