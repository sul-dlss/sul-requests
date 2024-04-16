import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['earliestAvailable']

  connect() {
    const form = document.getElementById('new_patron_request');
    const accordionbuttons = form.querySelectorAll('.accordion-button');

    if (accordionbuttons.length == 1){
      form.classList.remove('accordion');
      const accordion = document.querySelector(`${accordionbuttons[0].dataset.bsTarget}-accordion`);
      accordion.classList.remove('d-none');
      accordion.classList.remove('shadow-sm');
      accordion.querySelector('.accordion-header').remove();
      const formitem = document.querySelector(`${accordionbuttons[0].dataset.bsTarget}`);
      formitem.classList.remove('collapse')
    } else {
      accordionbuttons.forEach((accordionbutton, index) => {
        accordionbutton.getElementsByClassName('step-number')[0].innerHTML = index + 1;
        if (index == 0) {
          accordionbutton.removeAttribute('disabled');
          accordionbutton.click();
        }
      });
    }
  }

  nextStep(event) {
    const step = 'patron_request[' + event.target.id + ']';
    const formdata = new FormData(event.target.closest("form"));
    const nextstepid = formdata.get(step.replace('-', '_'));
    if (!nextstepid) { return }

    const accordionbutton = document.querySelector(`[data-bs-target='#${event.target.id}']`);
    accordionbutton.parentElement.classList.add('completed');
    accordionbutton.click();
    accordionbutton.setAttribute('disabled', '');
    const accordions = Array.from(document.querySelectorAll('.accordion-item:not([id*="placeholder"])'));
    const current = accordions.findIndex( x => x.id.indexOf(event.target.id) > -1  );
    var nextitem = accordions.at(current+1).id.split('-accordion')[0];
    nextitem = (nextitem == 'pickup' || nextitem == 'scan') && formdata.get('patron_request[request_type]') ? formdata.get('patron_request[request_type]') : nextitem;
    var nextstep = document.querySelector(`[data-bs-target='#${nextitem}']`);

    this.barcodes(event.target.id, nextitem)
    this.clickNext(nextstep, accordionbutton);
    event.preventDefault();
  }

  barcodes(previous, next) {
    if (previous == 'barcodes' && next == 'pickup') {
      this.addItems('availableItems');
      this.addItems('unavailableItems')
    }
  }

  addItems(id) {
    const available = id.indexOf('unavailable') > -1 ? 'false' : 'true';
    const items = document.querySelectorAll(`[data-itemselector-available-param="${available}"]:checked`);
    if (items) {
      document.getElementById(id).innerHTML = this.renderItems(items);
    }
  }

  editForm(event) {
    event.target.parentElement.classList.remove('completed');
    document.querySelectorAll('.accordion-item').forEach(accordion => {
      accordion.querySelector('.accordion-button').setAttribute('disabled', '');
    })
    document.querySelector('.show').classList.remove('show');
    this.clickNext(event.target.parentElement.querySelector('.accordion-button'));
    event.preventDefault();
  }

  clickNext(element, accordionbutton=false) {
    element.removeAttribute('disabled');
    const accordionid = element.dataset.bsTarget.replace('#', '') + '-accordion'
    document.querySelector(`#${accordionid}`).classList.remove('d-none')
    element.click();
    if (accordionbutton) {
      var previoustepnumber = parseInt(accordionbutton.querySelector('.step-number').innerHTML);
      element.querySelector('.step-number').innerHTML = previoustepnumber + 1;
      const placeholder = document.querySelector(`#placeholder${previoustepnumber + 1}-accordion`);
      if (placeholder){ placeholder.classList.add('d-none'); }
    } else {
      const accordions = Array.from(document.querySelectorAll('.accordion-item'));
      const currentelement = accordions.findIndex( x => x.id === accordionid  );
      accordions.slice(currentelement+1).forEach(accordion => {
        if (accordion.id.indexOf('placeholder') > -1) {
          accordion.classList.remove('d-none');
        } else {
          accordion.classList.add('d-none');
        }
      })
    }
  }

  async updateEarliestAvailable(event) {
    const url = new URL(this.earliestAvailableTarget.src + "/../" + event.currentTarget.value);

    this.earliestAvailableTarget.src = url;
  }

  renderItems(items) {
    return Array.from(items).map((item) => {
      return `
        <li class="hstack gap-2 border bg-light rounded-pill px-3">
          <span class="py-2">
            ${item.dataset.itemselectorLabelParam}
          </span>
          <span class="vr"></span>
          <button data-action="#unchecked" data-itemselector-id-param="${item.dataset.itemselectorIdParam}" type="button" class="btn-close py-2" aria-label="Remove"></button>
        </li>
      `;
    }).join('');
  }
}
