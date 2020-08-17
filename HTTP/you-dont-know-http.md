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
