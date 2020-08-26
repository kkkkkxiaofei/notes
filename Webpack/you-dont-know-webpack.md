### 1.commonjs/es module/umd

`commonjs`:目前主流实现为Node.js，默认情况下node环境是无法执行es module的，但是也可以在node运行时加入额外参数来实现。

node中主要是`module`和`exports`两个参数，其中`exports`和`module.exports`为同一引用。

> ps: commonjs1中只有exports;而module.exports是commonjs2才引进的，默认commonjs指的是commonjs2

`es module`：ES6引入的模块管理，默认情况下浏览器和node中解析，在浏览器中可以开启`type = module`来实现。但目前主流的做法还是在babel下将es module转为commonjs，如下

es6 import/export
```
import request from './api';

export default request;

export const get = request.get;
```

after babel 

```
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.get = exports.default = void 0;

var _api = _interopRequireDefault(require("./api"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _default = _api.default;
exports.default = _default;
var get = _api.default.get;
exports.get = get;
```

可以看到import/export会完全被转化为commonjs语法。

> 那转化为怎么区分原始module类型呢？

关键在于exports对象上，如果是es module转化来的，则__esModule为true，这一属性将会在module导入的时候起到决定性作用，

```
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

```
因此如果commonjs想导入es module的话，往往会有如下写法:

```
const traverse = require('@babel/traverse').default;
```

`umd`: 由于运行环境不一样会导致模块的使用不一样，所以umd将所有行为归一化:

```
(function(root, factory) {
  //commonjs
  if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
  //amd
	else if(typeof define === 'function' && define.amd)
		define([], factory);
  //类commonjs环境
	else if(typeof exports === 'object')
		exports["micro-app"] = factory();
  //browser
	else
		root["micro-app"] = factory();
})(window, factory)
```

### 2. output

最常用的output属性是`filename`，这个不多说，以下几个也很重要：

- `publicPath`

异步模块加载路径。进行code split后，默认拆分出来的chunk是在output的路径下的，那么自然路径就是`/`，若为分布式打包且资源在远端（微前端），那这个值将非常有用。

- `crossOriginLoading`
 
这个我是第一次听说。默认webpack在进行异步加载的时候使用的是JSONP，这里牵扯到跨域（虽然觉得能跨，因为用的script），但是一旦跨域，就需要考虑第三方Cookie的问题。默认不带，可以设置为`use-credentials`。

- `library/libraryTarget`

这两个必须要一起解释。

`library`是wepack到处模块的名称。

```
output.library = 'lib';

var lib = wepack_bundle;
```

`libraryTarget`是以何种方式打包。

默认是`var`

```
var libName = wepack_factory();
```

若为`umd`，导出时的情况分别如下：

```
//1. root（global, window, this) 注入

root['libName'] = wepack_factory();

//2. commonjs2

module.exports = wepack_factory();

//3. commonjs1

exports['libName'] = wepack_factory();

```

### 3. Module

`java里一切皆class;webpack里一切皆module`。

简单来讲任何一个文件，在webpack里都看作为一个module，问题就是如何解析这个module，那就涉及到了`loader`。先看一个最简单的module配置：

```
module: {
	rules: [
		//rule1
		{
			test: /\.js$/,
			use: ['babel-loader'],
			include: path.resolve(__dirname, 'src')
		},
		//rule2
		{
			test: /\.scss$/,
			use: ['sass-loader'],
			exclude: path.resolve(__dirname, 'node_modules')
		}
	]
}
```

在解析module时，首先需要分析文件类型，从而推断需要什么样的`loader`(核心是loader)，`loader`会将对应的代码`'翻译'`为该语言最原生的版本。

`exclude/include`很好理解，但是要强调的是这个最好还是明确写出来，不然webpack会在解析当前文件时，递归寻找依赖，这个效率可想而知，提早规划解析路径必然会加速打包进度。

`noParse`: 对于一些没有模块化的依赖，但是却和你的代码库放在了一起的case来说，它是不需要解析的，可以跳过，如`jQuery`。

`parser`: 如默认`@babel/preset-env`会将es中的`import/export`转换为`require/module.exports`，利用该属性就可以控制代码细节的解析。



