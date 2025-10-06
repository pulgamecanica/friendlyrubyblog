import { Controller } from "@hotwired/stimulus"
import Prism from "prismjs"
import "prismjs/components/prism-clike"
import "prismjs/components/prism-javascript"
import "prismjs/components/prism-python"
import "prismjs/components/prism-ruby"
import "prismjs/components/prism-c"
import "prismjs/components/prism-cpp"
import "prismjs/components/prism-bash"

export default class extends Controller {
  static targets = ["code"]
  static values = { language: String }

  connect() {
    this.addPrismStyles()
    this.highlight()
  }

  highlight() {
    this.codeTargets.forEach(codeElement => {
      const language = this.getLanguageFromClass(codeElement) || this.languageValue?.toLowerCase()

      // Make sure the code element has the proper language class
      if (language && !codeElement.classList.contains(`language-${language}`)) {
        codeElement.classList.add(`language-${language}`)
      }

      // Use Prism to highlight
      Prism.highlightElement(codeElement)
    })
  }

  getLanguageFromClass(element) {
    const classList = Array.from(element.classList)
    const langClass = classList.find(cls => cls.startsWith('language-'))
    return langClass ? langClass.replace('language-', '') : null
  }

  addPrismStyles() {
    if (document.getElementById('prism-dark-theme')) return

    const style = document.createElement('style')
    style.id = 'prism-dark-theme'
    style.textContent = `
      /* Force light backgrounds for all code blocks */
      pre[class*="language-"],
      code[class*="language-"] {
        background: white !important;
        color: #1f2937 !important;
      }

      code[class*="language-"] {
        background: transparent !important;
      }

      /* Light Prism Theme Tokens */
      .token.comment,
      .token.prolog,
      .token.doctype,
      .token.cdata {
        color: #6b7280;
        font-style: italic;
        background: transparent !important;
      }

      .token.punctuation {
        color: #374151;
        background: transparent !important;
      }

      .token.property,
      .token.tag,
      .token.constant,
      .token.symbol,
      .token.deleted {
        color: #db2777;
        background: transparent !important;
      }

      .token.boolean,
      .token.number {
        color: #7c3aed;
        background: transparent !important;
      }

      .token.selector,
      .token.attr-name,
      .token.string,
      .token.char,
      .token.builtin,
      .token.inserted {
        color: #059669;
        background: transparent !important;
      }

      .token.operator,
      .token.entity,
      .token.url,
      .language-css .token.string,
      .style .token.string,
      .token.variable {
        color: #1f2937;
        background: transparent !important;
      }

      .token.atrule,
      .token.attr-value,
      .token.function,
      .token.class-name {
        color: #d97706;
        background: transparent !important;
      }

      .token.keyword {
        color: #2563eb;
        font-weight: bold;
        background: transparent !important;
      }

      .token.regex,
      .token.important {
        color: #dc2626;
        background: transparent !important;
      }

      .token.important,
      .token.bold {
        font-weight: bold;
        background: transparent !important;
      }

      .token.italic {
        font-style: italic;
        background: transparent !important;
      }

      .token.string-literal {
        background: transparent !important;
      }

      /* Ensure no token has a background */
      .token {
        background: transparent !important;
      }
    `
    document.head.appendChild(style)
  }

  languageValueChanged() {
    this.highlight()
  }
}