import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  reload() {
    this.element.reload();
  }
}
