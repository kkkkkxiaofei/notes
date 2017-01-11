# Introduction

This [demo](https://github.com/kkkkkxiaofei/Spring-Cloud/tree/master/demo-for-config) is the basic tutorial for "Config Server/Client", and the usage of the services is below:

- `eureka-server`

The Eureka server to discovery other service.

- `config-server`

It's a Eureka client as well as config server, when start, it will firstly connect Eureka to be one of the cluster and then retrieve all config in config-repo, and listen on its port to wait other config client to connect.

- `config-repo`

Store all config files in Github Repo.

- `config-client`

It's a Eureka client as well as config client, it will start by getting config info from config-server.

- `compute-servcie`

Just for test, add more Eureka client.

# How To Demo 

- 1.`mvn spring-boot:run` to start `eureka-server`, lisenting on 1111

- 2.Start config-server like above. 

It will connect `eureka-server`, and then fetch the info from `config-repo` on Github. After successfully start up, you can try `http://localhost:7001/env` or `http://localhost:7001/didispace/dev` to see the detailed or specified config info.
The mapping relationship is `/{application}/{profile}[/{label}]`, and default label is `master`.

- 3.Start config-client

It will successfully connect the `eureka-server`: Some configs are defined in `bootstrap.properties` to connect `config-server`, but nothing for `eureka-server`. Because it can use this config info to find the specified detailed config info from `config-sever`. In this case, `config-server` has fetched the config of `dev` label in `repo-config`, it is defined in `didispace-dev.properties` 

- 4.It's up for you to start `compute-service`

# Referrence

[Thanks for this blog](http://blog.didispace.com/springcloud4)

