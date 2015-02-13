
paper: 	paper.pdf

paper.pdf: 
	cd paper; $(MAKE); mv paper.pdf ..

supplement: clean random-judgments.tar.gz cleanrt


clean:
	find . -name compiled | xargs -L1 rm -r
	find . \( -name '*~' -o -name '\#*\#' \) | xargs -L1 rm -r

cleanrt: random-judgments/
	rm -r random-judgments/

random-judgments.tar.gz: clean
	mkdir random-judgments
	cp -r paper random-judgments
	cp -r results random-judgments
	cp -r models random-judgments
	cp even-model-example.rkt random-judgments
	cp README random-judgments
	tar -cvzf random-judgments.tar.gz random-judgments

