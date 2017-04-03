all:
	pdflatex document
	bibtex document
	makeglossaries document
	pdflatex document
	pdflatex document

write18:
	pdflatex --enable-write18 document
	bibtex document
	makeglossaries document
	pdflatex --enable-write18 document
	pdflatex --enable-write18 document

open:
	evince document.pdf &

clean:
	rm -f *.bib.bak *.acn *.acr *.alg *.glg *.glo *.gls *.ist *.lol *.lot *.fdb_latexmk *.aux *.bbl *.aux *.synctex.gz *.log *.out *.blg *.lof *.toc *.len *.nav *.snm *.vrb *.backup *.tex~ *.bib~ *.glsdefs *.run.xml *-blx.bib *.auxlock
	rm -f frontback/*.lol frontback/*.lot frontback/*.fdb_latexmk frontback/*.aux frontback/*.bbl frontback/*.aux frontback/*.synctex.gz frontback/*.log frontback/*.out frontback/*.blg frontback/*.lof frontback/*.toc frontback/*.len frontback/*.nav frontback/*.snm frontback/*.vrb frontback/*.backup frontback/*.tex~ frontback/*.bib~
	rm -f chapters/*.lol chapters/*.lot chapters/*.fdb_latexmk chapters/*.aux chapters/*.bbl chapters/*.aux chapters/*.synctex.gz chapters/*.log chapters/*.out chapters/*.blg chapters/*.lof chapters/*.toc chapters/*.len chapters/*.nav chapters/*.snm chapters/*.vrb chapters/*.backup chapters/*.tex~ chapters/*.bib~
	rm -fR gfxcompiled/* tmp/*
