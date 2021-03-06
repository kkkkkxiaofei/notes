### 1. 缓存

#### 1.1 强缓存

强缓存若生效，则无需和服务器交互，直接返回200(from cache)，强缓存的头部有以下：

`Cache-Control`

- no-store
  表明当前资源不能被缓存，对于频繁改动且重要的资源这是必须的。
- no-cache
  表明当前资源可以被缓存，但在到达客户端之前需要重新验证新鲜度，若验证发现缓存依然有效则返回304（避免下载）。
- public/private
  public表明缓存可以被中间环节缓存（如CDN)；private则是浏览器级别，外部无法缓存。
- max-age
  表明缓存过期时间，优先级最高。

`Expires`: 若max-age没设，则会查看该值，优先级次之。该值为GMT时间，在此时间之前都会命中强缓存。


#### 1.2 协商缓存

当没有命中强缓存后，浏览器会向服务器询问一次是否还能应用缓存，若服务器决策后的结果还有缓存，则返回304（not modified)。协商缓存的头部有以下：

- Last-Modified/If-Modified-Since

浏览器首次请求资源时，由于没有缓存，服务器后返回资源，且带有`Last-Modified`的头（GMT时间）。浏览器第二次请求该资源的时候，会加上`If-Modified-Since`，这个值就是上次从服务器返回的`Last-Modified`。若两值相等，则返回304(不返回资源），否者重新生成头信息并返回资源。

- ETags/If-Non-Match

`ETags`与 `Last-Modified`的原理类似，但是`Etags`不是时间，而是资源的唯一标示（内容hash），只要没变则缓存继续有效。

两者结合的好处：

1. 多次对资源的时间进行修改，但内容不变，这时Etags就可以保证缓存依然有效。
2. 秒级内多次更改资源，但由于`Last-Modified`粒度在秒级，所以无法即时让缓存失效（不新鲜缓存），因此ETags就可以保证返回新资源。

*** ps: Last-Modified 和 Etags可以一起使用，Etags的优先级较高***

### 2.xss vs csrf

xss一般主要是html类型的的脚本被上传至服务器，而后其他用户访问到相关资源后会执行该脚本，从而产生数据安全隐患。

`措施`：

1.纯前端渲染。比如利用React技术栈，为什么我们没有考虑过xss呢？那是因为项目里没有使用`dangerouslySetInnerHTML`，除此之外在React的世界里，操作dom只会用innerText，因此不会有脚本注入的问题。

2.解析特殊标签，如`<>`；

csrf一般指A网站里有B网站的广告（第三方），正常情况下如果在A登陆后会存储A的cookie，此时如果这个广告里有一个攻击脚本，该脚本会模拟用户去访问A，那这样的话，就会把A站点之前的cookie带过去，就会让服务器误以为这是A，从而为此敞开大门，为所欲为。

`措施`:

1.Samesite属性，Strict（只第一方带cookie），Lax(第三方的get会带cookie），None（都带），所以大部分情况将samesite设置为Lax并且请求改为post即可

2.增加身份认证，其实B站点的攻击脚本并不能拿到A请求里的信息，只依赖于cookie，如果可以增加更多的信息来认证client的话也是可以的，比如origin, csrf-token

3.本质上1可以解决很多，但是如果真有攻击脚本的话，应该避免xss，这样也就无法注入其他类似iframe的东西了

> ps: 只有后端设置`Access-Control-Allow-Credentials: true` 且前端请求时header里`credentials: include`才可以把cookie发送到服务器。

[csrf方案by美团](https://tech.meituan.com/2018/10/11/fe-security-csrf.html)

### 3. Cookie

常见属性：

`HttpOnly`: js无法通过document.cookie获取cookie，只应用于服务端。
`Secure`: Cookie只在https的站点生效。
`Domain/Path`: 哪些domain（域）和路径可以接受Cookie。
`SameSite`: 在跨站请求时Cookie的使用条件（参考1），以前如果不设置SameSite，浏览器会默认为None，但是目前浏览器的最新行为是：如果没有值，则设为Lax，需要注意。

第三方Cookie:

Cookie中有domain（域），若域与网站的域一致，则为第一方Cookie;否则为第三方Cookie。

第三方Cookie常用于广告跟踪，但往往也会到来网络安全问题(参考1)。

### 4. 条件式请求

条件式请求：根据http头部信息的条件来决定response的结果，通常会利用文件的修改时间`Last-Modified`和文件资源表示标识`ETag`来进行验证，主要用途就是缓存和资源上/下传。

常用的条件header:

`If-Match`: 若远端资源标识与请求头部中的`ETag`相等，则表示匹配成功。

`If-Not-Match`: 与之上相反。

`If-Modified-Since`: 如果远端资源头部中的`Last-Modified`比该值晚，则匹配成功。

`If-Unmodified-Since`: 与之上相反。

`If-Range`: 值为日期，若匹配成功则返回`206 Partial Content`, 否则返回`200 完整资源`。


缓存例子：

1. client -> server

```
GET /doc HTTP/1.1
```

向服务端请求资源。

2. server -> client

```
HTTP/1.1 200 OK
Last-Modified: date1
ETag: "xxx1"
```

首次请求没有缓存，返回200，且头部有资源信息标识。

3. client -> server

```
GET /doc HTTP/1.1
If-Modified-Since: date1
If-None-Match: "xxx1"
```
再次请求资源，若在服务端中找不到资源`ETag`为`xxx1`或修改时间比date1要早，则不匹配，那么就会返回`200`，否则就是`304`。

4. server -> client

若`304`:

```
HTTP/1.1 304 Not Modified
```
这里虽然也有一次请求，但只是一次试探，远比请求资源要代价小的多。

若`200`:

```
HTTP/1.1 200
Last-Modified: date2
ETag: "xxx2"
```

刷新缓存，更新资源标识。


### 5. HTTP1/1.X VS HTTP/2

`HTTP1.0`: 一个请求就是一个TCP连接，请求结束则连接断开。

`HTTP1.1`: 引入了缓存校验，如`If-Match`,`If-None-Match`;从`1.1`开始默认开启持久连接，即一个TCP连接可以支持多个请求和响应，减少了频繁创建和销毁TCP连接的性能问题。

`HTTP2.0`: 引入和帧和流的概念，多个帧组成一个流，流代表一个请求。

- `2.0`由于有帧的概念，所以采用二进制格式进行传输

- 在`1.1`的持久连接基础上，`2.0`支持并发请求和响应，因此帧中有序列号，可以在请求或者响应完成后进行重排来还原次序，且并发请求是在一个TCP连接中，这就是多路复用。

- `2.0`对头部信息进行了压缩，减少了请求体积

### 6. Https加密原理

1. 服务端生成一套密钥，A为公钥，A'为私钥（非对称）

2. 网站请求服务器后得到公钥A

3. 网站随机生成一个密钥B(对称)，并利用A对B进行加密生成B'，而后发给服务端

4. 服务端收到B'，用私钥A'对其进行解密得到B

5. 至此，网站和服务端都有了B密钥，以后通信就用它进行加密和解密

Q&A:

- 为什么要用要用对称+非对称这么麻烦的进行密钥B的传输

因为直接传输B会有安全隐患

- 为什么最后大家使用对称加密来传输报文

相较于非对称而言，对称加密效率更高（更快），但是不够安全（需要两端都持有相同的密钥）

- 什么是数字证书

网站得到了B就敢用么？其实还是有隐患，网站得确保B真的是用来和该网站通信的。为了使网站授信，CA机构会为该网站生成证书，证书包括了网站域名，密钥B等信息，所以网站还需要请所对应的数字证书

- 数字证书是否可信

为了使其可信，所以会对证书进行数字签名。网站收到证书后需要校验签名是否一致，否则就是被篡改过

### 7. 如何使用https://localhost

- 1.生成私钥匙

```
openssl genrsa -des3 -out rootCA.key 2048

```
phrase: 2090

- 2.生成根证书(过期时间1024天)

```
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem
```
```
Country Name (2 letter code) []:CN
State or Province Name (full name) []:State
Locality Name (eg, city) []:Xian
Organization Name (eg, company) []:Org
Organizational Unit Name (eg, section) []:TW
Common Name (eg, fully qualified host name) []:localhost
Email Address []:fake@qq.com
```

- 3.信任根证书

在`KeyChain`中导入`rootCA.pem`，这之后，根证书就会被应用到`localhost`上。

- 4.创建必要的配置文件

OpenSSL配置文件`server.csr.cnf`：

```
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=CN
ST=State
L=Xian
O=Org
OU=TW
emailAddress=fake@qq.com
CN=localhost
```

创建`v3.ext`: 

```
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=@alt_names

[alt_names]
DNS.1=localhost
```

- 5.生成新的private key `server.key`

```
openssl req -new -sha256 -nodes -out server.csr -newkey rsa:2048 -keyout server.key -config server.csr.cnf
```

- 6.生成域证书
```
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 825 -sha256 -extfile v3.ext
```

- 7.利用wepack devServer测试

`webpack.config.js`
```
{
  devServer: {
    host: "localhost.com",
    port: 443,
    allowedHosts: ["localhost.com"],
    https: {
      key: fs.readFileSync(path.resolve("dist/server.key")),
      cert: fs.readFileSync(path.resolve("dist/server.crt")),
    }
  }
}
```

[参考1](https://www.freecodecamp.org/news/how-to-get-https-working-on-your-local-development-environment-in-5-minutes-7af615770eec/)

[参考2](https://lisongfeng.cn/2019/01/16/qucik-set-up-htts-development-environment.html)
### 8. 解决本地前端登陆cookie无效的解决办法

`背景`：

最早期Chrome并不管控第三方`cookie`的`SameSite`，即服务器返回什么配置的`cookie`浏览器就照用，最重要是比如若`SameSite`没有设置则视为`None`。后来Chrome改变了这一策略，最明显的差别就是如果`cookie`没有设置`SameSite`，那么默认就是`Lax`，这样一来就只接受第三方的`Get`请求（或者说外部链接）。幸运的是我们还是可以通过`://flags`来配置浏览器对待`cookie`的行为，以此还原完全支持第三方`cookie`的状态。但是自从Chrome`90`版本以后，`://flags`里不再支持`SameSite`的篡改了，更甚之如果设为`SameSite=None`, 浏览器强制要求必须同时设置了`Secure`, 否者视为无效的`cookie`。（[参考](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite)）

因此，如果常常调试本地前端项目，如果需要和线上的后端进行对接，尤其是登陆需求时，往往`cookie`可能很难正常返回。

`解决办法`：

- 1.下载以前90版本以前的Chrome

没啥可以说的，很无奈的。

- 2.依然使用最新版本，但是使用命令行修改默认配置

例如`Mac OS`:
```
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --disable-features=SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure
```
但是这种玩法必须保证没有任何Chrom实例在运行才能启动，直接真的把你的Chrome当成调试工具了。

- 3.搭建本地Https

如果服务器返回了`Secure=true`的`cookie`，那这种情况搭建本地`https`也是一种办法。

- 4.搭建本地域名

如果服务端显示的设置了比较严格的`Domain`且没有设置`SameSite=None`, 比如`Domain=hello.china.com.cn`，那这个`cookie`就只能被域名为`hello.china.com.cn`或者`*.hello.china.com.cn`访问。因此`localhost`或者`127.0.0.1`这样的`host`自然接受不到`cookie`。

可以在`/etc/hosts`建立简单的本地映射:

```
127.0.0.1 localhost.hell.china.com.cn
```
这样启动本地前端`http://localhost.hell.china.com.cn:9090`就可以接到后端发来的`cookie`了。

- 5.后端根据条件配置cookie

比如发现`origin`是本地调试(localhost)，则可以设为`SameSite=None;Secure=false`。

但是目前不确认浏览器是否因为安全级别过低而不认这个`cookie`？（需要验证不同版本的Chrome）。总之意思就是后端可以条件式为不同环境和需求建立`cookie`配置。