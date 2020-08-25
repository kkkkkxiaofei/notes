### 1. 缓存

`Cache-Control`有以下用法：

- no-store
  没有缓存。
- no-cache
  有缓存，但是需要重新验证，若验证发现缓存依然有效则返回304。
- public/private
  public表明缓存可以被中间环节缓存（如CDN)；private则是浏览器级别，外部无法缓存。
- max-age
  表明缓存过期时间，优先级最高。

缓存验证：

- Expires
  若max-age没设，则会查看该值，优先级次之。
- Last-Modified
  若max-age和Expires都没有，会查看该值，优先级较低，常常与`If-Modified-Since`一起使用。
- ETags
  如果请求响应头里有这个属性（值一般是资源hash），则下次请求时，客户端可以带上`If-Non-Match`。
- If-Non-Match
  该属性会和`Etags`一起使用，若服务端没有能够找到任何资源与Etags的值相等，则返回200。

### 2.xss vs csrf

xss一般主要是html类型的的脚本被上传至服务器，而后其他用户访问到相关资源后会执行该脚本，从而产生数据安全隐患。
措施：检测脚本

csrf一般指A网站里有B网站的广告（第三方），正常情况下，A站点的操作对应的是A'的服务器，而对广告这里，如果后端设置了允许第三方cookie的话，那么在A站点浏览该广告后，会把B站点的cookie带到本地（第三方cookie），但是之后所有请求都应该保持cookie同源策略。此时如果这个广告里有一个攻击脚本，该脚本会模拟用户去访问A'，那这样的话，就会把A站点之前的cookie带过去，就会让A'无以为这是A，从而为此敞开大门，为所欲为。

`措施`:

1.Samesite属性，Strict（只第一方带cookie），Lax(第三方的get会带cookie），None（都带），所以大部分情况将samesite设置为Lax并且请求改为post即可

2.增加身份认证，其实B站点的攻击脚本并不能拿到A请求里的信息，只依赖于cookie，如果可以增加更多的信息来认证client的话也是可以的，比如origin, csrf-token

3.本质上1可以解决很多，但是如果真有攻击脚本的话，应该避免xss，这样也就无法注入其他类似iframe的东西了

> ps: 只有后端设置`Access-Control-Allow-Credentials: true` 且前端请求时header里`credentials: include`才可以把cookie发送到服务器。

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


- Oauth2.0

1.授权码模式：

获取授权码需要授权服务器提供`/authorize`的url，例如以下get请求用于获取code：

> https://${authServerDomain}/oauth2/default/v1/authorize?client_id=0oabucvy
c38HLL1ef0h7&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Flocal
host%3A8080&state=state-296bc9a0-a2a2-4a57-be1a-d0e2fd9bb601'

`client_id`: 在授权服务器内注册的application，会分配一个client_id。

`response_type`: 值为code代表返回的是授权码。

`scope`: 该授权的权限范围，openid表明会返回idToken表明用户身份。常见的scope还有email, profile等等。

`redirect_uri`: 授权成功后应该返回到的地址，会在该地址上携带code。

`state`: 产生于授权服务器，用于方式csrf攻击。

当用户session没有过期或者授权成功后，将会到达redirect_uri上：

> http://localhost:8080/?code=P5I7mdxxdv13_JfXrCSq&state=state-296bc9a0-a2a2-4a57
-be1a-d0e2fd9bb601

授权码只会保留60秒的时间，下一步就是用授权码去获取token。

2.交换token

需要授权服务器提供`/token`的url，例如以下post请求：

> curl --request POST \
  --url https://${yourOktaDomain}/oauth2/default/v1/token \
  --header 'accept: application/json' \
  --header 'authorization: Basic MG9hY...' \
  --header 'content-type: application/x-www-form-urlencoded' \
  --data 'grant_type=authorization_code&redirect_uri=http%3A%2F%2Flocalhost%3A8080&code=P59yPm1_X1gxtdEOEZjn'

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