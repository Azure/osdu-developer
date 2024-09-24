# NOTE

This module is tightly coupled to the csv-parser dag. It is used to upload a file to a blob storage account and then execute a script on the file.

It shouldn't be done this way and we have to move this to a kubernetesjob that can run a python script and just copy into a pvc mount.