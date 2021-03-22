# DOSBOX IN A CONTAINER WITH VNC CLIENT

So much fun!

1. Create a folder.
1. Place a copy of your game in the folder. I am using the shareware version of Commander Keen here.
1. In that folder, create a file called `dockerfile`, paste in the following code.

  ````

FROM ubuntu:20.10
ENV USER=root
ENV PASSWORD=password1
ENV DEBIAN_FRONTEND=noninteractive 
ENV DEBCONF_NONINTERACTIVE_SEEN=true
COPY keen /dos/keen
RUN apt-get update && \
	echo "tzdata tzdata/Areas select America" > ~/tx.txt && \
	echo "tzdata tzdata/Zones/America select New York" >> ~/tx.txt && \
	debconf-set-selections ~/tx.txt && \
	apt-get install -y tightvncserver ratpoison dosbox novnc websockify && \
	mkdir ~/.vnc/ && \
	mkdir ~/.dosbox && \
	echo $PASSWORD | vncpasswd -f > ~/.vnc/passwd && \
	chmod 0600 ~/.vnc/passwd && \
	echo "set border 0" > ~/.ratpoisonrc  && \
	echo "exec dosbox -conf ~/.dosbox/dosbox.conf -fullscreen -c 'MOUNT C: /dos' -c 'C:' -c 'cd keen' -c 'keen1'">> ~/.ratpoisonrc && \
	export DOSCONF=$(dosbox -printconf) && \
	cp $DOSCONF ~/.dosbox/dosbox.conf && \
	sed -i 's/usescancodes=true/usescancodes=false/' ~/.dosbox/dosbox.conf && \
	openssl req -x509 -nodes -newkey rsa:2048 -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 -subj "/C=US/ST=NY/L=NY/O=NY/OU=NY/CN=NY emailAddress=email@example.com"
EXPOSE 80
CMD vncserver && websockify -D --web=/usr/share/novnc/ --cert=~/novnc.pem 80 localhost:5901 && tail -f /dev/null

````

1. Replace the COPY keen /dos/keen with your game (ie. COPY wolf3d /dos/wolf3d). 1. You can also change the default password, or override it with a -e parameter when you run the image.
1. Now, with Docker, build the image. I’m assuming you already have Docker installed and are familiar with it to some extent. CD to the directory in a console and run the command…
  ````
  docker build -t mydosbox .
  ````
1. Run the image.
  ```` 
   docker run -p 6080:80 mydosbox
   ````
   
1. Open a browser and point it to http://localhost:6080/vnc.html
1. You should see a prompt for the password. Type it in, and you should be able to connect to your container with DosBox running. The game is started automatically.
1. Once your image is built, you can push it to your image repository with docker push, but you’ll need to tag it appropriately.

# USE WITH KUBERNETES
Kubernetes is another part of the equation when it comes to container apps. Containers on Kubernetes are deployed into pods, which are then usually a part of a part of a deployment, which will have one or more pods associated with it. Deployments can also be used for creating scalable sets of pods for high availability too on a Kubernetes cluster. If you’re not familiar with Kubernetes, check out this webinar below where I go in depth on the matter.

Deployments and services can be defined declaratively with a YAML file. Below is a Kuberenetes YAML file that defines a deployment and a service for my retro gaming container.

The deployment is simple – it points to a single container image called blaize/keen and then tells Kubernetes what ports to expose for the container. The service defines how the deployment will be exposed on a network. In this case, it’s using a TCP load balancer, where it is exposing port 80 and mapping that to the port exposed by the deployment. The service uses selectors on the label app to match the service with the deployment.

````
apiVersion: v1
kind: Service
metadata:
  name: keen-service
  labels:
    app: keen-deployment
spec:
  ports:
  - port: 80
    targetPort: 6080
  selector:
    app: keen-deployment
  type: LoadBalancer
---
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: keen-deployment
spec:
  selector:
    matchLabels:
      app: keen-deployment
  replicas: 1
  template:
    metadata:
      labels:
        app: keen-deployment
    spec:
      containers:
      - name: master
        image: blaize/keen
        ports:
        - containerPort: 80
````

To connect use this, first create a file called keen.yaml file, configure your instance kubectl to work with your instance of Kubernetes, then run deploy the sample.

````
kubectl create -f keen.yaml
````

When this is deployed to Kubernetes, Kubernetes will configure the external network to open on port 80 to listen to incoming requests. When used on Azure Kubernetes Services, AKS will create and map a public IP address (htttp://[your ip address]/vnc.html) for the service. Once connected, you can point your browser to the IP address of your cluster and have fun playing your retro games!
