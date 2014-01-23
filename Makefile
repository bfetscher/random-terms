
.SILENT : notes derivation

all: notes paper.pdf

paper.pdf: deriv.pdf
	scribble --pdf paper.scrbl

deriv.pdf: 
	scribble --pdf deriv.scrbl

notes:
	echo Add check to infer.	
	echo Maybe example derivation should be section 2.

clean:
	find . \( -name '*.tex' -o -name '*.pdf' -o -name '*.log' -o -name '*.out' -o -name '*.aux' \) -exec rm -f {} \;
