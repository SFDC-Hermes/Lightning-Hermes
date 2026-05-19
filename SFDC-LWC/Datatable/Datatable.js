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

    updateDraftValuesAndData(updateItem) {
        const copyDraftValues = [...this.saveDraftValues];
        const itemIndex = copyDraftValues.findIndex(item => item.Id === updateItem.Id);

        if (itemIndex > -1) {
            copyDraftValues[itemIndex] = { ...copyDraftValues[itemIndex], ...updateItem };
        } else {
            copyDraftValues.push(updateItem);
        }
        this.saveDraftValues = copyDraftValues;

        this._tableData = this._tableData.map(item => {
            if (item.Id === updateItem.Id) {
                return { ...item, ...updateItem };
            }
            return item;
        });
    }

    updateDataValues(updateItem) {
        this._tableData = this._tableData.map(item => {
            if (item.Id === updateItem.Id) {
                return { ...item, ...updateItem };
            }
            return item;
        });
    }

    handleCellChange(event) {
        console.log('Normal field type cell change');
        const draftValues = event.detail.draftValues || [];
        draftValues.forEach(ele => {
            const cleanUpdateItem = {};
            Object.keys(ele).forEach(key => {
                if (ele[key] !== undefined) {
                    cleanUpdateItem[key] = ele[key];
                }
            });
            if (Object.keys(cleanUpdateItem).length > 1) {
                this.updateDraftValuesAndData(cleanUpdateItem);
            }
        });
    }

    handleToggleChange(event) {
        console.log('Boolean/Toggle field type cell change');
        event.stopPropagation();
        const { context, value, fieldName } = event.detail.data;
        const normalizedValue = (value === 'true' || value === true);

        const updatedItem = { Id: context, [fieldName]: normalizedValue };
        console.log('1',updatedItem);
        this.updateDraftValuesAndData(updatedItem);
    }

    handlePicklistChange(event) {
        console.log('PickList/Multi-Picklist field type cell change');
        event.stopPropagation();
        const { context, value, fieldName } = event.detail.data;
        
        if (!fieldName) {
            console.error('fieldName is missing in picklist event');
            return;
        }

        const updatedItem = { Id: context, [fieldName]: value };
        this.updateDraftValuesAndData(updatedItem);
    }

    async handleLookupChange(event) {
        console.log('LookUp field type cell change');
        event.stopPropagation();
        const { context, value, fieldName } = event.detail.data;

        let realRecordName = '';
        if (value) {
            try {
                realRecordName = await getRecordName({ recordId: value });
            } catch (error) {
                console.error('Record name fetch failed:', error);
                realRecordName = 'Unknown';
            }
        }

        const draftItem = { Id: context, [fieldName]: value };
        this.updateDraftValuesAndData(draftItem);

        const displayFieldName = fieldName + '_Name';
        this.updateDataValues({ Id: context, [fieldName]: value, [displayFieldName]: realRecordName });
    }

    handleSave(event) {
        try {
            if (!this.objectInfo || !this.objectInfo.data) {
                this.ShowToast('Error', 'Metadata is loading. Please try again later.', 'error');
                return;
            }

            const validFields = this.objectInfo.data.fields;
            const dataTableStandardDrafts = event.detail.draftValues || [];
            const allDrafts = JSON.parse(JSON.stringify(this.saveDraftValues));

            dataTableStandardDrafts.forEach(standardDraft => {
                const cleanDraft = {};
                Object.keys(standardDraft).forEach(key => {
                    if (standardDraft[key] !== undefined) {
                        cleanDraft[key] = standardDraft[key];
                    }
                });

                const existing = allDrafts.find(d => d.Id === cleanDraft.Id);
                if (existing) {
                    Object.assign(existing, cleanDraft);
                } else if (Object.keys(cleanDraft).length > 1) {
                    allDrafts.push(cleanDraft);
                }
            });

            if (allDrafts.length === 0) return;

            const recordInputs = allDrafts.map(draft => {
                const fields = {};
                Object.keys(draft).forEach(key => {
                    if (key === 'Id' || (validFields && validFields[key])) {
                        fields[key] = draft[key];
                    }
                });
                return { fields };
            });

            const promises = recordInputs.map(recordInput => updateRecord(recordInput));

            Promise.all(promises)
                .then(() => {
                    this.ShowToast('Success', 'All changes have been saved!', 'success');

                    this.saveDraftValues = [];
                    const datatable = this.template.querySelector('c-wj-custom-datatable');
                    if (datatable) {
                        datatable.draftValues = [];
                    }
                    this.dispatchEvent(new CustomEvent('refreshdata'));
                })
                .catch(error => {
                    console.error('Save failed:', error);
                    this.ShowToast('Error', 'An error occurred while saving.', 'error');
                });

        } catch (jsError) {
            console.error('handleSave error:', jsError);
        }
    }

    handleCancel() {
        this.saveDraftValues = [];
        const datatable = this.template.querySelector('c-custom-datatable');
        if (datatable) {
            datatable.draftValues = [];
        }
        this.dispatchEvent(new CustomEvent('canceldata'));
    }

    ShowToast(title, message, variant, mode = 'dismissable') {
        const evt = new ShowToastEvent({ title, message, variant, mode });
        this.dispatchEvent(evt);
    }
}