### OAuth 2.0

#### 1.Introduction

`OAuth 2.0`是一个规范标准，它可以安全地为应用程序提供资源访问权限，在了解它之前，有必要先理解下面的四个角色：

`Authentication Server`: 授权服务器用来颁发`access token`, 最常见的就是你们`Okta`（想想为啥你们公司的Okta主页里的app可以实现共享登陆吧）.

`Resource owner`: 应用的终端用户，他将通过他信任的授权服务器把权限授权给应用程序（`access token`)。

`Client`: 应用程序，它将`access token`发送给资源服务器来访问资源。

`Resource Sever`: 它接收`access token`后需要验证正确性和有效期，一般资源服务器指的就是你的`API server`。

通常`OAuth2.0`的具体流程有以下几个步骤：

- 1.应用程序向用户申请授权（唤起第三方登陆）

- 2.若用户同意授权，则应用程序会把授权信息发送到授权服务器

- 3.如果一切正确，授权服务器会向应用程序返回`access token`，有时也会携带`refresh token`或`ID token`

- 4.应用程序用`access token`来访问资源。


### 1. Authorization  
- OpenID Connect vs Oauth2.0

`OAuth 2.0`: 鉴权框架，最主要用于保护资源服务器，典型的Bearer方式就是其中一种方式。

`OpenID Connect`: 基于`OAuth 2.0`建立，使用JWT方式发布ID token,常常用于解决跨平台登陆问题。比如常见的code换token的方式就是来自此协议。

`OpenID Connect`的常见API:

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

- 以Oauth2.0的授权码模式为例子，其流程为

`1.获取code：`

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

`2.交换token`

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

`3.验证AccessToken`

有了accessToken，理论上就可以为所欲为了，所以在使用它之前，必须得验证它是否合法。

因为它的类型是`Bearer`，使用时需要将其注入到请求的header里:

```
Authorization: Bearer ${access_token}
```

关于如何解析Bearer的token，这一点规范也没说，因为这个token并不是JWT，一般是由授权服务器自己加密（或编码）生成，因此完全取决于如何编码，甚至还取决于资源服务器本身如何再次鉴权。

***补充***

`AccessToken`具有直接访问资源的能力，因此不宜给它过长的过期时间。但是如果过期时间过短的话又得让用户频繁的授权（在走一遍Auth流程），因此出现了`Reresh Token`。`Reresh Token`并不是说是刷新已有的`Access Token`，而是说当现在的`Access Token`失效后，为了避免重新授权，可以用`Reresh Token`请求新的`Access Token`。因此往往`Reresh Token`的过期时间会比较长。

`4.验证JWT（如ID token)`

验证其实大体分两个步骤，但都发生在resource server（你的服务器）：
 - 1.auth验证
 
 a）由于token是被RS256/HS256加密过，所以需要首先获取解密的public key。这一步是遵循标准的，只要能够找到issuer，就知道授权服务器，授权服务器需要提供对应的api去获取公钥。

 b)由于token被base64编码过，需要解析

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

[参考](https://developer.okta.com/docs/concepts/oauth-openid/)