el-ixir: *.pas
	fpc -XX el-ixir.pas

clean:
	rm -f *.gpi *.o *.ppu el-ixir

install: el-ixir
	mkdir -p "$$DESTDIR/usr/games"
	install -c el-ixir "$$DESTDIR/usr/games/"

dist:
	rm -rf tmp
	mkdir tmp
	VER=`git describe --tags` && \
	mkdir "tmp/el-ixir-$$VER" && \
	cp -p *.pas Makefile "tmp/el-ixir-$$VER/" && \
	cd tmp && \
	tar cfz "../el-ixir-$$VER.tar.gz" *
	rm -rf tmp
