targetDir = $$HOME/testCreate
suffix = mybackup
backupOpt = --backup=simple --suffix=.$(suffix)

install:
	@cd src; \
	for dir in `find . -type d`; do \
		echo Creating directory $(targetDir)/$$dir; \
		install -m 755 -d $(targetDir)/$$dir; \
		for file in `find $$dir -maxdepth 1 -type f`; do \
			echo installing $$file; \
			install -m 644 $(backupOpt) $$file $(targetDir)/$$dir; \
		done; \
		echo ""; \
	done; \

uninstall:
	@cd src; \
	for dir in `find . -type d | tac`; do \
		for file in `find $$dir -maxdepth 1 -type f`; do \
			if [ -f $(targetDir)/$$file ]; then \
				echo Removing $(targetDir)/$$file; \
				rm -f $(targetDir)/$$file; \
				if [ -f $(targetDir)/$$file.$(suffix) ]; then \
					echo Restoring $(targetDir)/$$file.$(suffix); \
					mv $(targetDir)/$$file.$(suffix) $(targetDir)/$$file; \
				fi; \
			fi; \
		done; \
		if [ -d $(targetDir)/$$dir ] && \
		   [ -z "`ls -A $(targetDir)/$$dir`" ] && \
			 [ $$dir != . ]; then \
			echo Removing $(targetDir)/$$dir; \
			rmdir $(targetDir)/$$dir; \
		fi; \
	done; 

