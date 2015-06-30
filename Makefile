
version: 
	agvtool what-marketing-version
	agvtool what-version
set-version:
	agvtool new-marketing-version $(filter-out $@,$(MAKECMDGOALS))
set-build:
	agvtool new-version -all $(filter-out $@,$(MAKECMDGOALS))
increment-build:
	agvtool next-version -all
%: # to do nothing
	@:
