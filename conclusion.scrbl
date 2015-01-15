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
project started and for an initial prototype implementation, to 
Asumu Takikawa for his help with the delimited continuations model,
and to Larry Henschen for his help with earlier versions of this work.
Thanks to Spencer Florence for helpful discussions and comments
on the writing.
Thanks to Hai Zhou, Li Li, Yuankai Chen, and Peng Kang for 
graciously sharing their compute servers with us.
Thanks to the Ministry of Science and Technology of the R.O.C.
for their support (under Contract MOST 103-2811-E-002-015)
when Findler visited the CSIE department at National Taiwan University.
Thanks also to the NSF for their support of this work.

@(linebreak)
This paper is available online at:
@centered[@url["http://users.eecs.northwestern.edu/~baf111/random-judgments/"]]
along with Redex models for all of the definitions in the paper and
the raw data used to generate all of the plots.
           
