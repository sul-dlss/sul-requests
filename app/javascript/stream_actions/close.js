import { Modal } from "bootstrap"

export default function() {
  const modalId = this.getAttribute("target")
  
  const modal = document.getElementById(modalId)?.closest('.modal');

  if (!modal) return;

  const bsModal = Modal.getInstance(modal);

  if (bsModal) {
    bsModal.hide();
  }
}
