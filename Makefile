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

clean:
	rm -f *.bib.bak *.acn *.acr *.alg *.glg *.glo *.gls *.ist *.lol *.lot *.fdb_latexmk *.aux *.bbl *.aux *.synctex.gz *.log *.out *.blg *.lof *.toc *.len *.nav *.snm *.vrb *.backup *.tex~ *.bib~ *.glsdefs *.run.xml *-blx.bib *.auxlock
	rm -f FrontBackmatter/*.lol FrontBackmatter/*.lot FrontBackmatter/*.fdb_latexmk FrontBackmatter/*.aux FrontBackmatter/*.bbl FrontBackmatter/*.aux FrontBackmatter/*.synctex.gz FrontBackmatter/*.log FrontBackmatter/*.out FrontBackmatter/*.blg FrontBackmatter/*.lof FrontBackmatter/*.toc FrontBackmatter/*.len FrontBackmatter/*.nav FrontBackmatter/*.snm FrontBackmatter/*.vrb FrontBackmatter/*.backup FrontBackmatter/*.tex~ FrontBackmatter/*.bib~
	rm -f Parts/*.lol Parts/*.lot Parts/*.fdb_latexmk Parts/*.aux Parts/*.bbl Parts/*.aux Parts/*.synctex.gz Parts/*.log Parts/*.out Parts/*.blg Parts/*.lof Parts/*.toc Parts/*.len Parts/*.nav Parts/*.snm Parts/*.vrb Parts/*.backup Parts/*.tex~ Parts/*.bib~
	rm -fR gfxcompiled/* tmp/*
