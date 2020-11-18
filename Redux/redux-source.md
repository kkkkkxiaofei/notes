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
 
`store`和`state`最容易混淆，`redux`所做的一切都是为了更好的管理`state`，`store`也不例外。

```
const store: Store = {
  dispatch,
  getState,
  subscribe,
  replaceReducer
}

```

- dispatch

dispach会分发一个action，根据action的类型进入不同的子reducer进行处理，而后产生最新的state，最后在广播所有的回调。

```
const dispatch = (action: Action): void => {
  if (action) {

    if (action.type === INIT) {
      state = currentReducer(initState, { type: INIT });
      return;
    }

    // include @@REPLACE 
    state = currentReducer(state, action);
    
    listeners.forEach(listener => listener());
  }
}
```

> ps: 如果你仔细观察`devtools`的话，会发现在首次会有一个INIT的action，正是用来初始化状态树的。

- getState

这个就再简单不过了，完完全全的getter。但有一点需要注意，仔细看上面的实现，state其实是闭包的。因此只能由getState拿到。

```
const getState: StateGetter = () => state;
```

- subscribe

subscribe只是注册监听器到监听列表，为后续dispatch时调用而使用。其实这个函数的作用非常隐晦，以至于80%以上的情况下你都不会（甚至是没见过）去使用它，但是它却在`react`生态里具有非常重要的作用。试想想，我们发送action，用reducer处理变化，最终的新state该怎么通知你的应用呢？答案必然是重新render，所以对于react应用来说，监听器往往就是组件forceRender的逻辑，关于这一方面，笔者会在`react-redux`里进行详细解释。

```
const subscribe = (listener: Listener) => {
  listeners.push(listener);
  //unsubsribe
  return () => listeners.splice(listeners.indexOf(listener), 1);
}
```

### 5. middleware

`redux`的中间件可能是最有意思的部分了，缺了这部分，想必处理`action`的灵活度是不会被广大开发者认可的。所以说我觉得`Dan`还是很理性的，他并没有赋予`redux`某种天然的能力，而是开放了这个思路任由大家来发挥奇思妙想（比如`redux-thunk`,`redux-saga`等)。

一个小的功能来说明中间件的思路：有一台打印机`printer`，它具有打印，复印查询历史记录等功能，每一个功能都是一个指令，打印机对外只暴露了`exec`方法，参数为指令码`code`，因此它可以这样执行:

```
printer.exec(code)
```

现在我们想在执行指令时能够记录日志：

```
const execWithLog = (printer, code) => {
  console.log('start exec: ', code)
  let result = printer.exec(code)
  console.log('end exec: ', code)
  return result
}

```
功能是有了，可完全是`hard-coding`，那还不如用`monkey-patching`呢。

```
let originExec = printer.exec
const execWithLog = (code) => {
  console.log('start exec: ', code)
  let result = originExec(code)
  console.log('end exec: ', code)
  return result
}
printer.exec = execWithLog
```

这样我们就可以抽一个方法了:

```
const enhancePrinterWithLog = printer => {
  let originExec = printer.exec
  const execWithLog = (code) => {
    console.log('start exec: ', code)
    let result = originExec(code)
    console.log('end exec: ', code)
    return result
  }
  printer.exec = execWithLog
}
```

同理，可以有很多的`enhancer`, 如`enhancePrinterWithXXX`。

```
enhancePrinterWithLog(printer)
enhancePrinterWithXXX1(printer)
enhancePrinterWithXXX2(printer)
...

```

到了这一步似乎好很多了，但是`enhancer`之间没有连贯性，这样穷举的调用实在不友好，我们试着把他们串起来。

```
const logMiddleware = printer => {
  const next = printer.exec
  const execWithLog = (code) => {
    console.log('start exec: ', code)
    let result = next(code)
    console.log('end exec: ', code)
    return result
  }
  printer.exec = execWithLog
  return printer
}

const enhancePrinter = (printer, ...middlewares) => {
  middleares.forEach(md => md(printer))
}

enhancePrinter(printer, logMiddleware, ...otherMiddlewares)
```

> ps:之前我们称作`originExec`是因为只有一个日志功能，现在我们已经把他们串起来了，就是next（下一个的wrapper）

这看起来优雅了一些，但有一个问题，我们这样封装后的中间件只能从开始（第一个）一路不停的执行到结束（最后一个），因为每个中间件调用的`exec`方法都是下一个中间件的`wrapper`，类似于：

```
---md3  start---
  ---md2  start---
    ---md1  start---
    ---md1 finish---
  ---md2 finish---
---md3 finish---
```

试想想我们在`react`中经常`dispatch`一个`promise`，而`redux`天然只接受类型为`Object`的`action`，这个`action`隐藏在`promise`成功后的回调里。针对这个`case`，比如我们第一个中间件是日志`log`，它是无法处理`promise`的，我们可以写一个中间件处理`promise`，可问题是请求回来后，我们发出去的`action`只能继续往下走，但正确的做法应该是重新在走一边所有的中间件，不然日志就会丢失。

比如`md1`,`md2`,`md3`...`mdn`中`md2`是可以处理`promise`的，但是按照上面我们封装的结果来看，`md2`就算同步等待结果，之后也只能往下走。正确的流程应该是md2请求结果后是需要再一次经过md1才对的，因此我们把上面的实现进行再次优化，让它不仅可以往下执行，也可以从头执行。

```
const logMiddleware = printer => next => code => {
  console.log('start exec: ', code)
  let result = next(code)
  console.log('end exec: ', code)
  return result
}

```

我们提炼了这个三阶函数，其中`next`为下一个`middleware`的`wrapper`，而`printer.exec`可以让调用链重新开始，这样一来每个中间件就可以选择是否继续还是重新开始，这一点非常重要。

接下来应用这些中间件也需要改动：

```
const applyMiddlewares = (printer, middlewares) => {
  const nexters = middlewares.reverse().map(md => md(printer))
  const composedNexter = nexters.reduce((f, g) => (...args) => f(g(args)))
  return {
    ...printer,
    exec: composedNexter(printer.exec)
  }
}
```

至此，这个打印机就可以接纳各种中间件实现特殊的需求了。

如果我们把`pirnter`改为`store`, 把`exec(code)`改为`dispatch(action)`，你就会发现，这就是`redux`中间件的核心实现。

> ps: 有一些签名和方法与源码不太一致，笔者在此只为总结核心思路。