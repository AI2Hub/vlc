# TagLib

TAGLIB_VERSION := 1.13.1
TAGLIB_URL := https://taglib.org/releases/taglib-$(TAGLIB_VERSION).tar.gz

PKGS += taglib
ifeq ($(call need_pkg,"taglib >= 1.9"),)
PKGS_FOUND += taglib
endif

$(TARBALLS)/taglib-$(TAGLIB_VERSION).tar.gz:
	$(call download_pkg,$(TAGLIB_URL),taglib)

.sum-taglib: taglib-$(TAGLIB_VERSION).tar.gz

taglib: taglib-$(TAGLIB_VERSION).tar.gz .sum-taglib
	$(UNPACK)
	$(APPLY) $(SRC)/taglib/0001-Implement-ID3v2-readStyle-avoid-worst-case.patch
	$(MOVE)

.taglib: taglib toolchain.cmake
	rm -f $</CMakeCache.txt
	cd $< && $(HOSTVARS_PIC) $(CMAKE)
	+$(CMAKEBUILD) $< --target install
	touch $@
