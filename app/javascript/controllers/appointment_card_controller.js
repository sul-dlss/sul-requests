import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['request'];

  connect() { }

  requestTargetDisconnected() {
    this.dispatch('request-removed', { });
  }
}
