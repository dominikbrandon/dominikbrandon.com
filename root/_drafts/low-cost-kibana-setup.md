---
layout: post
cover: '/assets/images/cover-code.webp'
navigation: True
title: 'Low-cost Kibana setup that everyone can afford'
# date: 2022-10-08 11:00:00
tags: [Tips and tricks, Observability, Logs, Kibana, Infrastructure]
subclass: 'post'
author: dominik
categories: dominik
# description: 'My approach to using helper methods for assertions in Spock'
---

Have you ever found yourself in a place where reading logs feels inefficient
because your best way of doing this is grepping through plain text? Do you
miss the experience of Kibana, which embraces histograms, visualizations, and
filtering, but your working environment does not provide that?

Well, that had been the case for me, but with a bit of effort, I've managed to
find a good-enough solution. It bases on running Kibana on your local
machine, so there's no additional server cost for your company. Together with
the setup of ingesting logs from the file, it provides a very flexible way
of running Kibana on demand.

Log storage together with the whole Kibana stack may indeed cost an arm and
a leg, so companies may be hesitant to incorporate it into their infrastructure.
Using the approach described below might be a quick win for you if you need
Kibana ad hoc.

#### Prerequisites

- local Kubernetes cluster, I used [minikube](https://github.com/kubernetes/minikube){:target="_blank" rel="noopener noreferrer"}
- [Helm](https://helm.sh/){:target="_blank" rel="noopener noreferrer"} installed

#### Step-by-step guide

##### Running ELK stack

<ol>
<li>
Clone <a href="https://github.com/elastic/helm-charts" target="_blank" rel="noopener noreferrer">the repo</a>
delivered directly by the Elastic team (thanks for that!).
{% highlight sh %}
git clone git@github.com:elastic/helm-charts.git
{% endhighlight %}
</li>
<li>
Checkout a specific tag, so that all components are compatible with each
other. At the time of writing this post, the newest one is <code>v7.17.3</code>.
{% highlight sh %}
git checkout tags/v7.17.3
{% endhighlight %}
</li>
<li>
Run Elasticsearch, Logstash and Kibana. Commands below will create 
<a href="https://helm.sh/docs/topics/architecture/#the-purpose-of-helm" target="_blank" rel="noopener noreferrer">Helm releases</a>.
{% highlight sh %}
cd elasticsearch/examples/minikube
make install
cd ../../../logstash/examples/elasticsearch
make install
cd ../../../kibana/examples/default
make install
{% endhighlight %}
</li>
<li>
You should be able to see the pods up and running. If instead of
<code>Running</code> status, you see <code>ImagePullBackOff</code>, see below.
{% highlight sh %}
➜  ~ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
elasticsearch-master-0       1/1     Running   0          100m
elasticsearch-master-1       1/1     Running   0          100m
elasticsearch-master-2       1/1     Running   0          100m
helm-kibana-default-kibana   1/1     Running   0          53s
helm-logstash-elasticsearch  1/1     Running   0          3m51s
{% endhighlight %}
</li>
<ul><li>
What to do if your pods are in <code>ImagePullBackOff</code> status? This means that
downloading Docker image have reached timeout or failed. There can be multiple
reasons for that. You can investigate it further by running:
{% highlight sh %}
kubectl describe pod elasticsearch-master-0
{% endhighlight %}

If the reason is, for example, slow internet connection, you can load the
image manually, as shown below:
{% highlight sh %}
docker pull docker.elastic.co/elasticsearch/elasticsearch:7.17.3
minikube image load docker.elastic.co/elasticsearch/elasticsearch:7.17.3
minikube image list
{% endhighlight %}
</li></ul>
<li>
Enable port forwarding. After that you should be able to access
<a href="http://localhost:5601" target="_blank" rel="noopener noreferrer">http://localhost:5601</a>
and see Kibana interface.
{% highlight sh %}
kubectl port-forward svc/helm-kibana-default-kibana 5601
{% endhighlight %}
</li>
</ol>

Congratulations, you now have the whole ELK stack up and running on your local
machine and you can even load some logs manually from a file in order to get
into play quickly. That was fast and easy, wasn't it?

##### Ingesting automatically from a file

You can already load logs manually, but you may want to utilize more automatic
approach in order to follow them in the real time, as they appear.

kubectl port-forward svc/elasticsearch-master 9200

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.3-darwin-x86_64.tar.gz
tar xzvf filebeat-7.17.3-darwin-x86_64.tar.gz
cd filebeat-7.17.3-darwin-x86_64
vim filebeat.yml

 - type: filestream

   # Change to true to enable this input configuration.
   enabled: true

   # Paths that should be crawled and fetched. Glob based paths.
   paths:
     - /Users/dominik/tmp.log

kubectl port-forward svc/elasticsearch-master 9200
