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
import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import MultiPicklistCSS from '@salesforce/resourceUrl/MultiPicklistCSS';

export default class MultiPicklistColumn extends LightningElement {
        @api label;
        @api placeholder;
        @api options;
        @api context;
        @api fieldName;
    
        _value;
        @api
        get value() { return this._value; }
        set value(v) { this._value = v; }
    
        showPicklist = false;
        yaxis;
        isRendered = false;
    
        renderedCallback() {
            if (this.isRendered) return;
            this.isRendered = true;
            loadStyle(this, MultiPicklistCSS).catch(err =>
                console.error('Style load failed', err)
            );
        }
    
        handleSelectOptionList(event) {
            const picklistValues = event.detail ? event.detail.join(';') : '';
            this._value = picklistValues;
                
            this.dispatchEvent(new CustomEvent('picklistchanged', {
                composed: true,
                bubbles: true,
                detail: { 
                    data: { 
                        context: this.context, 
                        value: picklistValues,
                        fieldName: this.fieldName
                    } 
                }
            }));      
        }
    
        handleClick(event) {
            this.yaxis = event.clientY;
            this.showPicklist = true;
        }
    
        closePicklist() {
            this.showPicklist = false;
        }
}