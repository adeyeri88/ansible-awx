# ansible-awx
Collection of AWX-related files

When implementing Ansible AWX, I created a couple files to make it more useful and am sharing with the world here.

**awx-puppetdb.sh** - An Ansible Tower/AWX inventory script that pulls data from Puppet's excellent PuppetDB, see comments at the top of the script for usage instructions. Once setup in AWX, schedule it to run regularly so your inventory is up-to-date.

**awx_gather_facts.yml** - Stupid simple ansible playbook to add to Tower/AWX as a template with 'Enable Fact Cache' enabled and run on a schedule shortly after your regular inventory update. By doing this, AWX will cache facts and you can very easily create smart inventories based ansible or facter facts.
