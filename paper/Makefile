
.SILENT : notes derivation

all: notes test paper

paper:
	raco make paper.scrbl
	scribble --pdf paper.scrbl

deriv.pdf: 
	raco make deriv.scrbl
	scribble --pdf deriv.scrbl

notes:
	echo

clean:
	find . \( -name '*.pdf' -o -name '*.log' -o -name '*.out' -o -name '*.aux' \) -exec rm -f {} \;

test:
	raco make ../models/disunify-a.rkt 
	raco test ../models/disunify-a.rkt
	raco make ../models/test.rkt
	racket ../models/test.rkt
