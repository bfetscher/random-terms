
.SILENT : notes derivation

all: notes paper.pdf

paper.pdf:
	scribble --pdf paper.scrbl

deriv.pdf: 
	scribble --pdf deriv.scrbl

notes:
	echo

clean:
	find . \( -name '*.tex' -o -name '*.pdf' -o -name '*.log' -o -name '*.out' -o -name '*.aux' \) -exec rm -f {} \;
