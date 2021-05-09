<div style="text-align: center">
  <img src="assets/images/new-cover.png" />
</div> 



### 1. JavaScript基础

#### 1.1 闭包

- 闭包的定义
- 闭包能用来干什么（至少三个场景）

#### 1.2 this

- this的指向（箭头函数，实例方法，全局调用，事件回调，setTimeout）
- call/apply/bind的区别，如何手动实现？

#### 1.3 原型

- 原型和原型链
- 如何优雅的手动设置原型链（不许使用__proto__)
- 为什么有的库喜欢把方法定义的原型对象上
- instanceof的真正含义

#### 1.4 继承

- 继承的最佳实现
- A() vs new A()

#### 1.5 Promise

- async/await vs promise
- promise A+
- Promise.resolve() vs setTimeout(0)

#### 1.6 Event loop

- 浏览器 vs Nodejs
- 宏任务和微任务

#### 1.7 事件委托

- 如何在捕获阶段触发回调
- 自定义事件

### 1.8 数据劫持

- Object.defineProperty vs Proxy

### 2. CSS

- disabled vs readonly
- 伪元素和伪类
- z-index层叠关系
- viewport
- flex
- grid
- 16:9怎么实现

### 3. 浏览器

- 浏览器的组成
- 浏览器 vs Nodejs vs v8
- defer vs async
- 关键路径分析
- 页面渲染流程
- transform vs position
- requestAnimationFrame

### 4. React(todo)

- 什么是JSX
- 什么是虚拟DOM
- 怎么实现DOM Diff (key的作用)
- 哪些生命周期在16以后就不安全了，为什么
- 手动实现一个mini react，有什么思路
- hook原理
- reconciler是什么
- 了解fiber node吗
- redux和react什么关系
- redux中间件的原理
- 什么是shallowEqual
- 什么是React-Redux
- useSelector vs connect
- 如何实现force render
- 什么是ssr

### 5. 工程化

#### 5.1 webpack

- module vs chunk vs bundle
- 为什么你写的代码从来不会出现声明问题
- 什么是代码分离，原理是什么
- 什么是tree shaking， 原理是什么
- 什么是HMR
- 什么是UMD
- esm vs commonjs
- compiler vs compilation 
- loader vs plugin
- 如何实现一个打包工具
- webapck vs rollup
- webpack最佳优化实践

### 5.2 babel

- 什么是AST
- 什么是preset
- 什么是plugin
- babel-tranform, taverse, parse是什么

### 5.3 部署

- 你的前端项目是怎么部署的
- 什么是CDN


### 6. Typescript

- interface vs type
- never
- unknown vs any
- 如何定义一个JSON结构
- d.ts
- namespace/module
- 如何打包ts+es6的工程项目
- 如何管理一个lib的typing文件

### 7. HTTP

- HTTP1.0 VS HTTP1.1 VS HTTP2.0
- HTTPS加密原理
- 301 vs 302
- cookie（各种属性的含义及用途）
- 强缓存
- 协商缓存（304）
- 如何跨域
- 什么是JSONP
- XSS
- CSRF
- 三次握手 vs 四次挥手

### 8. Nodejs(todo)

- 进程与线程
- node多进程
- 事件循环
- 守护进程(forever, nodemon)

### <mark>9. 算法</mark>

- 栈/队列/链表/树
- 排序算法（时间/空间复杂度）
- BFS/DFS以及实际用途


### 其他

- Oauth2.0
- 微前端实践
- AWS