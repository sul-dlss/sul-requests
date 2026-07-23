import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['section'];
  static values = { type: { type: String, default: 'none' }, subtype: { type: String, default: 'book' } }

  connect() {
    this.showHideSections();
  }

  updateType(event) {
    this.typeValue = event.target.value;
  }

  typeValueChanged() {
    if (this.typeValue == 'pickup') {
      this.subtypeValue = 'book';
    }

    this.showHideSections();
  }

  updateSubtype(event) {
    this.subtypeValue = event.target.value;
    this.showHideSections();
  }

  showHideSections() {
    Array.from(this.sectionTargets).forEach(section => {
      if ((section.dataset.illRequestForRequestType == undefined || section.dataset.illRequestForRequestType == this.typeValue) && (section.dataset.illRequestForRequestSubtype == undefined || section.dataset.illRequestForRequestSubtype == this.subtypeValue)) {
        const template = section.querySelector('template[data-request-type-template]');

        if (template) {
          const content = template.content.cloneNode(true);
          section.appendChild(content);
          template.remove();
        }

        section.classList.remove('d-none');
      } else if (section.dataset.illRequestForRequestType || section.dataset.illRequestForRequestSubtype) {
        section.classList.add('d-none');

        if (!section.querySelector('template[data-request-type-template]')) {
          const template = document.createElement('template');
          template.dataset.requestTypeTemplate = true;
          template.content.append(...section.childNodes);
          section.appendChild(template);
        }
      }
    });
  }
}
