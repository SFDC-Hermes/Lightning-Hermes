import { LightningElement, api } from 'lwc';

export default class LookupType extends LightningElement {
    @api value;         
    @api objectApiName;
    @api fieldName;
    @api label;
    @api name;
    @api context;

    @api
    focus() {
        const picker = this.template.querySelector('lightning-record-picker');
        if (picker) {
            picker.focus();
        }
    }

    @api
    get validity() {
        return { valid: true };
    }

    @api
    checkValidity() {
        return true;
    }

    @api
    reportValidity() {
        return true;
    }

    @api
    showHelpMessageIfInvalid() {
    }

    handleChange(event) {
        const selectedId = event.detail.recordId;

        if (selectedId === undefined) {
            return; 
        }

        if (selectedId === this.value) {
            return;
        }

        const lookupEvent = new CustomEvent('lookupselect', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { 
                    value: selectedId,
                    name: this.name,
                    fieldName: this.fieldName,
                    context: this.context 
                }
            }
        });

        this.dispatchEvent(lookupEvent);
        const picker = this.template.querySelector('lightning-record-picker');
        if (picker) {
            picker.blur();
        }
    }
}