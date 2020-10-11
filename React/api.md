### JSX

一个简单的组件：
```
const ReactComponent = props => {
  return (
    <div>
      <h1>{props.title}</h1>
      <div>{props.content}</div>
    </div>
  )
}

<ReactComponent title='title' content='content' />
```

经过babel转译后：

```
"use strict";

const ReactComponent = props => {
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h1", null, props.title), /*#__PURE__*/React.createElement("div", null, props.content));
};

/*#__PURE__*/
React.createElement(ReactComponent, {
  title: "title",
  content: "content"
});
```

`ReactComponent`为组件签名，`<ReactComponent />`才是真正的组件。

JSX语法经过bable后会转译为`createElement`,即组件其实是一个简单的对象（名为React元素），该对象的结构为：

```
{
  $$typeof : Symbol('react.element'),
  type: 'ReactComponent',
  props: {
    title: 'title',
    content: 'content',
    children: [
      {
        $$typeof: Symbol('react.element'),
        type: 'h1'
        children: 'title' 
      },
      {
        $$typeof: Symbol('react.element'),
        type: 'div'
        children: 'content' 
      }
    ]
  }
}
```

### Component

Class Component的源码如下：

```
function Component(props, context, updater) {
  this.props = props;
  this.context = context;
  this.refs = emptyObject;
  this.updater = updater || ReactNoopUpdateQueue;
}

Component.prototype.isReactComponent = {};

Component.prototype.setState = function(partialState, callback) { ... }

Component.prototype.forceUpdate = function(callback) { ... };
```

我们最常用的就是前两个参数，至于`updater`后续笔记在补充说明。

`PureComponent`最大的区别就是在原型对象上设置了`isPureReactComponent = true`。

### React.memo

```
export function memo<Props>(
  type: React$ElementType,
  compare?: (oldProps: Props, newProps: Props) => boolean,
) {
  ...

  const elementType = {
    $$typeof: REACT_MEMO_TYPE,
    type,
    compare: compare === undefined ? null : compare,
  };

  ...

  return elementType;
```

`memo`只是对`type`(组件签名)的一种封装，它提供了自定义的比较器，若没有传默认为空，但是在后期使用该组件时会设置`shallowEqual`。