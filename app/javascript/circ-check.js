import "bootstrap";
import "@hotwired/turbo-rails";
import { application } from "./controllers/application"

import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap";

class CircCheckController extends Controller {
  static targets = ["toast"]

  toastTargetConnected(element) {
    Toast.getOrCreateInstance(element).show();
  }

  removeToast(event) {
    event.target.remove();
  }

  clear() {
    setTimeout(() => {
      document.getElementById('barcode').value = '';
      document.getElementById('barcode').focus();
    }, 1);
  }

  reset() {
    document.getElementById('results').innerHTML = '';
    document.getElementById('barcode').focus();
  }
}

application.register("circ-check", CircCheckController)
