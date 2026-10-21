import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    term: String,
    html: String,
    articleId: String
  }

  connect() {
    const rawHtml = this.decodeHTML(this.htmlValue || "")
    const term = (this.termValue || "").trim()
    const articleId = (this.articleIdValue || "").trim()

    requestAnimationFrame(() => {
      const container = document.createElement("div")

      container.innerHTML = this.processContent(rawHtml, term, articleId)

      const busyElement = this.element.querySelector(".busy")
      if (busyElement) {
        busyElement.replaceWith(...container.childNodes)
      } else {
        this.element.appendChild(container)
      }

      this.element.classList.remove("busy-container")
    })
  }

  decodeHTML(html) {
    const txt = document.createElement("textarea")
    txt.innerHTML = html
    return txt.value
  }

  processContent(htmlContent, searchString, articleId) {
    if (!htmlContent) return ""

    const wrapper = document.createElement("div")
    wrapper.innerHTML = htmlContent

    if (searchString) {
      const rawTerms = searchString.split(/\s+/).filter(Boolean)
      if (rawTerms.length > 0) {
        const escapedTerms = rawTerms.map(t => t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
        const pattern = `\\b(${escapedTerms.join("|")})\\b`

        const walker = document.createTreeWalker(
          wrapper,
          NodeFilter.SHOW_TEXT,
          {
            acceptNode: (node) => {
              const parentName = node.parentElement?.tagName.toLowerCase()
              if (parentName === "script" || parentName === "style") {
                return NodeFilter.FILTER_REJECT
              }
              return new RegExp(pattern, "i").test(node.nodeValue)
                ? NodeFilter.FILTER_ACCEPT
                : NodeFilter.FILTER_SKIP
            }
          }
        )

        const nodesToReplace = []
        while (walker.nextNode()) {
          nodesToReplace.push(walker.currentNode)
        }

        nodesToReplace.forEach(node => {
          const replaceRegex = new RegExp(pattern, "gi")
          const span = document.createElement("span")
          span.innerHTML = node.nodeValue.replace(replaceRegex, (match) => {
            return `<span class="highlighted">${match}</span>`
          })
          node.replaceWith(...span.childNodes)
        })
      }
    }

    if (articleId) {
      const links = wrapper.querySelectorAll(`a[aria-describedby*="tooltip-${articleId}"]`)
      links.forEach(link => {
        link.classList.add("highlighted")
      })
    }

    return wrapper.innerHTML
  }
}
