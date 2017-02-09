# Introduction

This is the [demo](https://github.com/kkkkkxiaofei/Spring-Cloud/tree/master/demo-for-zuul) to illustrate the workflow of zull.

# How To Demo

- 1.Start `eureka-server` and `compute-service` one by one. 

As you see, `compute-service` exposes a api for external invoking. We can get the result of ***From Service-A, Result is 23*** by send get request `http://localhost:2222/add?a=1&b=22`. It doesn't make sense cause it has exposed the domain.

- 2.Start `api-gateway`.

This Eureka client roles as a gate way to redirect the address by mapping the route and serviceId you defined.

api-gateway.domain:5555/api/**  --> compute-service.domain:2222/**

api-gateway.domain:5555/api/add?a=1&b=2&accessToken=token  --> compute-service.domain:2222/add?a=1&b=2&accessToken=token

Also, you can define a custom filter to validate your request.