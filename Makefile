pull_hs_config:
	cp ~/.hammerspoon/init.lua .
	cp ~/.hammerspoon/tradingOverlay.lua

push_hs_config:
	cp init.lua ~/.hammerspoon/init.lua
	cp tradingOverlay.lua ~/.hammerspoon/tradingOverlay.lua

all: #install lint test