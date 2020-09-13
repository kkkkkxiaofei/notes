### 写在前面

> 长期以来，前端的模块化管理都不很成熟（`webpack`出现之前），为此，早期（ES5时代）为了实现依赖管理，甚至会利用`window`等全局对象进行注册模块，而如今有了`webpack`,`rollup`等优秀的打包工具，让我们开发起来事半功倍，因此笔者觉得很有必要去学习下这种划时代的工具的实现思路。因此，本篇将讲述如何一步步实现一个初级的前端打包工具，仅供学习和分享，希望读完后可以让大家对打包工具不只是停留在会用（光看文档）的基础上，而是能够有更多的思考（比如如何优化和按需定制）。

`如果你准备好了，请先倒一杯咖啡，因为此文略长（且最好亲自运行）。`[源码请戳这里](https://github.com/kkkkkxiaofei/dummy-playground/tree/master/pack)

所谓打包工具，无非是将`js`, `css`以及其他资源文件进行合并（本篇只讨论`js`，其他类型的文件你读完后必然有自己的思路)。

以`webpack`的start-kit为例子：

```

module.exports = {
  entry: path.resolve(__dirname, 'index.js'),
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'main.js'
  }
};

```

配置很简单，它只需要`entry`和`output`（甚至可以有默认的）即可。

那么它是怎么做的呢？

我们来分析一个`vanilla js`的`demo`。

`main.js`

```
import app from './application.js';
import config from './config/index.js';

const { appName, version } = config;
app.start(appName, version);
```

`main.js`有以下特点：

- 1.有依赖
`./application.js`和`./config/index.js`，

- 2.使用了ESM引入依赖
 `import ...`

- 3.依赖也有自己的导出
 `./application.js`必然有`export default`; 依赖的依赖也许还会有`export const xxx`;

- 4.main文件自身并没有导出

基于此，可以提出以下问题：

- 1.怎么处理ESM导入/导出的语法，貌似Node.js和Browser都不认识`import`关键字呀？

- 2.假设1已经解决，怎么将依赖处理成一个模块，且支持自身导出和外部引用？

- 3.如何分析依赖，以及依赖的依赖，以及。。。。

### 1 模块导入导出

我们先以ESM作为讨论。

#### 1.1 ESM in browser

你也许没有关注，目前ESM在`部分`浏览器里是可以直接使用的：

`index.html`

```
<script type="module">
  import showVersion from './index.js';
  showVersion();
</script>

```

`index.js`

```
import { version } from './config.js';

export default () => {
	console.log(`====== app version: ${version} ======`);
}

```

是不是很方便？但其中问题也不少：

- 1.文件路径

这里我所有的文件都必须写后缀(否则报错），且路径必须是以服务器的host为相对路径，这就极大的限制了模块的路径（alias，node_modules等）

- 2.http请求

如果你尝试上面的代码，会发现这种方式是直接去请求的文件，且请求顺序是有顺的。

这首先会需要大量http请求，且隐式的需要让callback也有序，不然可能会出现f1在f2之前请求的，但却晚回来，f2却依赖了f1里的方法，那么就会跪。

- 3.不支持CJS

如果我写了node环境的代码，是没办法用这种方式加载的，更别提其他模块机制了。

#### 1.2 ESM in Node.js

默认情况下是无法在`Node.js`环境下使用`ESM`的，但是自从`13.9`版本以上，可以开启flag `--experimental-modules`，并且在`package.json`里:

```
{
  "type": "module"
}
```

#### 1.3 从ESM到CJS

不难看出，单就`ESM`在浏览器和`Node.js`的切换就会有问题，为了消除差异，目前主流的做法是不在浏览器里使用`ESM`，取而代之的是将ESM先转化为`CJS`。比如上面的`main.js`，利用`Babel`转换后如下：

```
"use strict";

//1
var _application = _interopRequireDefault(require("./application.js"));

//2
var _index = _interopRequireDefault(require("./config/index.js"));

//3
function _interopRequireDefault(obj) { 
  return obj && obj.__esModule ? obj : { default: obj }; 
}

//4
var appName = _index.default.appName,
    version = _index.default.version;
//5
_application.default.start(appName, version);
```

首先1,2已经把`import`改为了`require`。

其次，3处对`require`的实现做了一次签名包装：若`module`为`ESM`则具有内部属性`_esModule`，此时默认导出的模块就是自身；否则，需要封装为`{ default: obj }`。

最后，由于`./application.js`和`./config/index.js`均为默认导出，所以使用时需要取出`default`，完全是按照3的标准来解析的。

看到这里，似乎问题已经解决了一大半了（代码已经归一化了），但还有一个问题没有解决：

这个require该怎么实现？

> 这里必须澄清，require并不一定就在说Node.js的require, Node.js只是commonjs标准的一种实现。


### 2 模块导出的通用解决方案

和上面一样，我们用`Babel`测试以下`ESM`的导出转换：

`ESM:`

```
export default A;

export const name = '';
```

`after babel:`

```
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.name = exports.default = void 0;
var _default = A;
exports.default = _default;
var name = '';
exports.name = name;
```

很简单，默认导出`export default`转化为`exports.default`；变量导出`export const xxx`转化为`exports.xxx`。

那万一需要打包的代码使用了`CJS`呢？

`CJS:`

```
module.exports = A;

module.exports = {
  name: ''
}
```

`after babel:`

```
module.exports = A;
module.exports = {
  name: ''
};
```

什么？居然一样。

没错，这就是目前的标准：因为浏览器端和Node.js端对ESM的支持都还不成熟，所以所谓的转译就是ES moudle转commonjs的过程。

这样依赖，我们就只用处理`commonjs1`和`commonjs2`的情况就好了，即代码里模块操作只有`require`,`exports.default`,`exports.xxx`, `module.exports`。所以任意文件的代码都可以按照如下来封装：

`source.js`

```
function(require, module, exports) {
  // source code
}
```

有`require`是因为有可能还需要引用其他模块，这个我下面会讲到。

`exports`等价于`module.exports`，因此本质上是利用`module`对象去注入原始代码，最终取出导出的模块。


### 3 导入路径分析

当我们导入一个模块时，一般有两类写法：

```
//1
import _ from 'lodash'; 

//2
import util from './util';

```
其中1的寻找规则默认会去项目根目录下的`node_modules`里寻找；

而2的寻找规则就稍微复杂一点：

当`./util`没有`package.json`文件时会去尝试寻找`./util`;否则会查看`package.json`里的`main`属性作为入口。

以上规则的前提没有用任何的打包工具，比如用`webpack`打包时路径的分析会比这个要复杂的多，还牵扯到`main`,`module`,`browser`等的优先级。所以基于此，我们这里把规则定的简单点：

- 1.默认外部依赖的路径为`${projectRoot}/node_modules`

- 2.`./util` 等价于 `./util.js` 或 `./util/index.js`

- 3.任何以字符开头的路径均代表外部依赖（`util`等价于`${projectRoot}/node_modules/util/index.js`)

于是首先我们需要把相对路径转化为绝对路径：

```
function buildPath(relativePath, dirname, config) {
  const { entry } = config;
  const NODE_MOUDLES_PATH = `${path.dirname(entry)}/node_modules`;

  if (relativePath === entry) {
    return relativePath;
  }

  let absPath = relativePath;
  if (/^\./.test(relativePath)) {
    absPath = path.join(dirname, relativePath);
    
  } else {
    absPath = path.join(NODE_MOUDLES_PATH, relativePath);
  }

  return revisePath(absPath);
}

```

而后，需要修复文件的最终定位（自身还是内部的index.js)

```
function revisePath(absPath) {
  const ext = path.extname(absPath);
  if (ext) {
    if (EXTENSIONS.indexOf(ext) === -1) {
      throw new Error(`Only support bundler for (${EXTENSIONS}) file, current ext is ${ext}`)
    }
    if (fs.existsSync(absPath)) {
      return absPath;
    }  
  }

  if (ext !== '.js') {
    if (fs.existsSync(`${absPath}.js`)) {
      return `${absPath}.js`;
    }

    if (fs.existsSync(`${absPath}/index.js`)) {
      return `${absPath}/index.js`;
    }
    throw new Error(`Can not revise the path ${absPath}`)
  }
  //here relative path is absolute path
  return absPath;
}

```

有了上面的概念，我们就可以进入我们的主题了。

### 4 Babel

上面分析了这么多关于模块导入导出的思路，当下摆在我们面前的第一步就是：如何在语法上识别一个文件里有依赖，以及依赖的路径是什么呢？

这里不得不提一下Babel转译js的步骤。

#### 4.1 parse

`parse`阶段会将源代码解析为[抽象语法树](https://astexplorer.net)(`AST`)，`AST`通过词法分析生成对应类型的节点，详细的描述了每一行代码的具体`特征`，例如：

`source code :` 

```
//1
import app from './application.js';

//2
import config from './config/index.js';

//3
const { appName, version } = config;

//4
app.start(appName, version);

```

`after parse:`

![](/images/bundler/4-1.png)


可以看到1,2为导入声明，3为变量声明，4为表达式。

以1为例，1为`ImportDeclaration`, 表明是`ESM`的`import`（require语法不会是这种类型的Node），且source里的value为依赖模块的相对路径。但是这个树的可能会很深，导致我们取具体信息的操作会很复杂（a?.b?.c?.e?....），为此我们可以进入Babel转译的第二个阶段。

#### 4.2 traverse

`traverse`可以方便的操作AST，比如我们可以这样遍历`ImportDeclaration`:

```
traverse(ast, {
    ImportDeclaration({
      node
    }) {
      const relativePath = node.source.value;
      //record the dependency
    }
});

```

而对于`Commonjs`的`require`，在AST中存在于`CallExpression`的Node上(笔者下面的寻找方式肯定不是最佳的)：

```

traverse(ast, {
  CallExpression({
    node
  }) {
    const {
      callee: {
        name
      },
      arguments
    } = node;

    if (name === 'require') {
      const relativePath = arguments[0].value;
      //record the dependency
    }
  }
});

```

在traverse的阶段我们还可以自定义一些语法然后去分析，比如对于动态导入模块来说，一般我们使用异步`import...then`:

```
import('./util').then(...)
```

我们可以再定义自己喜欢的语法糖：

```
dynamicImport('./api').then(
  module => console.log('======successfully load dynamic moudle=====');
);

```

在然后去像上面一样遍历该语法存在的节点：

```

traverse(ast, {
  CallExpression({
    node
  }) {
    const {
      callee: {
        name
      },
      arguments
    } = node;

    if (name === 'dynamicImport') {
      const revisedPath = buildPath(relativePath, path.dirname(filename), config);
      //record the dependency
    }
  }
});

```
类似的，我们甚至可以模拟`ES7`的`Decorator`(@xxx)，这就不赘述了。


#### 4.3 transform

生成了语法树，遍历/修改了语法树，最终`Babel`的目标是还是js代码。`transform`可以将我们修改后的`AST`输出最终的代码。

在这一过程中一般只需要配置以下`Babel`的`presets`即可，比如我们常用的`preset-env`就是ES6->ES5，如果什么都不设置，那`Babel`就什么也不干。

`presets`的角色比较上层，或者说它是一种宏观的规则，对于一些非常具体的代码转换逻辑，就需要`plugin`了。比如我们上面使用了`dynamicImport`语法，在traverse阶段我们也遍历到了该信息，但是这毕竟不是js语法，我们是需要写一个小插件来进行语法转换(`Babel`插件的写法这里就不赘述了)：

`plugin/dynamicImport.js`

```
module.exports = {
  visitor: {
    Identifier(path) {
      if (path.node.name === 'dynamicImport') {
        path.node.name = 'require';
      }
    }
  }
};
```

然后利用自己的插件以及配置好的`preset`，最终输出转译后的代码。

```
const { code } = babel.transformFromAstSync(
  ast, null, {
    plugins: [
      dynamicImportPlugin
    ],
    presets,
  }
);
```

至此，Babel的转译js代码的流程介绍完了。

参考：

const parser = require('@babel/parser');

const traverse = require('@babel/traverse').default;

const babel = require('@babel/core');


### 5 实现

#### 5.1 生成资源文件(Asset)

我们建立一个很简单`vanilla`项目，结构如下：

```
vanilla
│   main.js
│   constant.js    
│   application.js    
└───utils
│   └───log.js
└───config
    └───index.js
```

`main.js`

```
import app from './application.js';
import config from './config/index.js';

const { appName, version } = config;
app.start(appName, version);
```

我们先开始分析依赖。对于main.js，它是这个项目的入口，这个必须由调用者提供，我们期望从`main.js`分析出类似如下信息：

```
{
  id: String,
  code: String,
  filename: String,
  dependencies: Array:
}
```

我们可以把这个结构称作一个资源文件(`Asset`)，它由模块标识符（`id`），代码（`code`），文件名（`filename`）和依赖（`dependencies`）组成，它的依赖示例如下：

```
dependencies = ['./application.js', './config/index.js']
```

同理，`dependencies`里的元素本身也是一个`Asset`。

生成一个`asset`的逻辑如下：

- 1.生成资源id

简单点，我们这里使用自增id（第一个资源id为0）。

- 2.读取源代码

直接同步读取文件（暂时不考虑内存和效率）。

- 3.生成ast

[参考上面parse阶段](#41-parse)。

- 4.遍历ast，收集依赖

收集依赖只是将依赖添加到队列中([遍历ast不再赘述](#42-traverse))：

```
const dependencies = [];

traverse(ast, {
  ImportDeclaration({
    node
  }) {
    const relativePath = node.source.value;
    dependencies.push(relativePath);
  }
});
```

> 注意，依赖资源的路径是相对路径，后期使用时还需要修正。

- 5.转换为源代码

[参考上面transform阶段](#43-transform)

最终代码大致如下：

```
function createAsset(filename) {
    id++;
    const file = fs.readFileSync(filename, 'utf8');

    const dependencies = [];

    const ast = parser.parse(file, {
      sourceType: 'module'
    });

    traverse(ast, {
      ImportDeclaration({
        node
      }) {
        const relativePath = node.source.value;
        dependencies.push(relativePath);
      },
      CallExpression({
        node
      }) {
        const {
          callee: {
            name
          },
          arguments
        } = node;

        if (name === 'require') {
          const relativePath = arguments[0].value;

          if (/^\./.test(relativePath)) {
            dependencies.push(relativePath);
          }

        }
      }
    });
    const {
      code
    } = babel.transformFromAstSync(
      ast,
      null, {
        presets,
      }
    );

    return {
      id,
      filename,
      dependencies,
      code
    }
  };

```

#### 5.2 生成资源树(Asset[])

再来回顾一下我们的项目结构，这是一个典型的以入口文件（`main.js`）为根资源节点的树，我们采用DFS进行遍历：

```
function createAssets(filename) {
    const stack = [], assets = {};
    const push = stack.push; 
    stack.push = function(asset) {
      push.call(stack, asset);
      assets[asset.filename] = asset;
    }
    stack.push(createAsset(filename));
    
    //DFS
    while(stack.length > 0) {
      const asset = stack.pop();
      asset.mapping = {};//1
      asset.dependencies.forEach(relativePath => {
        const revisedPath = buildPath(relativePath, path.dirname(asset.filename), config);
        console.log(`Start extracting: ${revisedPath}`);
        const depAsset = createAsset(revisedPath);
        asset.mapping[relativePath] = depAsset.id;
        stack.push(depAsset);
      });
    }

    return assets;
  };

```

上面的实现很简单，但有一点需要特别解释下，就是再1处我们给asset附加了一个`mapping`属性。

`mapping`记录的是当前资源下一层（处于树中同一深度）的依赖关系，它的key为相对路径，value为模块id。这样就可以利用路径去反查id。比如`main.js`的依赖里必然有`./application.js`，当我们建立完`main.js`这个资源后，mapping里大致有`{"./application.js": 1}`这样的信息。这非常有用，当后面我们需要把`main.js`这个资源进行打包时可以利用mapping取出所有依赖的模块。


#### 5.3 整合所有资源

- 1.实现通用导出

有了`asset`, `assets`我们已经完成了一大半工作了（似乎有点长了，哈哈），为了让`assets`聚合在一起，我们需要把资源`‘拼’`在一起，毕竟最后输出的是一个文件。

拼接资源:

```
const modules = Object.values(assets)
  .reduce((result, asset) => {
      const {
        id,
        code,
        mapping,
        filename: revisedPath
      } = asset;
      
      return result += `
      ${id} : [
        function(require, module, exports) {
          ${code}
        },
        ${JSON.stringify(mapping)}
      ],
    `
    }, '');

```

对于`main.js`，我们会整合为大致如下的结构：

```
  0: [
    function (require, module, exports) {
      // main.js here
      "use strict";

        var _application = _interopRequireDefault(require("./application.js"));

        var _index = _interopRequireDefault(require("./config/index.js"));

        function _interopRequireDefault(obj) {
          return obj && obj.__esModule ? obj : { default: obj };
        }

        var appName = _index["default"].appName,
          version = _index["default"].version;

        _application["default"].start(appName, version);
    },
    { "./application.js": 1, "./config/index.js": 2 },
  ],

  1: [
    function (require, module, exports) {
      // code resource here
    },
    { "./utils/log.js": 4 },
  ],

  2: [
    function (require, module, exports) {
      // code resource here
    },
    { "../constant.js": 3 },
  ],

  3: [
    function (require, module, exports) {
      // code resource here
    },
    {},
  ],

  4: [
    function (require, module, exports) {
      // code resource here
    },
    {},
  ],
})
```

还记得上面提到的[模块导出的通用解决方案](#2-模块导出的通用解决方案)吗？。

我们为所有的源代码封装了一个factory：

```
function (require, module, exports) {
  // code resource here
}
```

这里我特意没有换别名，还是用了大家熟悉的变量名（`require`，`module`，`exports`），区别在于这些都需要我们自己实现。

以`main.js`为例（`require`的实现我们稍后介绍），我们注入了`module`和`exports`对象，只要`main.js`的factory已执行，我们就可以拿到`main.js`的代码。当然了，尽管有一些文件并没有任何的导出操作，但factory也需要执行（毕竟要执行源代码），自然`module`和`exports`会显示没有使用。

- 2.实现通用导入

我们暂时把上一步拼接好的资源叫做`modules`，每一个`module`有自己的factory和`mapping`。`modules`算得上是初步的资源整合结果，我们还差一个`require`没有实现。继续回顾上面`main.js`的factory，当执行factory时，会遇到：

```
var _application = _interopRequireDefault(require("./application.js"));
```

其实到了这一步，`./application.js`这个资源早已经被建好了（特殊情况除外，如代码分离），只要我们有一个全局的scope（这就是moudles呀）查询即可。

比如`./application.js`对应的模块id`1`，而`1`号模块也有自己的factory，一旦执行，不就变成了通用导出的逻辑了，依次循环，很简单。

不过有一点，我们需要寻找一个起点，那肯定就是入口文件么，即`0`号模块，因此，有了以下实现：


```
(function(modules) {
    function load(id) {
      //2
      const [factory, mapping] = modules[id];
      //3
      function require(relativePath) {
        return load(mapping[relativePath]);
      }
      //4
      const module = {
        exports: {}
      }
      //5
      const result = factory(require, module, module.exports);
      if (module.exports && Object.getOwnPropertyNames(module.exports).length === 0) {
        return result;
      }
      //6
      return module.exports;
    }
    //1
    return function() {
      return load(0);
    }
  })({${modules}})
```

`1`: 从根模块开始。

`2`: 取出module里的factory和mapping。

`3`: 自定义require方法，递归执行factory，这里闭包了`2`里的mapping

`4`: 自定义导出对象，期待mutable操作。

`5`: 真正执行当前模块的factory。

`6`: 返回4步的对象。

考虑到打包的代码量，我们用一个很小的工程作为测试：

`main.js`

```
const isArray = require('./util');

const arr = [1,2,3];

console.log(`[1,2,3] is array: ${isArray(arr)}`);
```

`./util`

```
const isArray = arr => arr instanceof Array;

module.exports = isArray;
```

打包后：

```
(function (modules) {
  function load(id) {
    const [factory, mapping] = modules[id];
    function require(relativePath) {
      return load(mapping[relativePath]);
    }
    const module = {
      exports: {},
    };
    const result = factory(require, module, module.exports);
    if (
      module.exports &&
      Object.getOwnPropertyNames(module.exports).length === 0
    ) {
      return result;
    }
    return module.exports;
  }
  return function () {
    return load(0);
  };
})({
  0: [
    function (require, module, exports) {
      const isArray = require("./util");

      const arr = [1, 2, 3];
      console.log(`arr is array: ${isArray(arr)}`);
    },
    { "./util": 1 },
  ],

  1: [
    function (require, module, exports) {
      const isArray = (arr) => arr instanceof Array;

      module.exports = isArray;
    },
    {},
  ],
})();

```

在Node.js或浏览器中执行结果:

```
[1,2,3] is array: true
```

至此，我们已经可以打包一个小型的纯js项目了，尽管它还有非常多的问题（@_@)

### 6 优化

一个好的打包工具是一定需要考虑很多细节以及性能的，虽然笔者无法做到像`webpack`这样优秀，但是基于上面的实现，我们还是能提出一些优化的建议的。

- 1.缓存

我们在建立资源时(`createAsset`方法)，由于不同的文件也许会导入同样的资源`A`，那么我们没有必要多次创建`A`，毕竟建立`A`的历程还是很长的。因此如果有一个cache对象的话，简直就是事半功倍。

```
console.log(`Start extracting: ${revisedPath}`);

if (cache[revisedPath]) {
  asset.mapping[relativePath] = cache[revisedPath].id;
} else {
  const depAsset = createAsset(revisedPath);
  cache[revisedPath] = depAsset;
  asset.mapping[relativePath] = depAsset.id;
}
```

- 2.umd

我们目前打包输出的bundle结构如下：

```
(function(modules) {
  function load(id) {
    ...
    return module.exports;//1
  }  
})(modules)

```

很显然1处的`return`显得几乎毫无意义，因为没有直接的办法能够接得住这个return的结果，它就像是你在浏览器的`console`里执行了一个函数`var result = do()`,这种方式叫做`var`打包。

其实大部分情况下，比如`react`的项目，不关心这个也是没有问题的，因为`chunk`之间的调用关系已经被`webpack`组织好了，并不需要你自己去管理最终打包的返回值。

但有时候我们为了兼容其他环境或者确实是想拿到这个打包后的结果（代码分离，微前端的拆分等），那我们就需要考虑更完善的兼容方案了，这是`umd`。

我们只需要简单的封装一层即可：

```

(function (root, factory) {
  //commonjs2
  if (typeof module === "Object" && typeof exports === "Object")
    module.exports = factory();
  //commonjs1
  else if (typeof exports === "Object") exports["dummy"] = factory();
  else root["umd-test"] = factory();
})(window, (function(modules) {
              function load(id) {
                ...
                return module.exports;//1
              }  
            })(modules))
)

```

> ps: 笔者这里忽略了AMD。

3. 配置文件

有几个重要的信息还是有必要抽离出来，这里笔者模仿`webpack`，最基本的配置如下：

```
module.exports = {
  entry: './main.js',
  output: {
    filename: 'chunck.js',
    library: 'umd-test',
    libraryTarget: 'umd'  
  },
  presets: [
    '@babel/preset-env'
  ]
}
```

4. 代码分离

笔者多次提到了`dynamicImport`这个语法，其实我这里用了一种比较偷懒的方式实现了代码分离。

首先代码分离必须配置`library`的名字（不用解释了吧），在遍历`AST`时，我就记录了哪些资源是需要异步加载的。

```
const dynamicDeps = {};

if (name === 'dynamicImport') {
  const revisedPath = buildPath(relativePath, path.dirname(filename), config);
  dynamicDeps[revisedPath] = '';
}

traverse(ast, {
  ...
  if (name === 'dynamicImport') {
    const revisedPath = buildPath(relativePath, path.dirname(filename), config);
    dynamicDeps[revisedPath] = '';
  }
  ...
});

```

`dynamicDeps`里的key就表明这个路径的资源是异步模块，由于我还需要在最终阶段修改它，所以暂时没设置它的value。

```
const {
  code
} = babel.transformFromAstSync(
  ast,
  null, {
    plugins: [
      dynamicImportPlugin
    ],
    presets,
  }
);

```

这样我在打包阶段就可以和正常的模块一起输出：

```
function bundle(assets) {
  ...
  if (dynamicDeps.hasOwnProperty(revisedPath)) {
    //code split here:
    //1.assume that the dynamic module does't have mapping
    //2.and not allowed to import the same moudle in other place
    asyncModules.push({
      prefix: `${id}.`,
      content: buildDynamicFactory(id, assets[revisedPath].code)
    });
    return result;
  }

  return [
    ...normalModules,
    ...asyncModules,
  ]
}

```

这里我还用到了 `buildDynamicFactory`, 它实现了一个类`jsonp`的promise：

```
buildDynamicFactory: function (id, code) {
    return `(self || this)['jsonpArray']['${id}'] = function(require, module, exports) {
      ${code}  
    }`
  }
```

只要异步模块被调到，它的factory就会被注册到全局`jsonpArray`对象上，key为模块的id，value为模块的factory。

但在这之前还需要知道如何寻找对应的异步模块，回忆上面的load函数，我需要有如下改造：

```

function load(id) {
  if (!modules[id]) {
    return (function (id) {
      window["jsonpArray"] = window["jsonpArray"] || {};
      const script = document.createElement("script");
      script.src = `/dist/${id}.chunck.js`;
      document.body.appendChild(script);
      return new Promise(function (res, rej) {
        script.onload = function () {
          const factory = window["jsonpArray"][id];
          const module = {
            exports: {},
          };
          factory(null, module, module.exports);
          res(module.exports);
        };
      });
    })(id);
  }
  
  ...

  return module.exports;
}

```
当在`modules`里找不到对应模块时，该模块就是异步模块，我会封装一个promise，当请求到异步模块后，它自己会完成注册，我只需要异步返回下factory执行后的结果即可。

比如，我源代码如果为：

```
dynamicImport('./api')
    .then(res => console.log(`dynamic module response: ${JSON.stringify(res.default())}`));
```

会被转译为：

```
require('./api')
    .then(res => console.log(`dynamic module response: ${JSON.stringify(res.default())}`));
```

注意：这个require返回的是一个promise（参考上面的load函数的修改）。

你可能见惯了`import('xxx').then`的写法，觉得笔者这样改造很怪异，但我想说，语法还不就是人定的么，自己怎么舒服怎么来嘛。

5. 其他

- 实现更复杂的路径解析

这里笔者只是实现了寻找`index.js`和补全文件后缀的简单解析逻辑，更好的方案应该支持自定义`node_modules`，自定义`alias`等等。

- 支持json导入

对于纯文本类型的文件（.yml, .txt, .md, .json...)可以考虑后期支持。

- 支持css/scss

这里默认我只处理了js文件，像css，scss，甚至ts等等可以考虑支持。

### 7 发布

为了让这个小轮子工程化一些，笔者也发布了简单的cli：

```

npm i -g @dummmy/pack-cli

cd your-project

touch pack-config.js

pack

```

### 8 源码

[源码请戳这里](https://github.com/kkkkkxiaofei/dummy-playground/tree/master/pack)