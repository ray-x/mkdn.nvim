;; extends
(pipe_table_header
  "|" @punctuation.special (#set! conceal "│" ))

(pipe_table_row
  "|" @punctuation.special (#set! conceal "│"))

(pipe_table_delimiter_row
  "|" @punctuation.special (#set! conceal "│"))

(pipe_table_delimiter_cell
  "-" @punctuation.special (#set! conceal "─"))

(("-" @punctuation.special) (#set! conceal "─"))
