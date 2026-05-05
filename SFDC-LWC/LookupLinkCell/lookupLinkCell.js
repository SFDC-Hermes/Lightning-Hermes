import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class LookupLinkCell extends NavigationMixin(LightningElement) {
    @api recordId;
    @api name;

    handleNavigate(event) {
        event.preventDefault();        
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        }
    }
}