FILENAME = main

date = $(shell date +%Y-%m-%d)
output_file = draft_$(date).pdf

figure_src = $(wildcard figures/*.tex figures/*/*.tex)
figure_list = $(figure_src:.tex=.pdf)

LATEX = pdf #pdflatex
# LATEX = xelatex
# LATEX = lualatex

BIBTEX = bibtex
# BIBTEX = biber

default: document copy_draft

all: default

figures: $(figure_list)

# Target assumes figure source is in same directory as expected figure path
figures/%.pdf: figures/%.tex
	latexmk -$(LATEX) -interaction=nonstopmode -halt-on-error $(basename $@)
	mv $(notdir $(basename $@)).pdf $(basename $@).pdf
	rm $(notdir $(basename $@)).*

text:
	latexmk -$(LATEX) -logfilewarnings -halt-on-error -shell-escape $(FILENAME)

document: figures text

copy_draft:
	rsync $(FILENAME).pdf $(output_file)

clean:
	rm -f *.aux *.bbl *.blg *.dvi *.idx *.lof *.log *.lot *.toc \
		*.xdy *.nav *.out *.snm *.vrb *.mp \
		*.synctex.gz *.brf *.fls *.fdb_latexmk \
		*.glg *.gls *.glo *.ist *.alg *.acr *.acn \
		mainNotes.bib

clean_figures:
	rm -f $(figure_list)

clean_drafts:
	rm -f draft_*.pdf

realclean: clean clean_figures
	rm -f *.ps *.pdf

lint:
	grep -E --color=always -r -i --include=\*.tex --include=\*.bib "(\b[a-zA-Z]+) \1\b" || true

final:
	if [ -f *.aux ]; then \
		$(MAKE) clean; \
	fi
	$(MAKE) figures
	$(MAKE) abstract
	$(MAKE) text
	$(MAKE) clean
	$(MAKE) lint

arXiv: realclean document
	mkdir submit_to_arXiv
	cp $(FILENAME).tex submit_to_arXiv
	if [ -f $(FILENAME).bbl ]; then cp $(FILENAME).bbl submit_to_arXiv/ms.bbl; fi
	cp Makefile submit_to_arXiv

	if [ -d src ]; then cp -r src submit_to_arXiv; fi
	if [ -d latex ]; then cp -r latex submit_to_arXiv; fi
	if [ -d figures ]; then cp -r figures submit_to_arXiv; fi
	if [ -f *.sty ]; then cp *.sty submit_to_arXiv; fi

	# Glossary support
	if [ -f $(FILENAME).gls ]; then cp $(FILENAME).gls submit_to_arXiv/ms.gls; fi

	mv submit_to_arXiv/$(FILENAME).tex submit_to_arXiv/ms.tex

	# -i.bak is used for compatability across GNU and BSD/macOS sed
	# Change the FILENAME to ms while ignoring commented lines
	sed -i.bak '/^ *#/d;s/#.*//;0,/FILENAME/s/.*/FILENAME = ms/' submit_to_arXiv/Makefile

	# Remove hyperref for arXiv
	# N.B. Need to manually set the file to edit for the time being
	# sed -i.bak '/{hyperref}/d' submit_to_arXiv/ms.tex
	sed -i.bak '/{hyperref}/d' submit_to_arXiv/latex/packages.tex

	find submit_to_arXiv/ -name "*.bak" -type f -delete

	# arXiv requires .bib files to be compiled to .bbl files and will remove any .bib files
	find submit_to_arXiv/ -name "*.bib" -type f -delete

	tar -zcvf submit_to_arXiv.tar.gz submit_to_arXiv/
	rm -rf submit_to_arXiv
	$(MAKE) realclean

clean_arXiv:
	if [ -f submit_to_arXiv.tar.gz ];then \
		rm submit_to_arXiv.tar.gz; \
	fi

deep_clean: realclean clean_arXiv
	rm -rf submit_to_arXiv