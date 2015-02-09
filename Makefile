
paper: 	paper.pdf
	cd paper; $(MAKE); mv paper.pdf ..

paper.pdf: 

supplement:
	mkdir random-terms
	cp -r paper random-terms
	cp -r results random-terms
	cp -r models random-terms
