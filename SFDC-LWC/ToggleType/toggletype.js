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

import {LightningElement,api,track} from 'lwc';

export default class Toggletype extends LightningElement {
   
@api value;
@api context;
@track togglevalue;



renderedCallback(){
    this.togglevalue=this.value;
}

  handleChange(event) {     
    event.preventDefault();   
    let value = event.target.checked;
    this.value=value;
    this.togglevalue=value;
       
    const toggle = new CustomEvent('toggleselect', {
        composed:true,
        bubbles: true,
        cancelable: true,
        detail: {
            data: { context: this.context, value: this.value }
        }   
    });
    this.dispatchEvent(toggle);  
  }
}
