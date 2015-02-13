
paper: 	paper.pdf

paper.pdf: 
	cd paper; $(MAKE); mv paper.pdf ..

supplement: clean random-terms.tar.gz cleanrt


clean:
	find . -name compiled | xargs -L1 rm -r
	find . \( -name '*~' -o -name '\#*\#' \) | xargs -L1 rm -r

cleanrt: random-terms/
	rm -r random-terms/

random-terms.tar.gz: clean
	mkdir random-terms
	cp -r paper random-terms
	cp -r results random-terms
	cp -r models random-terms
	cp even-model-example.rkt random-terms
	tar -cvzf random-terms.tar.gz random-terms

