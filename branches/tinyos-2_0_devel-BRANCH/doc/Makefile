OVERVIEW = txt/overview.txt
OVERVIEW_HTML = $(subst txt/,,$(subst .txt,.html,$(OVERVIEW)))
STYLESHEET = stylesheets/doc.css

HTML = $(OVERVIEW_HTML)


all: $(OVERVIEW_HTML)

%.html: txt/%.txt $(STYLESHEET)
	rst2html.py --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > html/$@

clean:
	rm -f html/*.html txt/*~ 

