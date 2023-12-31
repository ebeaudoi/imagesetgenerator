# imagesetgenerator
Script to create ImageSetConfiguration file to be used with oc-mirror
Description:

Depending on how many Operators you want to prune.  It can take a lot of time to generate the “ImageSetConfiguration” YAML file for the first time. 

This tool has been created to facilitate the process and generate a valid “ImageSetConfiguration” YAML file.

**Prerequisites:**

- Download the script locally
- Oc-mirror properly configured with the authentication
- Ref: <https://docs.openshift.com/container-platform/4.13/installing/disconnected_install/installing-mirroring-disconnected.html#oc-mirror-mirror-to-disk_installing-mirroring-disconnected>
- Downloading software: <https://console.redhat.com/openshift/downloads>

**How it works:**

- First, you need to identify the Operators you need and which catalogs they belong too.

- Next, you need to update the below variables of the script:

  - OPERATORFROM options: redhat,certified, community or marketplace

  - CVERSION options: v4.12, v4.13, v4.14

  - CREGIS options: 

    - registry.redhat.io/redhat/redhat-operator-index
    - registry.redhat.io/redhat/certified-operator-index
    - registry.redhat.io/redhat/community-operator-index
    - registry.redhat.io/redhat/redhat-marketplace-index

  - KEEP="\<List of Operators need to be pruned for a specific catalog>"

- Run the script:

./generate-imagesetconfigurationyamlfile.sh

- Output:
  The script generate three files
  - The text files stage1 and stage2 are for validation and/or to give extra information about the Operators
  - The yaml file is the "ImageSetConfiguration"
