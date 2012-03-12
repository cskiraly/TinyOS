OVERVIEW = txt/overview.txt
OVERVIEW_HTML = $(subst txt/,,$(subst .txt,.html,$(OVERVIEW)))
STYLESHEET = stylesheets/doc.css
HTML = $(OVERVIEW_HTML)
TEPS = $(wildcard txt/*.txt)
TEPS_HTML = $(subst txt/,,$(subst .txt,.html,$(TEPS)))
TEPS_PDF = $(subst txt/,,$(subst .txt,.pdf,$(TEPS)))
TEPS_TEX = $(subst txt/,,$(subst .txt,.tex,$(TEPS)))
TEP_STYLESHEET = stylesheets/tep.css

#override for different docutils installations
ifndef RST2HTML
RST2HTML= rst2html
endif
ifndef RST2LATEX
RST2LATEX= rst2latex
endif
ifndef RST2PDF
RST2PDF= rst2pdf
endif
ifndef PDFLATEX
PDFLATEX= pdflatex
endif

all: overview teps

pdf: $(TEPS_PDF)
	rm -f pdf/*.out pdf/*.log pdf/*.aux

$(OVERVIEW_HTML): $(OVERVIEW) $(STYLESHEET)
	$(RST2HTML) --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > html/$@

%.html: txt/%.txt $(TEP_STYLESHEET)
	$(RST2HTML) --stylesheet-path=$(TEP_STYLESHEET) --embed-stylesheet $< > html/$@

%.pdf: pdf/%.tex 
	$(PDFLATEX) -output-directory pdf $< > /dev/null


%.tex: txt/%.txt 
	$(RST2LATEX) $< > pdf/$@
	pdflatex -interaction=batchmode -output-directory pdf $@

overview: $(OVERVIEW_HTML)

teps: $(TEPS_HTML) $(TEPS_PDF)

clean:
	rm -f html/*.html txt/*~ pdf/*.log pdf/*.out pdf/*.tex pdf/*.aux

cleanpdf:
	rm -f pdf/*.log pdf/*.out pdf/*.tex pdf/*.aux

