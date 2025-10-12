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
    if (document.getElementById('prism-theme')) return

    const style = document.createElement('style')
    style.id = 'prism-theme'

    // Check if we're in public view (has id="public" on body)
    const isPublicView = document.body.id === 'public'

    style.textContent = `
      /* Context-aware code block styling */
      ${isPublicView ? `
      /* Light theme for public view */
      pre[class*="language-"],
      code[class*="language-"] {
        background: white !important;
        color: #1f2937 !important;
      }

      code[class*="language-"] {
        background: transparent !important;
      }

      /* Light Prism Theme Tokens */` : `
      /* Dark theme for author view */
      pre[class*="language-"],
      code[class*="language-"] {
        background: #111827 !important;
        color: #e5e7eb !important;
      }

      code[class*="language-"] {
        background: transparent !important;
      }

      /* Dark Prism Theme Tokens */`}
      .token.comment,
      .token.prolog,
      .token.doctype,
      .token.cdata {
        color: ${isPublicView ? '#6b7280' : '#9ca3af'};
        font-style: italic;
        background: transparent !important;
      }

      .token.punctuation {
        color: ${isPublicView ? '#374151' : '#d1d5db'};
        background: transparent !important;
      }

      .token.property,
      .token.tag,
      .token.constant,
      .token.symbol,
      .token.deleted {
        color: ${isPublicView ? '#db2777' : '#ec4899'};
        background: transparent !important;
      }

      .token.boolean,
      .token.number {
        color: ${isPublicView ? '#7c3aed' : '#a78bfa'};
        background: transparent !important;
      }

      .token.selector,
      .token.attr-name,
      .token.string,
      .token.char,
      .token.builtin,
      .token.inserted {
        color: ${isPublicView ? '#059669' : '#34d399'};
        background: transparent !important;
      }

      .token.operator,
      .token.entity,
      .token.url,
      .language-css .token.string,
      .style .token.string,
      .token.variable {
        color: ${isPublicView ? '#1f2937' : '#e5e7eb'};
        background: transparent !important;
      }

      .token.atrule,
      .token.attr-value,
      .token.function,
      .token.class-name {
        color: ${isPublicView ? '#d97706' : '#fbbf24'};
        background: transparent !important;
      }

      .token.keyword {
        color: ${isPublicView ? '#2563eb' : '#60a5fa'};
        font-weight: bold;
        background: transparent !important;
      }

      .token.regex,
      .token.important {
        color: ${isPublicView ? '#dc2626' : '#f87171'};
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