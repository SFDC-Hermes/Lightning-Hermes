import { LightningElement, wire, track } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getRecords from '@salesforce/apex/COMM_Utility.getRecords';

export default class DatatableSample extends LightningElement {
    @track fetchedRecords = [];
    @track _multiPickListOptions = []; 
    
    objectApiName = 'Account';
    wiredResult;

    get columns() {
        return [
            { label: 'Name', fieldName: 'Name', type: 'text', editable: true },
            {
                label: 'MultiUnit',
                fieldName: 'multiUnit__c',
                type: 'multiPicklistColumn',
                editable: false,
                typeAttributes: {
                    placeholder: 'Choose Type',
                    options: this._multiPickListOptions, 
                    value: { fieldName: 'multiUnit__c' },
                    context: { fieldName: 'Id' },
                    fieldName: 'multiUnit__c'
                }
            }
        ];
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: 'Account.multiUnit__c'
    })
    wireMultiPickList({ error, data }) {
        if (data) {
            this._multiPickListOptions = data.values;
        } else if (error) {
            console.error('Multi-picklist load error:', error);
        }
    }

    @wire(getRecords, {
        objectName: '$objectApiName',
        fieldQuery: 'Id, Name, multiUnit__c',
        whereQuery: '',
        limits: 100
    })
    wiredData(result) {
        if (result.data) {
            this.fetchedRecords = result.data;
        } else if (result.error) {
            this.fetchedRecords = [];
        }
    }
}