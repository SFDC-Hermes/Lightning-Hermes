/**
 * @description       : 
 * @author            : SFDC-Hermes
 * @group             : 
 * @last modified on  : 2026-03-13
 * @last modified by  : SFDC-Hermes
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2026-03-13   SFDC-Hermes   Initial Version
 * 1.1   2026-05-04   SFDC-Hermes   Add Lookup field type

 **/
import { LightningElement } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import picklistEditable from './picklistEditable.html';
import picklistNotEditable from './picklistNotEditable.html';
import toggleTemplate from './toggleTemplate.html';
import lookupTemplate from './lookupTemplate.html';
import lookupEditTemplate from './lookupEditTemplate.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
            picklistColumn: {
                template: picklistNotEditable,
                editTemplate: picklistEditable,
                standardCellLayout: true,
                typeAttributes : ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
            },
            toggle: {
                template:  toggleTemplate,
                standardCellLayout: true,
                typeAttributes : ['value', 'context']
            },
            lookup: {
                template: lookupTemplate,      
                editTemplate: lookupEditTemplate,
                standardCellLayout: true,
                typeAttributes: ['value', 'objectApiName', 'name', 'label', 'context', 'fieldName'] 
            }            
        };
}
