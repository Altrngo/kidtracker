// app/javascript/controllers/smiley_picker_controller.js
import { Controller } from "@hotwired/stimulus"

const EMOJI = { green: "🟢", yellow: "🟡", red: "🔴", "": "—" }

export default class extends Controller {
  static targets = ["btn", "popup"]
  static values  = { state: String, url: String, childItemId: Number, day: Number }

  connect() {
    this.#render()
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
    document.querySelectorAll(".kt-smiley-popup.is-open")
            .forEach(p => p.classList.remove("is-open"))
    if (!isOpen) this.popupTarget.classList.add("is-open")
  }

  async pick(e) {
    e.stopPropagation()
    const state = e.currentTarget.dataset.pick   // green | yellow | red | none
    this.#close()

    // Affichage optimiste : la case réagit immédiatement
    this.stateValue = (state === "none") ? "" : state
    this.#render()

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
          "Accept":       "text/vnd.turbo-stream.html",
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body
      })

      if (!resp.ok) throw new Error(`HTTP ${resp.status}`)

      // Indispensable : sans ceci, la contagion des jaunes et les totaux
      // ne seraient visibles qu'après rechargement de la page.
      const html = await resp.text()
      if (html.trim()) window.Turbo.renderStreamMessage(html)

    } catch (err) {
      console.error("Échec de mise à jour du smiley :", err)
      this.btnTarget.classList.add("is-error")
      setTimeout(() => this.btnTarget.classList.remove("is-error"), 1200)
    }
  }

  #close() {
    this.popupTarget.classList.remove("is-open")
  }

  #render() {
    this.btnTarget.textContent   = EMOJI[this.stateValue] ?? "—"
    this.btnTarget.dataset.state = this.stateValue
  }
}
