all: source build static

source: .FORCE
	./generate.py source

build:	.FORCE
	./generate.py build

static:
	cp source/c?.html build/
	cp source/mjpegcanvas?.js build/

.FORCE:
