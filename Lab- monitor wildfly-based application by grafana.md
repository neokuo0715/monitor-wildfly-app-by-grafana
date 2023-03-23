---
date: 2023-03-16 16:07
alias: []
---

# Metadata
Status :: #🌱  (筆記狀態) <br>
Source Type :: #📥/📰 (筆記資訊來源)<br>
Source URL :: [wildfly-todo-backend](https://github.com/wildfly/quickstart/tree/main/todo-backend)<br>
Author :: {作者名稱} <br>
Topics :: [[wildfly MOC]]、[[Docker MOC]]、[[kubernete MOC]]、[[maven MOC]]、[[實作MOC]]<br>
LAB目的 :: containerize wildlfy-app and montor it by grafana<br>
知識需求 :: embedded wildfly app、containrize app、kubernetes

# Evergreen Note
Question :: 這篇主要是在說什麼?
Answer ::  

# Summary

# Note
## prerequisites
- docker
- dockerhub
- minikube
## in this lab , you will learn:
- containerize your app & push to your images repo
- run your app on minikube
## steps
### 1. build wildfly-embedded application
1. git clone example project`todo-backend` [todo-backend](https://github.com/wildfly/quickstart/tree/main/todo-backend#run-the-backend-locally-as-a-bootable-jar)
2. in todo-backend folder  cmd : `$ mvn clean package -P bootable-jar-openshift`
3. run  Local PostgreSQL 
   ```python
     docker run --name todo-backend-db \
	  -e POSTGRES_USER=todos \
	  -e POSTGRES_PASSWORD=mysecretpassword \
	  -p 5432:5432 \
	  postgres
   ```  
4. find your virtual-machine ip ex : `docker-machine ls`
	```python
	$ docker-machine ls
		NAME          ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER      ERRORS
		wildfly-lab   -        virtualbox   Running   tcp://192.168.99.101:2376           v19.03.12
	```
5. run bootable jar app
```python
POSTGRESQL_DATABASE=todos \
  POSTGRESQL_SERVICE_HOST=<docker-machine ip:192.168.99.101> \
  POSTGRESQL_SERVICE_PORT=5432 \
  POSTGRESQL_USER=todos \
  POSTGRESQL_PASSWORD=mysecretpassword \
  POSTGRESQL_DATASOURCE=ToDos \
  java -jar target/todo-backend-bootable.jar
```
6. test app : `curl http://localhost:8080`
7. test app : `curl -X POST -H "Content-Type: application/json"  -d '{"title": "This is my first todo item!"}' http://localhost:8080/`
### 2. create Dockfile to containerize your app
1. create dockerfile
	```dockerfile
	# BUILD STAGE
	# from redhat website: https://catalog.redhat.com/software/containers/ubi8/openjdk-11/5dd6a4b45a13461646f677f4?container-tabs=gti&gti-tabs=unauthenticated
	FROM registry.access.redhat.com/ubi8/openjdk-11 
	WORKDIR /app
	
	COPY ./target/todo-backend-bootable.jar /app/todo-backend-bootable.jar
	
	# 8080 for services 、9990 for web console  
	EXPOSE 8080/tcp 9990/tcp 
	
	ENV TZ=Asia/Taipei
	ENV JAVA_OPTS=""
	
	# from wilfly to-do backend app, https://github.com/wildfly/quickstart/tree/main/todo-backend
	ENV POSTGRESQL_DATABASE=todos 
	ENV POSTGRESQL_SERVICE_HOST=localhost
	ENV POSTGRESQL_SERVICE_PORT=5432
	ENV POSTGRESQL_USER=todos
	ENV POSTGRESQL_PASSWORD=mysecretpassword
	ENV POSTGRESQL_DATASOURCE=ToDos
	
	ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS     -jar  /app/todo-backend-bootable.jar"]
	```
1. build image : `docker build -t <defination-your-image-name:wildfly-todo-backend> .`
	- indicate build image named `wildfly-todo-backend` at  `.`  folder. 
	- after successfully built run cmd to check : `docker images`
		```python
		$ docker images
		REPOSITORY                                   TAG       IMAGE ID       CREATED          SIZE
		wildfly-to-do-backend                        latest    3f49601debe0   46 seconds ago   522MB
		registry.access.redhat.com/ubi8/openjdk-11   latest    8d06f878cd4a   41 hours ago     391MB

		```
1. test locally
	1. cmd:  [[Lab- monitor wildfly-based application by grafana#1. build wildfly-embedded application]]
	```python
	run successfully 
	2023-03-17 03:32:02.491 UTC [1] LOG:  starting PostgreSQL 15.2 (Debian 15.2-1.pgdg110+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 10.2.1-6) 10.2.1 20210110, 64-bit
	2023-03-17 03:32:02.495 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
	2023-03-17 03:32:02.495 UTC [1] LOG:  listening on IPv6 address "::", port 5432
	2023-03-17 03:32:02.511 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
	2023-03-17 03:32:02.534 UTC [64] LOG:  database system was shut down at 2023-03-17 03:32:02 UTC
	2023-03-17 03:32:02.556 UTC [1] LOG:  database system is ready to accept connections
	```
	1. cmd : ` docker run --name todo-backend-1 -e POSTGRESQL_SERVICE_HOST=192.168.99.101 -p 8080:8080 <image-name:wildfly-to-do-backend>`
### 3. push image to your private DockerHub
1. before push, tag your image
	1. cmd : `docker tag <image-name:wildfly-todo-backend> <username:neo1234567>/<image-name:wildfly-todo-backend>:<define-your-tag:v1.0>`
2. push to dockerub
	1. cmd : `docker push <username:neo1234567>/<image-name:>:<tagversion>`
### 4. create cluster by minikube
1. `minikube delete && minikube start --kubernetes-version=v1.24.10 --cpus=4 --memory=6g --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.bind-address=0.0.0.0 --extra-config=controller-manager.bind-address=0.0.0.0 --no-vtx-check`
### 5. create & apply secret to grant permission from your private DockerHub
- by [pull-image-private-registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
1. `docker login`
2. View the `config.json` file: `cat ~/.docker/config.json`
3. create secret yaml, path example `/home/username/.docker/config.json`
	```python
	kubectl create secret generic regcred \
	    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
	    --type=kubernetes.io/dockerconfigjson
	```
4. check config.json in secret yaml : `kubectl get secret/regcred --output="jsonpath={.data.\.dockerconfigjson}"|base64 --decode`
### 6. create & apply wildfly-deployment 
1. create deploy 、service yaml [[Lab- monitor wildfly-based application by grafana#020_wildfly-base-app]] same as secret's namespace.
### 7.deploy prometheus and grafana into kubernetes
1. kube-prometheus ( use tool : prometheus-operator ) or prometheus.yaml with configuration yaml ( by configMap )
2. kube-prometheus as example, git clone kube-prometheus project & go into kube-prometheus folder: [[prometheus- monitor activemq#Tool 2 : kube-prometheus [github](https://github.com/prometheus-operator/kube-prometheus kube-prometheus)]]
	```python
	kubectl apply --server-side -f manifests/setup # create CRDS
	kubectl wait \
		--for condition=Established \
		--all CustomResourceDefinition \
		--namespace=monitoring
	kubectl apply -f manifests/ # included: grafana、alertmanagement、nodeExporter... etc
	```
3. change grafana version to 8.3.4 : `kubectl -n monitoring edit deploy/grafana`
4. test : `kubectl port-forward -n wildfly-ex-app svc/<your-app-service> <port-you-define>:<containerPort>`.
	1. `curl <your-service-name>:8080` to list your data
	2. `curl -X POST -H "Content-Type: application/json"  -d '{"title": "This is my first todo item!"}' http://<your-service-name>:8080/ ` to create the info.
## problem and solve
### problem : The connection to the server localhost:8080 was refused - did you specify the right host or port?
- scenario : any docker command invalided  
- check your virtual-machine whether it is running or not ex : `minikube profile list` 、`docker-machine ls`
### problem : Failed to pull image "what2468ba/nginx": rpc error: code = Unknown desc = Error response from daemon: manifest for username/nginx:latest not found: manifest unknown: manifest unknown
- scenario: apply deployment which images from privacy dockerhub
- need to add tag on you images resource ex (in deploy.yaml) : `spec.container[*].image:what2468ba/nginx:v0.1`
### problem : docker deamon is not running
- use docker related command occured
- solution : check docker-cli is binded with docker-machine ( or minikube )
	- cmd : `docker-machine env <your-virtual-machine-name:wildfly-lab>`。
	- cmd : `eval $(docker-machine env wildfly-lab)` set variables。
### problem : denied: requested access to the resource is denied
- scenario : docker push `<image>`。
- solution : 
	- cmd : `docker login`
	- cmd : `docker tag` ,confirm you tagged before you push the image.

### key point
- (learned) dockerfile options  `EXPOSE` means the port you want to let outside request
- (learned) sh -c means open another shell to execute the cmd 
- how to add env variables into container
- build 完的image 在哪裡?
- how to run local image in docker
- (learned) how to set env in deployment
	- `spec.tempate.spec.containers[*].env`
- how to find another namespace's service to request
	- use default defination[stackflow](https://stackoverflow.com/questions/37221483/service-located-in-another-namespace)
### example yaml
#### 001_namespace.yaml
```python
apiVersion: v1
kind: Namespace
metadata:
  name: database
---
apiVersion: v1
kind: Namespace
metadata:
  name: wildfly-ex-app
```
#### 002_secret-dockerhub.yaml
- generated from cmd : [[Lab- monitor wildfly-based application by grafana#5. create & apply secret to grant permission from your private DockerHub]]
```python
apiVersion: v1
kind: Secret
metadata:
  name: myregistrykey
  namespace: wildfly-ex-app # same as wildfly-example namesapce
data:
  .dockerconfigjson: # generated from ~/.docker/config.json 
type: kubernetes.io/dockerconfigjson
```
#### 010_postgreSQL
```python
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql-deployment
  namespace: database
  labels:
    application: postgresql-database
spec:
  replicas: 1
  selector:
    matchLabels:
      application: postgresql-database
  template:
    metadata:
      labels:
        application: postgresql-database
    spec:
      containers:
      - name: postgresql-database
        image: postgres:latest
        env: 
        - name: POSTGRES_USER
          value: "todos"
        - name: POSTGRES_PASSWORD
          value: "mysecretpassword"
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql-database-service
  namespace: database
spec:
  selector:
    application: postgresql-database
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
```
#### 020_wildfly-base-app
```python
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wildfly-app-deployment
  namespace: wildfly-ex-app
  labels:
    application: wildfly-ex-app
spec:
  replicas: 1
  selector:
    matchLabels:
      application: wildfly-ex-app
  template:
    metadata:
      labels:
        application: wildfly-ex-app
    spec:
      containers:
      - name: wildfly-ex-app
        image: what2468ba/wildfly-to-do-backend:v1.1
        env: 
        - name: POSTGRESQL_SERVICE_HOST
          value: "postgresql-database-service.database.svc.cluster.local"
        - name: POSTGRESQL_SERVICE_PORT
          value: "5432"
        - name: POSTGRESQL_USER
          value: "todos"
        - name: POSTGRESQL_PASSWORD
          value: "mysecretpassword"
        - name: POSTGRESQL_DATASOURCE
          value: "ToDos"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: wildfly-app-service
  namespace: wildfly-ex-app
spec:
  selector:
    application: wildfly-ex-app
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```
# Reference
- [check docker ID](https://docs.docker.com/docker-id/#log-in)
- [create 64encode for dockerHub-secret yaml](https://www.base64encode.org/)
- [docker-push-error-requested-access-to-the-resource-is-denied](https://forums.docker.com/t/docker-push-error-requested-access-to-the-resource-is-denied/64468/10)
- [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
- [orverride env variable](https://phoenixnap.com/kb/docker-environment-variables)
	- single : cmd `docker run -e "Key=value"`
	- multi : cmd `docker run --name <container-name> --env-file <path-to-env-file> <images-name>`
- [config prometheus by prometheus.yaml and monitored resource](https://se7entyse7en.dev/posts/how-to-set-up-kubernetes-service-discovery-in-prometheus/)
- [todo-backend](https://github.com/wildfly/quickstart/tree/main/todo-backend#run-the-backend-locally-as-a-bootable-jar)
- [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus kube-prometheus)