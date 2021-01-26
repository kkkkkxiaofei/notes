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

### 4. Authorization
- OpenID Connect & OAuth 2.0

`OpenID Connect & OAuth 2.0`的常见API:

| APIs                                    | Description                                    |
|-----------------------------------------|------------------------------------------------|
| /authorize                              | 和资源持有者进行交互并获取授权                 |
| /token                                  | 根据不同的授权方式获取id/access/refresh token  |
| /introspect                             | 返回token信息                                  |
| /revoke                                 | 废除access/refresh token                       |
| /logout                                 | 清除和当前id token的关系                       |
| /keys                                   | 返回签名时的公钥                               |
| /userinfo                               | 返回授权用户的claims                           |
| /.well-known/oauth-authorization-server | 返回授权服务器（OAuth 2.0）的metadata信息      |
| /.well-known/openid-configuration       | 返回授权服务器（OpenID Connect）的metadata信息 |

> ps: `OpenID Connect`是扩展于`OAuth 2.0`，在此基础上提供了`access token`

- Token

`id token`: 代表用户身份
`access token`: 访问资源，也可携带信息(需要资源服务器验证)
`refresh token`: 用来更新id/access token

当access token获取后，不必再次走一遍授权流程去拿token，取而代之的是用refresh token（前提是这个token合法且有效）去更新access token，就会方便很多：

```
http --form POST https://${yourOktaDomain}/oauth2/default/v1/token 
  accept:application/json
  authorization:'Basic MG9hYmg3M...'
  cache-control:no-cache
  content-type:application/x-www-form-urlencoded
  grant_type=refresh_token
  redirect_uri=http://localhost:8080
  scope=offline_access%20openid
  refresh_token=MIOf-U1zQbyfa3MUfJHhvnUqIut9ClH0xjlDXGJAyqo

```
请求成功后可以获得新的id/access token:

```
{
    "access_token": "eyJhbGciOiJ[...]K1Sun9bA",
    "token_type": "Bearer",
    "expires_in": 3600,
    "scope": "offline_access%20openid",
    "refresh_token": "MIOf-U1zQbyfa3MUfJHhvnUqIut9ClH0xjlDXGJAyqo",
    "id_token": "eyJraWQiO[...]hMEJQX6WRQ"
}

```

> ps: 目前refresh token真有在授权码和用户密码方式下才可以。

- Oauth2.0

1.授权码模式：

获取授权码需要授权服务器提供`/authorize`的url，例如以下get请求用于获取code：

```
https://${authServerDomain}/oauth2/default/v1/authorize?client_id=0oabucvy
c38HLL1ef0h7&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Flocal
host%3A8080&state=state-296bc9a0-a2a2-4a57-be1a-d0e2fd9bb601'
```

`client_id`: 在授权服务器内注册的application，会分配一个client_id。

`response_type`: 值为code代表返回的是授权码。

`scope`: 该授权的权限范围，openid表明会返回idToken表明用户身份。常见的scope还有email, profile等等。

`redirect_uri`: 授权成功后应该返回到的地址，会在该地址上携带code。

`state`: 产生于授权服务器，用于方式csrf攻击。

当用户session没有过期或者授权成功后，将会到达redirect_uri上：

```
http://localhost:8080/?code=P5I7mdxxdv13_JfXrCSq&state=state-296bc9a0-a2a2-4a57
-be1a-d0e2fd9bb601
```

授权码只会保留60秒的时间，下一步就是用授权码去获取token。

2.交换token

需要授权服务器提供`/token`的url，例如以下post请求：

```
  curl --request POST \
  --url https://${yourOktaDomain}/oauth2/default/v1/token \
  --header 'accept: application/json' \
  --header 'authorization: Basic MG9hY...' \
  --header 'content-type: application/x-www-form-urlencoded' \
  --data 'grant_type=authorization_code&redirect_uri=http%3A%2F%2Flocalhost%3A8080&code=P59yPm1_X1gxtdEOEZjn'
```

`grant_type`: 这里指明授权方式是授权码模式

`redirect_uri`: 这里的重定向一定得是上一步使用的值

`code`: 上一步获取到的授权码

`authorization`：在注册application时一般需要指定应用的交互时的验证方式，如果不设置，默认时`client_secret_basic`方式，格式为`Authorization: Basic ${Base64(<client_id>:<client_secret>)}`，还有其他的方式，如jwt方式。

若请求成功，则会返回idToken和accessToken:

```
{
    "access_token": "eyJhbG[...]9pDQ",
    "token_type": "Bearer",
    "expires_in": 3600,
    "scope": "openid",
    "id_token": "eyJhbG[...]RTM0A"
}
```

3.验证accessToken

有了accessToken，理论上就可以为所欲为了，所以在使用它之前，必须得验证它是否合法。

验证其实大体分两个步骤，但都发生在resource server（你的服务器）：
 - 1.auth验证
 
 a）由于token是被RS256/HS256加密过，所以需要首先获取解密的public key。这一步是遵循标准的，只要能够找到issuer，就知道授权服务器，授权服务器需要提供对应的api去获取公钥。

 b)由于token被base64编码过，需要解析access token

 c)验证签名。在a步时已经获取了公钥，可以重新计算一次签名，和当前signature进行比较，算法为：

```
 HMACSHA256(
   base64encode(header).
   base64encode(payload).
   publicKeyEncode(signature)
 )
```

 d)验证claims信息

 - 2.业务验证

以上为auth相关验证，这一步是必须的，这一步之后就是真正的业务部分，看对应的用户是否有足够的业务权限访问该资源（取决于你的业务）。

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

