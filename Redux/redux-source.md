本篇是笔者阅读源码后，将其精简后的版本

### 1. 什么是redux

`redux`可能是最简单的状态管理机制了，简单到寥寥几行代码就可以清楚的表达它的思路：

```
const listeners = []

const subscribe = (listener) => {
  listeners.push(listener);
  //unsubsribe
  return () => listeners.splice(listeners.indexOf(listener), 1);
}

const dispatch = (action) => {
  state = currentReducer(state, action);
  listeners.forEach(listener => listener());
}
```
`subscribe`用来注册监听列表，`dispatch`用来触发状态变化，之后监听器会捕获最新的状态。如此而已，这就是`redux`最核心的代码，。

### 2. 核心概念

`action`: 普通对象，必须有`type`属性，它表明一个即将发生`state`改变的行为，因此往往需要携带`payload`。

`reducer`: 真正处理`action`的逻辑，只有它知道怎么响应这个`action`（即如何改变state），返回值为新的`state`。

`store`: 相当于`state`操作的封装，可以发送`action`，获取`state`和注册监听器。

`middleware`: 没有中间件的时候，`action`经过所有的`reducer`后就会消失，middleware可以控制action的数据流向，同时可以使得`action`更加的多样化和灵活化。

### 3. reducer

其实这部分不属于`redux`的实现，但因为`reducer`可能是开发人员使用最多的，因此很有必要看下`redux`里是怎么使用我们编写的`reducer`的。

实现如下：

```
export default (reducersMap: ReducerMap): Reducer => {
  let nextState = {}, 
  finalReducer = {};

  const reducerKeys = Object.keys(reducersMap);

  // make sure all reducers are function
  finalReducer = reducerKeys
    .filter(key => typeof reducersMap[key] === 'function')
    .reduce((result, key) => ({ ...result, [key]: reducersMap[key] }), finalReducer);

  // combination
  return (state = {}, action) => {
    const finalReducerKeys = Object.keys(finalReducer);

    let hasChanged = false;

    finalReducerKeys.forEach(key => {
      const currentStateOfKey = state[key];
      const nextStateOfKey = finalReducer[key](currentStateOfKey, action);
      nextState[key] = nextStateOfKey;

      hasChanged = currentStateOfKey !== nextStateOfKey;
    })

    return hasChanged ? nextState : state;
  }
};
```
思路很简单：我们编写的所有的`reducer`最终都会被`combine`成一个大的`reducer`，每当有`action`发出时，该`action`会经过所有的子`reducer`，返回最终的`state`结果，这个过程终`state`也许会被修改很多次，这也就是为什么`reducer`必须要强制返回不可变的`state`。


### 4. store

### 5. middleware

