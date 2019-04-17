# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [eff: 1],
  export: [
    locals_without_parens: [eff: 1]
  ]
]
