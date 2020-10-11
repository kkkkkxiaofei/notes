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



