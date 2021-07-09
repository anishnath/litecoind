# Litecoind 

Docker image runs the Litecoin **litecoind node** in a secure container enviroment

## Security Consideration

- Run as **non-root**  the username:group=`litecoin:litecoin`
- `supervisord` for monitoring the process
- litecoind `gpg` checks 
- slim images



## Compiling 

```bash
docker build -t anishnath/litecoind .
```

## Running Litecoin

Run the  Litecoin node with the default options 

`. Create and run a container with the `anishnath/litecoind` image.

```
docker run  -d \
    -v litecoind-data:/litecoin-data \
    -p 9333:9333 \
    anishnath/litecoind
```

This will create a  litecoind container which gets the host's port `9333 ` forwarded to it. In this case the data is ephermal and will destroyed when the container is stopped or killed

```
❯ docker ps
CONTAINER ID IMAGE  COMMAND  CREATED STATUS  PORTS NAMES
aec7b8dc05b9 anishnath/litecoind  "/usr/bin/supervisor…" 4 seconds ago Up 2 seconds (health: starting) 9332/tcp, 0.0.0.0:9333->9333/tcp, :::9333->9333/tcp heuristic_sammet
```


2. Inspect the output of the container by using docker logs

```
docker logs -f aec7b8dc05b9
```

```
❯ docker logs -f aec7b8dc05b9
2021-07-09 12:48:15,529 INFO Included extra file "/etc/supervisor/conf.d/litecoin.conf" during parsing
2021-07-09 12:48:15,540 INFO RPC interface 'supervisor' initialized
2021-07-09 12:48:15,540 CRIT Server 'unix_http_server' running without any HTTP authentication checking
2021-07-09 12:48:15,540 INFO supervisord started with pid 1
2021-07-09 12:48:16,548 INFO spawned: 'litecoind' with pid 10
2021-07-09T12:48:16Z Litecoin Core version v0.18.1 (release build)
......
......
.....
```

## Custom configs 

To pass the custom `litecoind.conf`  and to map host volume for the data persistence 
```
docker run  \
    -v $PWD/data:/litecoin-data \
    -v $PWD/conf/litecoind.conf:/litecoin-conf \
    -p 9333:9333 \
    anishnath/litecoind
```

Using docker-compose.yml

```
services:
  litecoind:
    image: anishnath/litecoind
    ports:
    - 9333:9333
    volumes:
    - $PWD:/litecoin-data
    - $PWD/conf/litecoind.conf:/litecoin-conf
version: '3'
```

```
docker-compose -f docker-compose.yml up
```


We can use docker volume also 


Create a **[volume](https://docs.docker.com/storage/volumes/#create-and-manage-volumes)** for the litecoin data and conf for [litecoind.conf](https://litecoin.info/index.php/Litecoin.conf) file

```bash
docker volume create --name=litecoind-data
```
and then run 

```
docker run  \
    -v litecoind-data:/litecoin-data \
    -v $PWD/conf/litecoind.conf:/litecoin-conf \
    -p 9333:9333 \
    anishnath/litecoind
```


**Note**

The file permissions set on content in the volume are identical from the perspective of host as well as container.



## Vulnerability scans 

Using Anchore to scan the docker image and reporting the vulnerability 

```
sh-4.4$ anchore-cli image add anishnath/litecoind
Image Digest: sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf05
Parent Digest: sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf05
Analysis Status: not_analyzed
Image Type: docker
Analyzed At: None
Image ID: f4f42928cefd9ae6e84ae8b05163376704e70e00fe6873985e4ae1c9b0acd0a8
Dockerfile Mode: None
Distro: None
Distro Version: None
Size: None
Architecture: None
Layer Count: None
Full Tag: docker.io/anishnath/litecoind:latest
Tag Detected At: 2021-07-09T13:03:00Z
```

The image is in `not_analyzed` state now after some time it will move to `analyzed` state

```
sh-4.4$ anchore-cli image vuln  sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf05
os: available
non-os: available
all: available
```

```
sh-4.4$ anchore-cli image vuln  sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf05  all
```


Generate the Vulnerability report through  (utility script)

```
root@496fa1335bac:/opt# python report.py
Get Image Vuln: Format (sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf05)  sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf05
Input Basic Authorization:
Vun Report Generated sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf0520210709-131246.csv
```

## Kuberenetes (statefulset)

I'm using my [own kubernetes tool](https://8gwifi.org/kube.jsp)  for kubernetes statefull set configuration

```yaml
#kubernetes YAML file for the Service litecoind.yml
#This is Service Configuration Kube definition
---
apiVersion: v1
kind: Service
metadata:
  name: litecoind.service
  namespace: default
spec:
  ports:
  - name: rpcport
    port: 9333
    protocol: tcp
    targetPort: 9333
  selector:
    app: litecoind
  type: NodePort

#This is StatefulSet Configuration Kube definition
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: litecoind
  name: litecoind.statefulset
  namespace: default
spec:
  podManagementPolicy: OrderedReady
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: litecoind
  serviceName: litecoind.service
  template:
    metadata:
      labels:
        app: litecoind
      namespace: default
    spec:
      containers:
      - image: anishnath/litecoind
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9333
          name: portname.0
          protocol: tcp
        volumeMounts:
        - mountPath: /litecoin-data
          name: pvo.0
        - mountPath: /litecoin-conf
          name: pvo.1
      terminationGracePeriodSeconds: 0
      volumes:
      - name: pvo.0
        persistentVolumeClaim:
          claimName: claimname.0
      - name: pvo.1
        persistentVolumeClaim:
          claimName: claimname.1
  volumeClaimTemplates:
  - accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 1Gi
    volumeName: pvo.0
  - accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 1Gi
    volumeName: pvo.1


#This is PersistentVolume Kube Object with Name
#pvo.0.yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvo.0
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 10Gi
  hostPath:
    path: $PWD
    type: Directory
  persistentVolumeReclaimPolicy: Retain

#This is PersistentVolume Kube Object with Name
#pvo.1.yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvo.1
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 10Gi
  hostPath:
    path: $PWD/conf/litecoind.conf
    type: Directory
  persistentVolumeReclaimPolicy: Retain
```


