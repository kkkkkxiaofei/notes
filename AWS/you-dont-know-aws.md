### NACL vs Route Tables vs Secruity Group

`NACL`: (Network access control list)类似防火墙，规定了网络inbound/outbound的权限，你需要描述什么样的协议(Protocol)，什么样的端口以及什么样的ip段具有怎么样的访问权限（Allow/Deny)。它隶属于VPC，即一个VPC可以拥有多个ACL（比如private/public acl）。它作用于subnet上，即ACL可以绑定多个subnet。

`Route Tables`: 当到达路由表时，就代表`ACL`已经通过，，比如路由表里定义`destination`为`0.0.0.0/0`， `target`为`Internet Gateway`,那就代表如果有traffic的目的是外网，那么将会用于互联网网关来把它导向目的地，因此它是public的。此外，路由表也是作用在subnets上的。

`Secruity Group`: 也类似于防火墙，也需要定义inbound/outbound，但是它针对的是instance或loader balancer，它往往会定义一些端口暴露，支持的协议以及ip段。


