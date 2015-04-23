
paper: 	paper.pdf

paper.pdf: 
	cd paper; $(MAKE); mv paper.pdf ..

supplement: clean random-judgments.tar.gz cleanrt


clean:
	find . -name compiled | xargs -L1 rm -r
	find . \( -name '*~' -o -name '\#*\#' \) | xargs -L1 rm -r

cleanrt: random-judgments/
	rm -r random-judgments/

cleanpoly: poly-gen/
	rm -rf poly-gen

random-judgments.tar.gz: clean
	mkdir random-judgments
	cp -r paper random-judgments
	cp -r results random-judgments
	cp -r models random-judgments
	cp even-model-example.rkt random-judgments
	cp README random-judgments
	git clone https://github.com/bfetscher/poly-gen.git
	mkdir random-judgments/poly-gen
	cp poly-gen/*.rkt random-judgments/poly-gen
	cp poly-gen/*.hs random-judgments/poly-gen
	cp poly-gen/README random-judgments/poly-gen
	echo 'poly-gen/ contains the models used in the second evaluation' \
		>> random-judgments/README
	rm -rf poly-gen
	tar -cvzf random-judgments.tar.gz random-judgments

