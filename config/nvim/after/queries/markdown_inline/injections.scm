; Override default injections to remove latex_block which was removed
; from the markdown_inline grammar in newer tree-sitter-markdown versions.
((html_tag) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined))
