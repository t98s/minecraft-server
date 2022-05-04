archive: gcf-minecraft-starter.zip

force-apply: archive
	terraform apply --auto-approve

gcf-minecraft-starter.zip: gcf-minecraft-starter/package.json
	rm -f gcf-minecraft-starter.zip
	cd gcf-minecraft-starter && npm run archive
