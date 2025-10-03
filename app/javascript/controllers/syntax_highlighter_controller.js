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
      /* Dark Prism Theme */
      .token.comment,
      .token.prolog,
      .token.doctype,
      .token.cdata {
        color: #6272a4;
        font-style: italic;
      }

      .token.punctuation {
        color: #f8f8f2;
      }

      .token.property,
      .token.tag,
      .token.constant,
      .token.symbol,
      .token.deleted {
        color: #ff79c6;
      }

      .token.boolean,
      .token.number {
        color: #bd93f9;
      }

      .token.selector,
      .token.attr-name,
      .token.string,
      .token.char,
      .token.builtin,
      .token.inserted {
        color: #50fa7b;
      }

      .token.operator,
      .token.entity,
      .token.url,
      .language-css .token.string,
      .style .token.string,
      .token.variable {
        color: #f8f8f2;
      }

      .token.atrule,
      .token.attr-value,
      .token.function,
      .token.class-name {
        color: #f1fa8c;
      }

      .token.keyword {
        color: #8be9fd;
        font-weight: bold;
      }

      .token.regex,
      .token.important {
        color: #ffb86c;
      }

      .token.important,
      .token.bold {
        font-weight: bold;
      }

      .token.italic {
        font-style: italic;
      }
    `
    document.head.appendChild(style)
  }

  languageValueChanged() {
    this.highlight()
  }
}