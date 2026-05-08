import getRecordName from '@salesforce/apex/COMM_Utility.getRecordName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import {LightningElement, api , track, wire } from 'lwc';

export default class MasterDatatable extends LightningElement {
    @api columns;
    @api objectApiName;
    @api picklistFieldApiName;    
    @api multiPicklistFieldApiName;    

    @track _tableData = [];
    @track saveDraftValues = [];
    @track pickListOptions;
    @track multiPickListOptions;

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

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: '$picklistFieldApiName'
    })
    wirePickList({ error, data }) {
        if (data) {
            this.pickListOptions = data.values;
            if (this._tableData.length > 0) {
                this.processData(this._tableData);
            }
        } else if (error) {
            console.error('Picklist load error:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: '$multiPicklistFieldApiName'
    })
    wireMultiPickList({ error, data }) {
        if (data) {
            this.multiPickListOptions = data.values;
            if (this._tableData.length > 0) {
                this.processData(this._tableData);
            }
        } else if (error) {
            console.error('Multi-picklist load error:', error);
        }
    }

    processData(dataArray) {
        this._tableData = dataArray.map(row => {
            const newRow = { ...row };

            for (const key in row) {
                if (row[key] && typeof row[key] === 'object' && row[key].Name) {
                    const lookupIdField = key.endsWith('__r') ? key.replace('__r', '__c') : key + 'Id';
                    newRow[`${lookupIdField}_Name`] = row[key].Name;
                }
            }

            newRow.pickListOptions = this.pickListOptions;
            newRow.multiPickListOptions = this.multiPickListOptions;
            return newRow;
        });
    }
}