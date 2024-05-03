import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];
  static values = { field: String, asc: Boolean };

  connect() { }


  // Send event in required GA4 format to Google
  send({ params: { action, category, label, value } }) {
    window.gtag && window.gtag('event', action, {
      event_category: category,
      event_label: label,
      event_value: value
    });  
  }
}
