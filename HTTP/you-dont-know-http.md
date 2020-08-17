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