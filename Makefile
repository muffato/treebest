CC=			gcc
CXX=		g++
CFLAGS=		-g -Wall -O2 #-pg
CXXFLAGS=	$(CFLAGS)
YFLAGS= 
DFLAGS=		-DUSE_GCC -DHAVE_PHYML -DLH3_ADDON # for phyml
VERSION=	1.9.0
NJVERSION=	-DTR_VERSION="\"$(VERSION)\"" -DTR_BUILD=\"`date +%d%b%Y`\"
LEX=		flex
YACC=		bison --yacc
FLUID=		fluid
FLTKCFG=	fltk-config
PROG=		njtree
LIBOBJS=	lex.yy.o y.tab.o read.o nj.o utils1.o subtree.o sdi.o bs_nj.o \
			reroot.o task.o output.o ortho.o cut_tree.o spec.o utils2.o \
			align.o filter.o aln_mask.o prob_dist.o brent.o ng86_ds.o lost.o \
			tree_plot.o cpp_utils.o read_aln.o pre_cons.o simulate.o compare.o \
			order.o nhx_output.o nj2.o backtrans.o phyml.o mmerge.o est_len.o best.o
FLOBJS=		flnjtree.o flnjtree_ui.o flglobal.o flworkspace.o flcallback.o
INCLUDES=	-I.
LIBS=		-L. -lphylotree -Lalign_lib -lalign -lm -Lphyml -lphyml
SUBDIRS=	. align_lib phyml

.SUFFIXES:.c .o .cc

.c.o:
		$(CC) -c $(DFLAGS) $(CFLAGS) $(INCLUDES) $< -o $@

.cc.o:
		$(CXX) -c $(DFLAGS) $(CXXFLAGS) $(INCLUDES) $< -o $@

all:$(PROG)

lib-recur all-recur clean-recur install-recur:
		@target=`echo $@ | sed s/-recur//`; \
		wdir=`pwd`; \
		list='$(SUBDIRS)'; for subdir in $$list; do \
			cd $$subdir; \
			$(MAKE) CC="$(CC)" CXX="$(CXX)" DFLAGS="$(DFLAGS)" CFLAGS="$(CFLAGS)" \
				INCLUDES="$(INCLUDES)" $$target || exit 1; \
			cd $$wdir; \
		done;

lib:libphylotree.a

libphylotree.a:$(LIBOBJS)
		$(AR) -cru $@ $(LIBOBJS)

njtree:lib-recur main.o
		$(CXX) $(CFLAGS) $(DFLAGS) main.o -o $@ $(LIBS)

flnjtree:lib-recur $(FLOBJS)
		$(CXX) $(CXXFLAGS) $(DFLAGS) -o $@ $(FLOBJS) `$(FLTKCFG) --cxxflags` `$(FLTKCFG) --ldstaticflags` $(LIBS)

timeout:timeout.o
		$(CC) $(CFLAGS) $(DFLAGS) timeout.o -o $@

make_ng86:make_ng86.o 
		$(CC) $(CFLAGS) $(DFLAGS) make_ng86.o -o $@

ng86_ds.h:make_ng86
		./make_ng86 $@

ng86_ds.o:ng86_ds.h ng86_ds.c

main.o:main.c
		$(CC) -c $(CFLAGS) $(DFLAGS) $(NJVERSION) main.c -o $@

tags:*.c *.cc phyml/*.c align_lib/*.c phyml/*.cc
		ctags *.c *.cc *.l *.y phyml/*.c phyml/*.cc align_lib/*.c common/*.h common/*.c

script:
		@sed 's/my $$version.*/my $$version = "$(VERSION)";/' run_njtree.pl > 1; mv 1 run_njtree.pl; \
		sed 's/my $$version.*/my $$version = "$(VERSION)";/' cgi_njtree.pl > 1; mv 1 cgi_njtree.pl; \
		chmod 755 *.pl

njtree.pdf:njtree.texi
		texi2pdf njtree.texi

tfdev.pdf:tfdev.texi
		texi2pdf tfdev.texi

y.tab.c y.tab.h:parser.y
		$(YACC) -d $(YFLAGS) parser.y

lex.yy.c:parser.l
		$(LEX) parser.l

order.o:algo.h

lex.yy.o:lex.yy.c y.tab.h
		$(CC) -c $(DFLAGS) $(CFLAGS) lex.yy.c -o $@

y.tab.cc:y.tab.c
		ln -sf y.tab.c y.tab.cc

y.tab.o:y.tab.cc
		$(CXX) -c $(DFLAGS) $(CFLAGS) y.tab.cc -o $@

set:
		@if [ `expr match "$(DFLAGS_SPEC)" ".*HAVE_PHYML.*"` -ne 0 ]; then echo 'yes'; fi

$(FLOBJS):flnjtree_ui.h flglobal.h
flnjtree_ui.cc flnjtree_ui.h:flnjtree_ui.fl
		$(FLUID) -c flnjtree_ui.fl

package:lex.yy.c y.tab.c
		@cd ..; cp -a phylotree /tmp; (cd /tmp/phylotree; find . -name "CVS"|xargs -i rm -fr {}; cd ..; \
		mv phylotree njtree-$(VERSION); tar cf - njtree-$(VERSION) | bzip2 ) > phylotree/njtree-$(VERSION).tar.bz2; \
		rm -fr /tmp/njtree-$(VERSION)

clean:
		rm -f gmon.out *.o a.out y.output libphylotree.a *.cp *.fn *.ky *.pg *.tp *.vr *.toc *.aux *.pdf *.log \
			njtree flnjtree timeout nh2pic flnjtree_ui.cc flnjtree_ui.h make_ng86 njtree-*.tar.bz2 ChangeLog.bak _phyml_boot*.txt \
			y.tab.cc tags common/*.o

cleanmore:clean
		rm -f ng86_ds.h lex.yy.c y.tab.*

distclean:clean-recur
		rm -f ng86_ds.h lex.yy.c y.tab.*
