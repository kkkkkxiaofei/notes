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