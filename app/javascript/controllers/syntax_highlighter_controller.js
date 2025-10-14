import { Controller } from "@hotwired/stimulus"
import Prism from "prismjs"
import "prismjs/components/prism-clike"
import "prismjs/components/prism-javascript"
import "prismjs/components/prism-python"
import "prismjs/components/prism-ruby"
import "prismjs/components/prism-c"
import "prismjs/components/prism-cpp"
import "prismjs/components/prism-makefile"
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

    // Always use dark theme for code blocks (both public and author views)
    style.textContent = `
      /* Dark theme for all code blocks */
      pre[class*="language-"],
      code[class*="language-"] {
        background: #111827 !important;
        color: #e5e7eb !important;
      }

      code[class*="language-"] {
        background: transparent !important;
      }

      /* DO NOT reset padding - respect Tailwind classes */
      pre[class*="language-"] {
        margin: 0 !important;
      }

      /* Dark Prism Theme Tokens */
      .token.comment,
      .token.prolog,
      .token.doctype,
      .token.cdata {
        color: #9ca3af;
        font-style: italic;
        background: transparent !important;
      }

      .token.punctuation {
        color: #d1d5db;
        background: transparent !important;
      }

      .token.property,
      .token.tag,
      .token.constant,
      .token.symbol,
      .token.deleted {
        color: #ec4899;
        background: transparent !important;
      }

      .token.boolean,
      .token.number {
        color: #a78bfa;
        background: transparent !important;
      }

      .token.selector,
      .token.attr-name,
      .token.string,
      .token.char,
      .token.builtin,
      .token.inserted {
        color: #34d399;
        background: transparent !important;
      }

      .token.operator,
      .token.entity,
      .token.url,
      .language-css .token.string,
      .style .token.string,
      .token.variable {
        color: #e5e7eb;
        background: transparent !important;
      }

      .token.atrule,
      .token.attr-value,
      .token.function,
      .token.class-name {
        color: #fbbf24;
        background: transparent !important;
      }

      .token.keyword {
        color: #60a5fa;
        font-weight: bold;
        background: transparent !important;
      }

      .token.regex,
      .token.important {
        color: #f87171;
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
        position: static !important;
        display: inline !important;
      }

      /* Fix token wrapping */
      pre[class*="language-"] .token {
        white-space: pre !important;
      }
    `
    document.head.appendChild(style)
  }

  languageValueChanged() {
    this.highlight()
  }
}