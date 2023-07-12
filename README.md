# DOSBOX IN A CONTAINER WITH VNC CLIENT

So much fun! After 3 years, I decided to bite the bullet and figure out how to add sound... and now it has it. I completely overhauled the Dockerfile to use Suerpvisor to start the processes because there were simply too many after adding support for sound. The rest of it is similar to the original, which is in an archive folder in this repo. In any case, I hope you enjoy it!

1. Clone the repo: `git clone https://github.com/theonemule/dos-game.git`
1. Place a copy of your game in the folder. I am using the shareware version of Commander Keen here.
1. Replace the `COPY keen /dos/keen` with your game (ie. COPY wolf3d /dos/wolf3d). 1. You can also change the default password or override it with a -e parameter when you run the image.
1. Now, with Docker, build the image. I’m assuming you already have Docker installed and are somewhat familiar with it. CD to the directory in a console and run the command…
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
Kubernetes is another part of the equation when it comes to container apps. Containers on Kubernetes are deployed into pods, which are then usually a part of a deployment with one or more pods associated. Deployments can also be used to create scalable sets of pods for high availability on a Kubernetes cluster. If you’re unfamiliar with Kubernetes, check out this webinar below, where I go in-depth.

Deployments and services can be defined declaratively with a YAML file. Below is a Kubernetes YAML file that defines a deployment and a service for my retro gaming container.

The deployment is simple – it points to a single container image called blaize/keen and then tells Kubernetes what ports to expose for the container. The service defines how the deployment will be exposed on a network. In this case, it’s using a TCP load balancer, exposing port 80 and mapping that to the port exposed by the deployment. The service uses selectors on the label app to match the service with the deployment.

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

To connect, use this, first create a file called keen.yaml file, configure your instance kubectl to work with your instance of Kubernetes, then run deploy the sample.

````
kubectl create -f keen.yaml
````

When this is deployed to Kubernetes, Kubernetes will configure the external network to open on port 80 to listen to incoming requests. When used on Azure Kubernetes Services, AKS will create and map a public IP address (htttp://[your ip address]/vnc.html) for the service. Once connected, you can point your browser to the IP address of your cluster and have fun playing your retro games!
