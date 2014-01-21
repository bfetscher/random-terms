
all: deriv.pdf

deriv.pdf: deriv.scrbl
	scribble --latex deriv.scrbl
	pdflatex deriv.tex

clean:
	find . \( -name '*.tex' -o -name '*.pdf' -o -name '*.log' -o -name '*.out' -o -name '*.aux' \) -exec rm -f {} \;	
