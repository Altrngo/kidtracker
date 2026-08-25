// app/javascript/controllers/smiley_picker_controller.js
//
// Usage sur chaque cellule du tableau :
//
// <div data-controller="smiley-picker"
//      data-smiley-picker-state-value="green"
//      data-smiley-picker-url-value="<%= child_week_day_entries_path(...) %>"
//      data-smiley-picker-child-item-id-value="<%= child_item.id %>"
//      data-smiley-picker-day-value="<%= day %>">
//   <button data-smiley-picker-target="btn" data-action="click->smiley-picker#toggle">🟢</button>
//   <div data-smiley-picker-target="popup" class="kt-smiley-popup">
//     <button class="kt-smiley-popup__btn" data-pick="green"  data-action="click->smiley-picker#pick">🟢</button>
//     <button class="kt-smiley-popup__btn" data-pick="yellow" data-action="click->smiley-picker#pick">🟡</button>
//     <button class="kt-smiley-popup__btn" data-pick="red"    data-action="click->smiley-picker#pick">🔴</button>
//   </div>
// </div>

import { Controller } from "@hotwired/stimulus"

const EMOJI = { green: "🟢", yellow: "🟡", red: "🔴", "": "—" }

export default class extends Controller {
  static targets = ["btn", "popup"]
  static values  = { state: String, url: String, childItemId: Number, day: Number }

  connect() {
    this.#render()
    // Ferme le popup si clic en dehors
    this._outsideHandler = (e) => {
      if (!this.element.contains(e.target)) this.#close()
    }
    document.addEventListener("click", this._outsideHandler)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideHandler)
  }

  toggle(e) {
    e.stopPropagation()
    const isOpen = this.popupTarget.classList.contains("is-open")
    // Ferme tous les autres popups ouverts
    document.querySelectorAll(".kt-smiley-popup.is-open").forEach(p => p.classList.remove("is-open"))
    if (!isOpen) this.popupTarget.classList.add("is-open")
  }

  async pick(e) {
    e.stopPropagation()
    const state = e.currentTarget.dataset.pick
    this.#close()

    // Optimistic UI : mise à jour immédiate
    this.stateValue = state
    this.#render()

    // Envoi au serveur
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const body  = new URLSearchParams({
      child_item_id: this.childItemIdValue,
      day_of_week:   this.dayValue,
      emoji_state:   state
    })

    try {
      const resp = await fetch(this.urlValue, {
        method:  "PATCH",
        headers: {
          "X-CSRF-Token": token,
          "Accept":       "text/vnd.turbo-stream.html, text/html",
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body
      })
      if (!resp.ok) throw new Error("Erreur serveur")
      // Si Turbo Stream, Turbo le gère automatiquement
    } catch (err) {
      console.error("Smiley update failed:", err)
    }
  }

  // ── Privé ──────────────────────────────────────────────────
  #close() {
    this.popupTarget.classList.remove("is-open")
  }

  #render() {
    this.btnTarget.textContent   = EMOJI[this.stateValue] || "—"
    this.btnTarget.dataset.state = this.stateValue
  }
}
