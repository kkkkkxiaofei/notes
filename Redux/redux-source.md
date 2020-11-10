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

### 2. reduer

### 3. enhancer
  - 中间件

