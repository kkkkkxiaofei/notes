### 1. JSX

#### 1.1 JSX的结构

`Vitrual DOM`(vdom)本质上就是`Plain Object`，为了方便开发者编写`vdom`，于是`JSX`诞生。

一段简单的`jsx`如下：

```
const App = ({ name }) => <div>{name}</div>

<div>
  <App name='jsx test' />
</div>
```

`vdom`的终态（中间态暂时忽略）为：

```
{
  type: 'div',
  children: [
    {
      type: 'div',
      props: {
        name: 'jsx test'
      }
    }
  ]
}
```

`jsx`的解析逻辑极其简单：当遇到任意闭合尖括号时，将其转化为`createElement`的函数调用。

例如`<div>hello</div>`会被转化为:

```
{
  type: 'div',
  children: [
    'hello'
  ]
}
```

可以看到，即使对于最简单的原生`html`标签，`type`为`nodeName`(DIV),而`children`则为字符串。

但有一种情况比较特殊：

```
<App name='jsx test'>
  <div>hello</div>
</App>
```

转化后为：

```
{
  type: 'App', // constructor of App component
  props: {
    name: 'jsx test'
  },
  children: [
    {
      type: 'div',
      children: [
        'hello'
      ]
    }
  ]
}
```

`type`变成了`function`，这个特殊之处很明显。但是它离终态还是有一定距离，这就涉及到了`vdom`的再次转换（稍后我们细说）。

#### 1.2 JSX的实现

如果你熟悉[前端打包工具的原理](http://flypursue.com/notes/Webpack/bundler.html)的话，那么自然对`AST`以及`Babel Plugin`不陌生。

`jsx`其实就是一个`babel plugin`，这里我们没必要再去造这个轮子，会因为`react jsx`官方的插件是提供别名的，比如我们的`babel.rc`配置如下：

```
{
  ...
  "plugins": [
    ["transform-react-jsx", {"pragma": "DummyReact.createElement"}]
  ]
  ...
}
```

此配置表明，当遇到任何`jsx`闭合标签时，会编译为`DummyReact.createElement`的函数调用。

这其实也解释了为什么你写的任何`react`组件都需要`import React from 'react'`，但仔细找却发现没有显式调用，其实它是需要结合`jsx`插件使用的。

`jsx`只负责语法转化，所以`DummyReact.createElement`还只是一个签名，代码自然还需要我们自己实现：

`DummyReact.js`

```
const createElement = (type, props, ...children) => ({ type, props, children })
export { createElement }
```

至此，`jsx`的转化我们借助已有的插件已经实现，这一步运行后的结果就是`vdom`。


### 2. vdom to dom

使用`jsx`创建`vdom`，就是因为`vdom`是纯`js`对象，用描述性的结构在操作`vdom`自然很方便和快捷，这样就避免了大量`real dom`的操作（这是极其耗能的）。

但，最终我们需要的还是浏览器才能够认识的dom。

#### 2.1 从一般的jsx到dom

通过观察不难发现，一般的jsx

#### 2.2 从组件的jsx到dom

上面提到，在生成组件的

> ps: 如果只讨论操作dom这一层面的话，vdom绝对性能极佳；但在做例如diff的操作时，vdom由于层级较深，所以比较起来也是相当耗时，这就不一定孰好孰坏了(取决于算法喽)。所以vdom一定比dom高效吗，此处保留观点。




参考：

[React-in-depth](https://medium.com/react-in-depth/inside-fiber-in-depth-overview-of-the-new-reconciliation-algorithm-in-react-e1c04700ef6e)

[160行代码搞定react](https://medium.com/@sweetpalma/gooact-react-in-160-lines-of-javascript-44e0742ad60f)
