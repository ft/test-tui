MAN = Test-TUI.3 Test-TUI-Inspect.3 Test-TUI-VT102.3
PDF = Test-TUI.pdf Test-TUI-Inspect.pdf Test-TUI-VT102.pdf
HTML = Test-TUI.html Test-TUI-Inspect.html Test-TUI-VT102.html

COMMONOPTIONS = --self-contained --number-sections --normalize --smart --toc

TEX_META = -V date='\today' --highlight-style=monochrome
HTML_META = -c manual.css

MAIN_TEX_META = -V author="Frank Terbeck"
MAIN_TEX_META += -V title="Test::TUI(3) Reference Manual"
MAIN_HTML_META = $(MAIN_TEX_META) --highlight-style=monochrome
MAIN_MAN_META = -V title="Test::TUI" -V section="3" -V date="Oct, 2012"

INSPECT_TEX_META = -V author="Frank Terbeck"
INSPECT_TEX_META += -V title="Test::TUI::Inspect(3) Manual"
INSPECT_HTML_META = $(INSPECT_TEX_META) --highlight-style=monochrome
INSPECT_MAN_META = -V title="Test::TUI::Inspect" -V section="3"
INSPECT_MAN_META += -V date="Oct, 2012"

VT102_TEX_META = -V author="Frank Terbeck"
VT102_TEX_META += -V title="Test::TUI::VT102(3) Manual"
VT102_HTML_META = $(VT102_TEX_META) --highlight-style=monochrome
VT102_MAN_META = -V title="Test::TUI::VT102" -V section="3"
VT102_MAN_META += -V date="Oct, 2012"

all: man html pdf
man: $(MAN)
pdf: $(PDF)
html: $(HTML)

Test-TUI.3: Test-TUI.mdwn
	pandoc -t man $(COMMONOPTIONS) $(MAIN_MAN_META) -o $@ Test-TUI.mdwn
Test-TUI.pdf: Test-TUI.mdwn
	pandoc --template template.latex $(COMMONOPTIONS) $(TEX_META) $(MAIN_TEX_META) -o $@ Test-TUI.mdwn
Test-TUI.html: Test-TUI.mdwn
	pandoc -t html5 $(HTML_META) $(COMMONOPTIONS) $(MAIN_HTML_META) -o $@ Test-TUI.mdwn

Test-TUI-Inspect.3: Test-TUI-Inspect.mdwn
	pandoc -t man $(COMMONOPTIONS) $(INSPECT_MAN_META) -o $@ Test-TUI-Inspect.mdwn
Test-TUI-Inspect.pdf: Test-TUI-Inspect.mdwn
	pandoc --template template.latex $(COMMONOPTIONS) $(TEX_META) $(INSPECT_TEX_META) -o $@ Test-TUI-Inspect.mdwn
Test-TUI-Inspect.html: Test-TUI-Inspect.mdwn
	pandoc -t html5 $(HTML_META) $(COMMONOPTIONS) $(INSPECT_HTML_META) -o $@ Test-TUI-Inspect.mdwn

Test-TUI-VT102.3: Test-TUI-VT102.mdwn
	pandoc -t man $(COMMONOPTIONS) $(VT102_MAN_META) -o $@ Test-TUI-VT102.mdwn
Test-TUI-VT102.pdf: Test-TUI-VT102.mdwn
	pandoc --template template.latex $(COMMONOPTIONS) $(TEX_META) $(VT102_TEX_META) -o $@ Test-TUI-VT102.mdwn
Test-TUI-VT102.html: Test-TUI-VT102.mdwn
	pandoc -t html5 $(HTML_META) $(COMMONOPTIONS) $(VT102_HTML_META) -o $@ Test-TUI-VT102.mdwn

clean:
	rm -f $(HTML) $(PDF) $(MAN) *~

.PHONY: all man html pdf clean
