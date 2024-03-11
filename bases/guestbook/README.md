# Deploy a PHP Guestbook Application

This directory contains the Kubernetes manifests for deploying the PHP Guestbook Application

* with [MongoDB](https://docs.vmware.com/en/VMware-Cloud-Foundation/services/vcf-developer-ready-infrastructure-v1/GUID-6F184EC5-AFC1-4D0A-A5D5-1E31EE938438.html?hWord=N4IghgNiBcIOYFcCmBnALgIwPZYNYgF8g)
* with [Redis](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-A19F6480-40DC-4343-A5A9-A5D3BFC0742E.html)

## Transfer Images

Download images from Docker and transfer them to Harbor

```console
../../scripts/copy-images.sh -m images.yml
```

## Deploy

Apply based upon your choice of storage

* thin-disk and mongodb

  ```sh
  clusterDomain=$CLUSTER kubectl apply -k thin-disk/mongo
  ```

* nas-performance and mongodb

  ```sh
  clusterDomain=$CLUSTER kubectl apply -k nas-performance/mongo
  ```

* nas-premium and mongodb

  ```sh
  clusterDomain=$CLUSTER kubectl apply -k nas-premium/mongo
  ```

## Connect to MongoDB shell

* Open a shell into the mongo-client

  ```sh
  kubectl exec deploy/mongo-client -it -- /bin/bash
  ```

* Login to the MongoDB shell

  ```sh
  root@mongo-client-d4b459cd8-28wdq:/# mongo --host mongo --port 27017
  MongoDB shell version v4.2.24
  connecting to: mongodb://mongo:27017/?compressors=disabled&gssapiServiceName=mongodb
  Implicit session: session { "id" : UUID("0eebec08-610a-4637-96aa-7126bf80b33b") }
  MongoDB server version: 4.2.24
  ```

* Display list of DBs

  ```sh
  > show dbs
  admin      0.000GB
  config     0.000GB
  guestbook  0.000GB
  local      0.000GB
  ```

* Use the guestbook db

  ```sh
  > use guestbook
  switched to db guestbook
  ```

* Display a list of collections inside the `guestbook` database

  ```sh
  > show collections
  messages
  ```

* Display messages from the `guestbook` database

  ```sh
  > db.messages.find()
  { "_id" : ObjectId("65b9352cf2749d797418d582"), "message" : ",mark" }
  { "_id" : ObjectId("65b9352eb6334019d223d2b2"), "message" : ",mark,ron" }
  > 
  ```
