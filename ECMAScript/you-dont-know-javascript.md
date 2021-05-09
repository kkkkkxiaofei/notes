### 1.变量提升

先考虑以下代码(case1-1)：

```js
a = 1;
var a;
console.log(a);
```

大部分情况，我们会认为`a = 1`（global）会被`var a;`（局部）覆盖掉，最终输出`undefined`。然而结果是`1`。

再考虑以下代码(case1-2)：

```js
console.log(a);
var a = 1;
```

在case1-1的基础上，你是不是还会认为会输出`1`，亦或是认为`a`没有定义。然后输出为`undefined`。

解释：

对于变量的声明和赋值是在不同阶段进行的，前者是在编译期，而后者是在运行期，于是case1-1就变成了：

```js
var a;
a = 1;
console.log(a);
```
而case1-2可以看作：

```js
var a;
console.log(a);
a = 1;
```

***Note: 谨记，变量声明在前，赋值在后***

case1-3:

```js
foo();

function foo() {
	console.log( a ); // undefined
	var a = 2;
}
```
通过前两个case，我们知道变量提升在前，可以具体提升多前呢？其实它是在当前作用域进行顶端提升，如当前`var a = 2`是在方法的花括号呢，属于该该方法的作用域，并且提升时在当前作用域的最顶端，即：

```js
foo();

function foo() {
  var a;
	console.log( a ); // undefined
	a = 2;
}
```

case1-4:

```js
foo();

var foo;

function foo() {
	console.log(1);
}

foo = function() {
	console.log(2);
};
```

一般变量需要提升，方法也算是变量，而且提升在最前面：

```js
function foo() {
	console.log(1);
}
//var foo is ignored cause duplicated declaration
foo();

foo = function() {
	console.log(2);
};
```
自然是输出`1`。

case1-5:

```js
foo();

function foo() {
	console.log(1);
}

var foo = function() {
	console.log(2);
};

function foo() {
	console.log(3);
}
```
类似的，按照`方法声明优先`的原则，`foo`在调用之前必然是已经声明了，且被后者覆盖，故输出`3`;


### 2. Event Loop

#### 2.1 浏览器中的事件循环

这要从`js为什么是单线程而ajax又是异步`的说起。

当前`javascript`运行在`v8`引擎中，`v8`里面有方法执行栈，有内存堆。而`v8`只是浏览器的一部分，浏览器还提供了GUI渲染线程，事件触发线程，定时器线程，异步请求线程。

众所周知，`js`是单线程的，那在浏览器中是怎么支持异步非阻塞的代码运行的呢？这就得靠`Event Loop`(事件循环)。


`js`运行时，会生成方法栈，栈描述了函数调用顺序，程序每执行一步就会进行一次入栈。若栈空，则会从`task queue`里取出最早的任务放入方法栈内执行，每个`task`执行后会去执行所有在`job task`里的任务，当`task queue`里没有任务时，则会进入等待，这个过程就叫做事件循环。

`macrotask`: `宏任务`/`task queue`/`message queue`，例如事件回调，定时器回调，I/O回调等都会进入该队列。

`microtask`: `微任务`/`job task`，产生于ES6时代，promise的回调会进入该队列。

所以`setTimeout`参数里的时间只代表多久以后该回调会进入`macrotask`列表，而具体什么时候入栈去执行，这就要看具体情况了。若有任务在长时间执行，那么就会阻塞`Event Loop`，从而影响其他任务的执行，甚至导致UI假死现象，总之`setTimeout`的时间是不可靠的，但它一定不会比你设置的时间早执行。

** task vs micro-task **

如下demo:

```js
<script type="text/javascript">
    	
	const parent = document.querySelector('.parent');
	const child = document.querySelector('.child');

	//1
	const onClick = () => {
		//2
		console.log('click callback start');

		//3
		setTimeout(() => {
			console.log('setTimeout');
		}, 0);

		//4
		Promise.resolve()
			.then(() => console.log('promise'))

		//5
		console.log('click callback end');
	}

	child.addEventListener('click', onClick);
	parent.addEventListener('click', onClick);

</script>
```

点击child后输出：

```
click callback start
click callback end
promise
click callback start
click callback end
promise
setTimeout
setTimeout
```

分析：

a)点击child后会进入事件回调1处，2处直接入栈执行,3为异步调用，它的回调会进入`macrotasks`队列，4处是特殊的异步，回调则会进入`microtasks`队列，5和1类似，直接输出。

b)第一次的`onClick`代码执行完毕，栈空。取出`promise then`入栈，执行后出栈，栈空。

c)此时child的点击导致了冒泡，冒泡的`callback`回来了，再次执行a),b)

d)第二次的`onClick`完成后，栈空，此时`macrotasks`队列里仍然有两个`setTimeout`没有执行，入栈执行，完毕。

总结：

1.setTimeout,setInterval等属于宏任务

2.promise,async属于微任务

3.每当栈空后会从`macrotasks`队列里取出宏任务执行，每次执行完一个宏任务，都会去执行微任务。

4.每个宏任务之后，会立即执行微任务队列中的所有任务，然后再执行其他的宏任务，或渲染，或进行其他任何操作，用以确保微任务之间的环境一致（新网络数据等）

[参考1 blog of jakearchibald](https://jakearchibald.com/2015/tasks-microtasks-queues-and-schedules/)

[参考2 JS.INFO Event loop](https://javascript.info/event-loop#use-case-3-doing-something-after-the-event)

[参考3 Node.js Event loop](https://nodejs.dev/learn/the-nodejs-event-loop)

[参考4 事件循环头条好文章](https://www.toutiao.com/i6909456210169315844/?tt_from=weixin&utm_campaign=client_share&wxshare_count=1&timestamp=1608769572&app=news_article&utm_source=weixin&utm_medium=toutiao_ios&use_new_style=1&req_id=202012240826110101470831040D3AC743&group_id=6909456210169315844)

[参考5 知乎讲解](https://zhuanlan.zhihu.com/p/54882306)

#### 2.2 Node.js中的事件循环

先看下面的例子：

```js

setTimeout(function() {
	console.log('timeout1');
	Promise.resolve('promise1').then(console.log);
}, 0);

setTimeout(function() {
	console.log("timeout2");
	Promise.resolve('promise2').then(console.log);
}, 0);

```

如果执行在浏览器中结果必然是：

```
timeout1 -> promise1 -> timeout2 -> promise2
```

但是`Node`里就不一定了，很有可能是：

```
timeout1 -> timeout2 -> promise1 -> promise2
```

这里说`不一定`是因为根据笔者的测试(Node.js 12)，结果是和浏览器一致的，但是在早起的Node版本里确实可能不一定，说明Node的升级也会逐渐将Eventloop的实现向浏览器靠拢。

但是根据官方的解释，`Node.js`的`Event Loop`机制的确是和浏览器端是不一致的，如下图：

![](/images/js/node-event-loop.png)

- timers: 这个阶段会执行setTimeout()和setInterval()的回调

- pending callbacks: 处理一些上一轮循环中的少数未执行的 I/O 回调

- idle, prepare: 内部使用.

- poll: 获取新的 I/O 事件, 适当的条件下 node 将阻塞在这里

- check: setImmediate()的回调会在此阶段调用

- close callbacks: 执行一些关闭时间的回调，如`socket.on('close', ...)`

*** 在浏览器中，每执行完一个macrotask之后就会执行所有的microtask；而在Node中，microtask是在各个阶段之间执行的，比如timers阶段完成后但是在pending之前。 ***


事件循环在`Node.js`中有些不一样，主要体现在两个新的API:

*** 1. nextTick ***

*** 2. setImmediate ***

to be continued...

#### 2.3 浏览器，Node和v8之间的关系


|         | js engine | network | event | dom | disk |
|---------|-----------|---------|-------|-----|------|
| v8      | Y         | N/A     | N/A   | N/A | N/A  |
| browser | Y         | Y       | Y     | Y   | N/A  |
| node    | Y         | Y       | Y     | N/A | Y    |

#### 2.4 事件委托

比如要实现p标签的点击功能，我们可以绑定指定的p，但也可以将事件委托给父级：

```
document.addEventListener('click', function(e) {
	if (e.target.nodeName === 'P') {
		console.log('p is clicked!');
	}
});
```

这称之为`事件委托`。

当然，我们可以自定义事件。

```
const customEvent = new CustomEvent('log', { 
	bubbles: true,
	detail: {
		data: 'hello'
	}
});
document.addEventListener('log', function(e) {
	console.log('log event invoked', e.detail.data);
});
document.addEventListener('click', function(e) {
	if (e.target.nodeName === 'P') {
		console.log('dispatching');
		e.target.dispatchEvent(customEvent)
		console.log('dispatched');
	}
});

```
当点击p时，打印如下:

```
dispatching
log event invoked hello
dispatched
```

结论：

- 与浏览器的事件不一样，自定义事件并不是异步的。
- 自定义事件必须显示定义`bubbles`才会具有冒泡的机制，默认不冒泡。
- 自定义事件的传参可利用`detail`对象。
- 自定义事件的返回值为布尔值，表明是否可以取消。




### 3.substr vs substring

`substr`: (start, length)

`substring`: (start, end)


### 4.preventDefault, stopPropagation, return false

`return false`: 一般用于jquery，对原生事件并无太大意义

`preventDefault`: 阻止默认行为，如a标签的跳转，checkbox的勾选等

`stopPropagation`: 阻止冒泡

### 5. new A() vs A()

```js
function A(name) {
  this.name = name;
	return this;
}

let a1 = new A('Kelvin1');
let a2 = A('Kelvin2');

console.log(a1, a2);
```

`对于a1`: new关键字会寻找构造函数上原型对象里的constructor属性进行构建当前实例，并把当前对象指向this，若不返回结果则默认返回this。此外`a1 instanceof A`返回true，因为a1的原型链指向A的原型对象。

new一个对象实际上干了三件事:

```js
var obj = {};
A.apply(obj, arguments);
obj.__proto__ = A.prototype;

// var obj = Object.create(A.prototype);
// A.apply(obj, arguments);
```

>ps: 这里忽略了返回值的处理，若无返回值应该返回this（上面的obj）。

`对于a2`: 必须显式的`return this`，否则返回undefined;此外由于在外部调用，则this默认指向window(browser)/global(node)，a2与A没有任何关系，必然也不是其实例, 它的原型链直接指向了Object的原型；

那么如果怎么让a2成为真正的A的实例呢：

```js
let a2 = A.call({}, 'reall a2');
a2.__prop__ = A.proptotype;
```

### 6. Object.create(obj)

Object.create会将新创建的对象的原型链指向obj，所以可以这样实现

```js
function create(obj) {
	function T() {}
	T.prototype = obj;
	return new T();
}
```

因此，Object.create常常用在组合继承的方式里，类似

```js
Man.prototype = Object.create(Person.prototype);
```

这样的话一旦执行new Man(), 该实例的原型链上必然可以找到基类构造器的原型对象，instanceof的话必然就是true了。

### 7. Object.defineProperty vs Proxy

`Object.defineProperty`: ES6之前，实现对象属性监控的最佳手法，兼容IE，最大的弊端在于一次只能监控已有对象的一个属性，且无法监控数组。

`Proxy`: ES6的产物，算是前者的enhancement，可监控数组变化，且捕捉的行为也比较多，直接捕获的是target本身，所以灵活性很强。（性能未知）

### 8. 防抖和节流

防抖（debounce）：多次连续行为，只执行最后一次（即t时间内没有下一次）。

```js
function debounce(fn, ms) {
	var timer;
	return function(...args) {
		clearTimeout(timer);
		timer = setTimeout(function() {
			fn.apply(this, args);
		}, ms);
	}
}
```

节流（throttle）：t时间内连续行为只会执行第一次。

```js
function throttle(fn, ms) {
	var timer;
	return function(...args) {
		if (timer) return;
		timer = setTimeout(function() {
			fn.apply(this, args);
			timer = null;
		}, ms);
	}
}
```

### 9. ES6的class继承

例：基类为A，子类为B;

若想实现继承，则b不但是B的实例，还得是A的实例，且b内含有A中的所有属性。

- 1.b获取super的属性

```js
function B(name) {
	A.apply(this, arguments)
}
```

- 2.让A的原型对象出现在b的原型链上

```js
B.prototype = Object.create(A.prototype);
```
这里可得: `b.__proto__` -> `B.prototype` -> `B.prototype.__proto__` -> `A.prototype`

因此 `b instanceof A` 成立。

- 3.恢复b的构造器

`B.prototype`原本内部是有`constructor`属性（指向Man)，第2步修改原型链时把`constructor`属性给覆盖了，所以需要重置(注：constructor的修改不会影响instanceof的结果)。

```js
B.prototype.constructor = B;
```

- 基于以上提炼继承的最佳方案：


```js
function Person(name) {
  this.name = name;
}

Person.prototype.sayName = function() {
  console.log(this.name);
}

function Man(name) {
	//1
  Person.call(this, name);
}

//2
Man.prototype = Object.create(Person.prototype, {
  constructor: {
    value: Man,
    writable: true,
    configturable: true,
  }
})

//3
Man.__proto__ = Person;

var man = new Man('kelvin');

console.log(man instanceof Man); // true
console.log(man instanceof Person); // true
man.sayName(); // kelvin
```

分析：

`1`: 利用子类的this，设置与父类相同的实例属性（不含原型属性）。

`2`: 弥补原型属性没有继承的漏洞，且维护子类原型对象指向父类原型对象，因而instanceof成立。

`3`: 根据Babel解析ES6 class的标准实现，设置构造器的关系。

> 为了使子类规范调用，也可以加上this指向的判断。

### 10. this指向问题

直接调用函数: 非strict模式下是window;strict模式下为undefined。

对象上调用: 调用对象

call/apply/bind: 若第一个参数为null，在strict的模式下为undefined，非strict模式下会是window

箭头函数：没有this，必须在调用处向上依次寻找作用域(非箭头函数），若找不到则返回window(严格模式为undefined)

事件：this指向事件绑定元素(target为事件触发元素，currentTarget才是事件绑定元素);setTimeout依然遵循事件绑定，为全局绑定。


### 11. async vs Promise

若在一个方法内调用`await`，则必须显式的标注该方法为`aysnc`，这是最基本的用法。

- 但执行异步方法时可以直接调用

```js
let getData = () => Promise.reject('res');
let fn = async () => await getData();
fn();

//Promise {<fulfilled>: "res"}
```
- 如果不在async里await呢

```js
let fn = async () => 'async fn';
fn();

//Promise {<fulfilled>: "async fn"}
```

可以得出：async会返回一个promise，这个promise的结果箭头函数返回的结果。

- await后面的代码

```js
let getData = () => Promise.reject('res');//1
let fn = async () => {
	await getData();
	console.log('======after await=======');//2
};
fn();
```

此代码2处并不会打印，因为await解析出来的promise有异常。

若1处改为：

```js
let getData = () => Promise.resolve('res');//1
```

则可以输出log。

可是我一不小心手误，将1处写为：

```js
let getData = () => { Promise.reject('res') };//1
let fn = async () => {
	await getData();
	console.log('======after await=======');//2
};
fn();
```
这时2处是可以打印的，因为1处是一个没有返回值的普通函数；如果这里把1处内部花括号里

显式return出去的话，那么就等同于上一个例子。

可见对于await来说它会解析promise(async也是prmomise)，如果await后面不是promise，则正常执行。

> ps:需要注意的是，aysnc里的函数必须有返回值，不然外部调用aysync函数（无论是否用await）都无法拿到结果。

### 12. Closure

闭包：当前函数f和其周围此法作用域形成依赖关系，导致f可以访问到外部变量，因此形闭包。

优点：

- 1.私有变量

```js
function Person() {
	var name = 'Kelvin'
	this.getName = function() {
		return name;
	}
}
```

- 2.柯里化

```js
function add(x) {
	return function(y) {
		return x + y;
	}
}
const add1 = add(1);
const add2 = add(2);
```

- 3.缓存(持久化)

```js
function debounce(fn, ms) {
	var timer;
	return function(...args) {
		if (timer) {
			clearTimeout(timer);
		}
		timer = setTimeout(function() {
			fn.apply(null, args);
		}, ms);
	}
}
```

缺点：内存泄漏

- 4.利用闭包和作用域的角度重新分析下面的经典代码

```js
for (var i=0;i<10;i++) {
	//1
	setTimeout(function() {
	//2
		console.log(i);
	}, 0)
}
```
var具有函数作用域，setTimout执行之前必须让主线程把for执行完，此时i还具有作用域（i为10）；当执行setTimeout时，回调里（2处）没有i的作用域，于是向上（1处）寻找，发现i为10，于是全部输出10。

`角度1`: 改变var的作用域，使用let不解释。

`角度2`: 利用setTimeout的第三参数。

```js
for (var i=0;i<10;i++) {
	setTimeout(function(j) {
		console.log(j);
	}, 0, i)
}
```

缺点是兼容性（IE9不支持）。

`角度3`: IIFE

```js
for (var i=0;i<10;i++) {
	(function(j) {
		//1
		setTimeout(function() {
		//2
			console.log(j);
		}, 0)
	})(i)
}
```
IIFE函数创建了新的函数作用域（1处）。


### 13. 浅拷贝和深拷贝

- 深拷贝：

JSON.stringify: 缺点是会忽略方法，只能处理基本类型。

手动实现: 需要一层层的展开，可参考lodash的set或者Immutable的操作。


- 浅拷贝：

Object.create: 利用原型链指向需要复制的对象

Object.assign: 用的最多，但语法冗余，一般可以直接用`...`展开

### 14. 类型判断

- typeof

js目前有7种原始类型: `Null`, `Undefined`, `BigInt`, `Number`, `Boolean`, `String`, `Symbol`；引用类型为`Object`,`Object`的子类有: `Array`, `RegExg`, `Function`.

对于原始类型，除了`Null`返回`object`之外，其他都能用`typeof`获得类型；对于引用类型除了`Function`之外其他都返回`object`.

所以`typeof`并不准确。

- Object.prototype.toString

```js
Object.prototype.toString.call(1); // [object Number]

Object.prototype.toString.call(NaN); // [object Number]

Object.prototype.toString.call(Infinity); // [object Number]

Object.prototype.toString.call(true); // [object Boolean]

Object.prototype.toString.call(Symbol('s')); // [object Symbol]

Object.prototype.toString.call(null); // [object Null]

Object.prototype.toString.call(undefined); // [object Undefined]

Object.prototype.toString.call(''); // [object String]

Object.prototype.toString.call(BigInt(1)); // [object BigInt]

Object.prototype.toString.call({}); // [object Object]

Object.prototype.toString.call(function() {}); // [object Function]

Object.prototype.toString.call(/\s/); // [object RegExp]

```
`toString` 几乎是万能的类型检查工具，但由于它在原型链上，因此还是会有被篡改的风险。

- instanceof

如果我们已经知道构造函数，那么`instanceof`很有用，它需要检查当前构造器的原型对象是否存在于实例的原型链上，但这只对引用类型有用。如果想让原始生效，需要用到`Symbol.hasInstance`:

```js
class NumberType {
	static [Symbol.hasInstance](instance) {
		return typeof instance === 'number';
	}
}
```
```js
111 instanceof Number; // false

111 instanceof NumberType; // true
```

因此我们可以修改任意构造函数的`[Symbol.hasInstance]`，从而改变`instanceof`的逻辑，上面的代码使用了静态类型，`Babel`转译后其实就是构造函数的属性：

```js
function NumberType() {}

Object.defineProperty(NumberType, Symbol.hasInstance, {
	configurable: true,
	writable: true, // here just for test, maybe sometime don't allow to change
	value: function (instance) {
		return typeof instance === 'number';
	}
})

111 instanceof NumberType; // true

```

** instanceof手动实现？ **

```js
function iof(instance, Parent) {
	if (typeof instance !== 'object' || instance === null)
		return false
	let proto = Object.getPrototypeOf(instance);

	while(proto !== null) {
		if (proto === Parent.prototype) 
			return true;
		proto = Object.getPrototypeOf(proto);
	}

	return false;
}
```
使用循环向上找是考虑到了A->B->C的情况。

** 实战灵魂拷问之常用类型判断(参考lodash) **

`isFunction`

```js
function isFunction(value) {
	return typeof fn === 'function';
}
```

`isString`

暴力写法：
```js
function isString(value) {
	return Object.prototype.toString.call(value) === '[object String]';
}
```

考虑到原型链的安全性，lodash的优化：

```js
function isString(value) {
  const type = typeof value
  return type === 'string' || 
	(type === 'object' && value != null && !Array.isArray(value) && Object.prototype.toString.call(value) === '[object String]')
}
```

`isObject`

```js
function isObject(value) {
	//1
	if (Object.prototype.toString.call(value) !== '[object Object]')
		return false
	
	//2 Object.create(null)
	if (Object.getPrototypeOf(value) === null) 
		return true;

	//3
	let proto = value;
	while(Object.getPrototypeOf(proto) !== null) {
		proto = Object.getPrototypeOf(proto);
	}
	return proto === Object.getPrototypeOf(value);
}

```
这里的`isObject`对应lodash的`isPlainObject`，大部分情况我们需要判断是对象的场景就是`Plain Object`的场景，所以3处处理了类似继承或者arrary的衍生对象（总之就是必须直接继承Object)。

### 15. call, apply, bind polyfill

`call`

```js
Function.prototype._call = function(context, ...args) {
	const sym = Symbol('');
	context[sym] = this;
	const result = context[sym](...args);
	delete context[sym];
	return result;
}

```

`apply`


```js
Function.prototype._apply = function(context, args) {
	return this._call(context, ...args);
}

```

`bind`

```js
Function.prototype._bind = function(context, ...args) {
	return function(...nextArgs) {
		return this._call(context, ...args, ...nextArgs);
	}
}
```

测试：

```js
var name = 'window';

var obj = {
  name: 'obj',
  getName(prefix, suffix) {
    return `${prefix}${this.name}${suffix}`;
  }
}

obj.getName._call(obj, '(', ')'); // (obj)

obj.getName._apply(obj, ['{', '}']); // {obj}

var b1 = obj.getName.bind(obj, '(');

b1(')'); // (obj)

var b2 = obj.getName.bind({});

b2('[', ']'); // [undefined]


```