
all: 
	mkdir build
	ls -1 | grep -v build | xargs -L1 -J % cp -R % build/
	cd build
	scribble --pdf paper.scrbl
	cp paper.pdf ..
	cd ..
	rm -r build/

clean:
	rm -r build/
