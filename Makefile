VERSION ?= 6.6.30
CASE ?= default

.PHONY: help check fetch config kernel busybox rootfs initramfs workspace run up clean case

help:
	@echo "make check"
	@echo "make workspace VERSION=6.6.30 CASE=default"
	@echo "make up VERSION=6.6.30 CASE=default"
	@echo "make case CASE=my-new-case"

check:
	./lab.sh check

fetch:
	./lab.sh fetch $(VERSION)

config:
	./lab.sh config $(VERSION)

kernel:
	./lab.sh kernel $(VERSION)

busybox:
	./lab.sh busybox

rootfs:
	./lab.sh rootfs $(VERSION) $(CASE)

initramfs:
	./lab.sh initramfs $(VERSION) $(CASE)

workspace:
	./lab.sh workspace $(VERSION) $(CASE)

run:
	./lab.sh run $(VERSION) $(CASE)

up:
	./lab.sh up $(VERSION) $(CASE)

clean:
	./lab.sh clean $(VERSION)

case:
	./lab.sh case $(CASE)
