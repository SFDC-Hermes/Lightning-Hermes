/**
 * @description       : 
 * @author            : SFDC-Hermes
 * @group             : 
 * @last modified on  : 2026-03-13
 * @last modified by  : SFDC-Hermes
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2026-03-13   SFDC-Hermes   Initial Version
 **/
import { LightningElement } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import picklistEditable from './picklistEditable.html';
import picklistNotEditable from './picklistNotEditable.html';
import toggleTemplate from './toggleTemplate.html';
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
            }
            
        };
       
       
}
