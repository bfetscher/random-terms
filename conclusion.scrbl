#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          scribble/core
          "citations.rkt")

@title[#:tag "sec:conclusion"]{Conclusion}

As this paper demonstrates, random test-case generation is
an effective tool for finding bugs in formal models. Even
better, this work demonstrates how to build a generic random
generator that is competitive with hand-tuned generators. We
believe that employing more such lightweight techniques for
debugging formal models can help the research community more
effectively communicate research results, both with each
other and with the wider world. Eliminating bugs from our
models makes our results more approachable, as it means that
our papers are less likely to contain frustrating obstacles
that discourage newcomers.

@(element (style "noindent" '()) '())
@bold{Acknowledgments.} Thanks to Casey Klein for help getting this
project started and for an initial prototype implementation.
