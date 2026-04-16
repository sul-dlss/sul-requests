import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addTemplate", "removeTemplate", "items", "appointmentRequests", "draftRequests"]

  addToForm(e){
    e.preventDefault();
    this.moveElements(this.appointmentRequestsTarget, this.draftRequestsTarget, this.removeTemplateTarget, e)
    
  }

  removeFromForm(e){
    e.preventDefault();
    this.moveElements(this.draftRequestsTarget, this.appointmentRequestsTarget, this.addTemplateTarget, e)
  }

  moveElements(moveTo, moveFrom, template, e) {
    const call_number = e.currentTarget.parentElement.querySelector(`.item-call-number`).innerHTML;
    const data = e.currentTarget.dataset;
    const element = document.importNode(template.content, true);
    let parentExists = moveTo.querySelector(`[data-title="${data.title}"]`)

    let rootNode = element.querySelector('[data-request-parent]');

    if(parentExists) {
      rootNode = element.querySelector('[data-list-request-id]');
      rootNode.dataset.listRequestId = data.id;
      rootNode.id = rootNode.id.replace('__TRANSACTION_NUMBER__', data.id)
    }
    rootNode.dataset.requestParent = data.title;
    rootNode.innerHTML = rootNode.innerHTML.replaceAll('__TITLE__', data.title);
    rootNode.innerHTML = rootNode.innerHTML.replaceAll('__TRANSACTION_NUMBER__', data.id);
    rootNode.innerHTML = rootNode.innerHTML.replaceAll('__transaction_number__', data.id);
    rootNode.innerHTML = rootNode.innerHTML.replaceAll('__CALL_NUMBER__', call_number);
    rootNode.innerHTML = rootNode.innerHTML.replaceAll('__BASE_CALLNUMBER__', data.baseCallnumber);

    let appendTarget = moveTo;
    if (parentExists) {
      appendTarget = appendTarget.querySelector(`[data-request-parent="${data.title}"] ul`)
    }
    
    appendTarget.appendChild(rootNode);
    const li_node = moveFrom.querySelector(`#aeon_request_${data.id}`);
    li_node.remove()
    if (moveFrom.querySelectorAll(`[data-request-parent="${data.title}"] ul li`).length == 0){
      moveFrom.querySelector(`[data-request-parent="${data.title}"]`).remove();
    }
  } 
}