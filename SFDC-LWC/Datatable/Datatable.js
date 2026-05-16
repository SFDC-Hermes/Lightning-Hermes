/**
 * @description       : 
 * @author            : SFDC-Hermes
 * @group             : 
 * @last modified on  : 2026-05-15
 * @last modified by  : SFDC-Hermes
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2026-05-15   SFDC-Hermes   Initial Version

 **/
import getRecordName from '@salesforce/apex/COMM_Utility.getRecordName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import {LightningElement, api , track, wire } from 'lwc';

export default class Datatable extends LightningElement {
    @api columns;
    @api objectApiName;

    @track _tableData = [];
    @track saveDraftValues = [];

    @api
    get tableData() {
        return this._tableData;
    }
    set tableData(value) {
        if (value && value.length > 0) {
            this._rawData = JSON.parse(JSON.stringify(value)); 
            this.processData(this._rawData);
        } else {
            this._rawData = [];
            this._tableData = [];
        }
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    processData(dataArray) {
        this._tableData = dataArray.map(row => {
            const newRow = { ...row };
            
            for (const key in row) {
                if (row[key] && typeof row[key] === 'object' && row[key].Name) {
                    const lookupIdField = key.endsWith('__r') ? key.replace('__r', '__c') : key + 'Id';
                    newRow[`${lookupIdField}_Name`] = row[key].Name;
                }
            }

            return newRow;
        });
    }

    refreshTableData() {
    if (!this._rawData || this._rawData.length === 0) {
        return;
    }
    this.processData(this._rawData); 
    }
}