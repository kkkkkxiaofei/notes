前端自身由于缺少模块化管理，因此当我们进行模块化开发后，必须要将代码进行整合（bundle）。打包工具无非是将js, css以及其他资源文件进行合并。

以webpack的startkit为例子：

```

module.exports = {
  entry: path.resolve(__dirname, 'index.js'),
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'main.js'
  }
};

```

配置很简单，它只需要entry和output（甚至可以有默认的）即可。

那么它是怎么做的呢？

我们来分析一个vanilla js的demo。

`main.js`

```
import app from './application.js';
import config from './config/index.js';

const { appName, version } = config;
app.start(appName, version);
```


`main.js`有以下特点：


- 1.有依赖
`./applicantion.js`和`./config/index.js`，

- 2.使用了ES module引入依赖
 `import ...`

- 3.依赖必然将自己进行了导出
 `./applicantion.js`必然有`export default`; 依赖的依赖也许还会有`export const xxx`;

- 4.main文件自身并没有导出

基于此，可以提出以下问题：

- 1.怎么处理ES module导出/导出的语法，这么貌似Node.js和Browser都不认识呀？

- 2.假设1已经解决，怎么将依赖处理成一个模块，且支持自身导出和外部引用？

- 3.如何分析依赖，以及依赖的依赖，以及。。。。







- (done)继续测试es module的打包，包括node_module路径

- 解决CommonJS无法从AST中读取依赖的问题,包括node_module路径
  - 排除node内置模块(http, path, fs...)
  - node_modules里又引入了外部的node_modules,需要切换NODE_MODULE_PATH

- 解决umd打包，兼容全局注入,包括node_module路径

- 导入json文件

- 动态导入（jsonp）

- 缓存

- 支持css

- 支持scss

- jsx(babel插件)