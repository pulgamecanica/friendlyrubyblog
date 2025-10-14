# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "sortablejs" # @1.15.6
pin "@rails/actioncable", to: "actioncable.esm.js"

# Prism.js for syntax highlighting
pin "prismjs", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-core.js"
pin "prismjs/components/prism-clike", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-clike.js"
pin "prismjs/components/prism-javascript", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-javascript.js"
pin "prismjs/components/prism-typescript", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-typescript.js"
pin "prismjs/components/prism-python", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-python.js"
pin "prismjs/components/prism-ruby", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-ruby.js"
pin "prismjs/components/prism-c", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-c.js"
pin "prismjs/components/prism-cpp", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-cpp.js"
pin "prismjs/components/prism-bash", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-bash.js"
pin "prismjs/components/prism-makefile", to: "https://ga.jspm.io/npm:prismjs@1.30.0/components/prism-makefile.js"

# Chart.js
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.2.0/dist/chart.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
