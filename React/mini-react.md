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

`type`变成了`function`，这个特殊之处很明显，稍后我们细说。

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

使用`jsx`创建`vdom`，就是因为`vdom`是纯`js`对象，用描述性的结构操作`vdom`自然方便和快捷，这样就避免了大量`real dom`的操作（这是极其耗能的）。

但，最终我们需要的还是浏览器才能够认识的dom。

> ps: 如果只讨论操作dom这一层面的话，vdom绝对性能极佳；但在做例如diff的操作时，vdom由于层级较深，所以比较起来也是相当耗时，这就不一定孰好孰坏了(取决于算法喽)。所以vdom一定比dom高效吗，此处保留观点。

#### 2.1 从一般vdom的到dom

通过观察不难发现，一般的`vdom`满足以下条件：

- type为jsx标签名，且为字符串
- props为简单对象
- children为一组element

由于标签名是天然的html标签，因此可以直接创建dom节点(`document.createElement(type)`)。props携带了当前dom节点以及其子孙的属性，一般情况下（除过一些特殊的key名），我们可以直接`setAttribute`。children就更加简单了，递归是必须的了。

因此，我们有了一个初步实现：

```
export const render = (vdom, parentNode) => {
  const { type, props = {}, children } = vdom
  let node;

  if (isString(vdom) || isNumber(vdom)) {
    node = document.createTextNode(vdom)
  }

  if (isArray(vdom)) {
    vdom.forEach(_vdom => render(_vdom, parentNode))
    return parentNode
  }

  if (isObject(vdom)) {
    if (isString(type)) {
      const _parentNode = document.createElement(type)
      children.forEach(childVdom => render(childVdom, _parentNode))
      Object.entries(props || {}).forEach(([key, value]) => setAttribute(_parentNode, key, value))
      node = _parentNode
    }
  }
  
  const result = parentNode ? parentNode.appendChild(node) && node : node
  return result
}

```

这里我们无论是函数名还是参数，都保持和`ReactDom`的render一致。

#### 2.2 从组件的vdom到dom

上面提到，一般的`vdom`里`type`是`html`标签名，组件的`vdom`最大的区别就是`type`是组件的构造器。组件的真正`vdom`是其自身`render`后的结果，这里就要分`function component`和`class component`了。

```
if (isFunction(type)) {
  //class component
  if (Object.getPrototypeOf(type) === Component) {
    return Component.render(vdom, parentNode, render, update)
  } 
  //function component
  return render(type({ ...props, children }), parentNode)
}
```

这里我们提到了`Component.render`（稍后会实现），接下来我们开始实现`Component`。

### 3. Component

`Component`的签名如下：

```
class Component {
  constructor(props) {
    this.props = props
  }

  componentWillReceiveProps(nextProps) {}

  shouldComponentUpdate(nextProps, nextState) {
    return this.props !== nextProps || this.state !== nextState
  }

  componentWillUpdate(nextProps, nextState) {}

  componentDidUpdate() {} 

  componentWillMount() {}

  componentWillUnmount() {}

  componentDidMount() {}

  static render(vdom, parentNode, render, update) {}

  static update(oldNode, newVdom, parentNode, update, render) {}

  setState(nextState) {}
}

```

这里为了简单起见，我们只实现`props`的构造器（忽略context）。`Component`由生命周期，`render`，`setState`和`update`构成。

#### 3.1 render

`render`函数不同于组件实例（instance）的render，后者返回的是终态的`vdom`，而它能够处理`vdom`里有组件构造器的情况，并且在此过程可以管理组件的部分生命周期。

```
static render(vdom, parentNode, render, update) {
  const { type, props, children } = vdom
  const instance = new type({ ...props, children })
  instance.componentWillMount()
  console.log(instance.render())
  const node = render(instance.render())
  parentNode && parentNode.appendChild(node)
  instance.componentDidMount()
  instance._render = render
  instance._update = update
  node._parentNode = parentNode
  node._instance = instance
  instance._node = node
  return node
}
```
过程很简单：由于`type`为组件构造器，首先可以获取组件`instance`，此时进入`准备挂载阶段(componentWillMount)`，而后在`instance`上调用实例方法`render`获取终态的`vdom`，再挂载到父节点上，此时进入`已经挂载阶段(componentDidMount)`，最后记录节点信息。

#### 3.2 setState

`setState`可以说是唯一能够更新组件状态的方法了，它的大致实现如下： 

```
if (this.shouldComponentUpdate(nextState, this.props)) {
  this.componentWillUpdate(nextState, this.props)
  this.state = { ...nextState }
  const newVdom = this.render()
  const oldNode = this._node
  this._update(oldNode, newVdom, oldNode._parentNode)
  this.componentDidUpdate()
}
```

若组件需要更新（`shouldComponentUpdate`）,则进入`即将更新阶段(componentWillUpdate)`,而后调用组件实例上的`render`方法获取最新的`vdom`，最后更新组件，进入`更新完毕阶段(componentDidUpdate)`。

除了`update`外，`Component`的基本功能已经实现，`update`我们涉及`react`的`diff`算法，我们放到下一篇章。




参考：

[React-in-depth](https://medium.com/react-in-depth/inside-fiber-in-depth-overview-of-the-new-reconciliation-algorithm-in-react-e1c04700ef6e)

[160行代码搞定react](https://medium.com/@sweetpalma/gooact-react-in-160-lines-of-javascript-44e0742ad60f)
