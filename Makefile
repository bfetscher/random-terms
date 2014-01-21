
.SILENT : notes derivation

all: notes paper.pdf

paper.pdf: deriv.pdf
	scribble --pdf paper.scrbl

deriv.pdf: force
	cd derivation; $(MAKE); cp deriv.pdf ..

notes:
	echo Add check to infer.	
	echo Maybe example derivation should be section 2.

force:
	true
