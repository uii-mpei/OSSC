OUT = lab01-api.html lab02-ipc.html

all: $(OUT)

clean:
	rm -f $(OUT)

%.html: %.md
	pandoc \
		--css /study/courses/assets/styles/style.css \
		--include-after-body footer.html \
		--toc --standalone --smart --to html \
		$< >$@
