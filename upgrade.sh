#!/bin/bash

# Delete lock file, because OpenTofu currently has readonly access to it, so it won't update anything if it exists.
rm .terraform.lock.hcl

# Comment out all module versions so `tofu init -upgrade` can pull the latest versions.
grep -rI --exclude-dir bootstrap --exclude-dir .git --exclude-dir .terraform -E '^[ ]+version[ ]+=' -l | xargs sed -Ei 's/^([ ]+)version /#\1version /'

# Upgrade everything!
tofu init -upgrade

# Show new versions?
cat .terraform/modules/modules.json | jq -r '.Modules[] | "\(.Source) \(.Version)"' | sort -u

echo "Now open a new terminal and go manually update the versions and uncomment them..."
