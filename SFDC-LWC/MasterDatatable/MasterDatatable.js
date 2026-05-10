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

    @track sortBy;
    @track sortDirection;

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

    handleCellChange(event) {
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

    handletoggleselect(event) {
        event.stopPropagation();
        const { context, value, fieldName } = event.detail.data;
        const updatedItem = { Id: context, [fieldName]: value };
        this.updateDraftValuesAndData(updatedItem);
    }

    handlePicklistChanged(event) {
        event.stopPropagation();
        const { context, value } = event.detail.data;
        const fieldName = this.multiPicklistFieldApiName;
        if (!fieldName) {
            console.warn('multiPicklistFieldApiName is not configured');
            return;
        }
        const updatedItem = { Id: context, [fieldName]: value };
        this.updateDraftValuesAndData(updatedItem);
        this.updateDataValues(updatedItem);
    }

    async handleLookupSelect(event) {
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
                    this.ShowToast('Success', 'All changes have been saved', 'success');

                    this.saveDraftValues = [];
                    const datatable = this.template.querySelector('c-custom-datatable');
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

    updateDraftValuesAndData(updateItem) {
        const copyDraftValues = [...this.saveDraftValues];
        const itemIndex = copyDraftValues.findIndex(item => item.Id === updateItem.Id);

        if (itemIndex > -1) {
            copyDraftValues[itemIndex] = { ...copyDraftValues[itemIndex], ...updateItem };
        } else {
            copyDraftValues.push(updateItem);
        }
        this.saveDraftValues = copyDraftValues;
    }

    updateDataValues(updateItem) {
        this._tableData = this._tableData.map(item => {
            if (item.Id === updateItem.Id) {
                return { ...item, ...updateItem };
            }
            return item;
        });
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.tableData));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.tableData = parseData;
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