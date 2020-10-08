### 1.变量提升

先考虑以下代码(case1-1)：

```
a = 1;
var a;
console.log(a);
```

大部分情况，我们会认为`a = 1`（global）会被`var a;`（局部）覆盖掉，最终输出`undefined`。然而结果是`1`。

再考虑以下代码(case1-2)：

```
console.log(a);
var a = 1;
```

在case1-1的基础上，你是不是还会认为会输出`1`，亦或是认为`a`没有定义。然后输出为`undefined`。

解释：

对于变量的声明和赋值是在不同阶段进行的，前者是在编译期，而后者是在运行期，于是case1-1就变成了：

```
var a;
a = 1;
console.log(a);
```
而case1-2可以看作：

```
var a;
console.log(a);
a = 1;
```

***Note: 谨记，变量声明在前，赋值在后***

case1-3:

```
foo();

function foo() {
	console.log( a ); // undefined
	var a = 2;
}
```
通过前两个case，我们知道变量提升在前，可以具体提升多前呢？其实它是在当前作用域进行顶端提升，如当前`var a = 2`是在方法的花括号呢，属于该该方法的作用域，并且提升时在当前作用域的最顶端，即：

```
foo();

function foo() {
  var a;
	console.log( a ); // undefined
	a = 2;
}
```

case1-4:

```
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

```
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

```
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

- 浏览器中的事件循环

这要从`js为什么是单线程而ajax又是异步`的说起。

当前javascript运行在v8引擎中，v8里面有方法执行栈，有内存堆，还有web api，其中web api就包含了DOM, ajax，setTimeout等等。

js运行时，首先会分析js代码片段，生成调用栈，栈描述了函数调用顺序，异步调用不会放在栈中，首先会放在event table里，而后根据event table里的事件来分析谁应该先放到event queue里，这还会有一个event loop，它主要是用来监测调用栈，当发现调用栈为空时则会去event queue里取一个事件放入栈中执行.

> PS: setTimeout里的时间只是表明多久后会被加入到event queue里面。

** task vs micro-task **

如下demo:

```
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

a)点击child后会进入事件回调1处，2处直接入栈执行,3为异步调用入tasks队列，4处是特殊的异步进入micro-tasks队列，5和1类似，直接输出。

b)第一次的onClick代码执行完毕，栈空。取出micro-tasks里的promise callback入栈，执行后出栈，栈空。

c)此时child的点击导致了冒泡，冒泡的callback回来了，再次执行a),b)

d)第二次的onClick完成后，栈空，此时tasks队列里仍然有两个setTimeout没有执行，入栈执行，完毕。


若把上面例子里的setTimeout改为:

```
setTimeout(() => {
	console.log('setTimeout');
	Promise.resolve()
		.then(() => console.log('promise1'))    			
}, 0);
```

那么里面的promise一定是跟着对应的setTimeout按顺序输出：

```
setTimeout
promise1
setTimeout
promise1
```

总结：

1.setTimeout, setInterval等属于task（宏任务）

2.promise,async属于（微任务）

3.每当栈空后会从tasks队列里取出宏任务执行，每次执行完一个宏任务，都会去执行微任务。

4.事件callback比较特殊，微任务也会在其之后执行。

[参考](https://jakearchibald.com/2015/tasks-microtasks-queues-and-schedules/)


- Node.js中的事件循环(todo)

### 3.substr vs substring

`substr`: (start, length)

`substring`: (start, end)


### 4.preventDefault, stopPropagation, return false

`return false`: 一般用于jquery，对原生事件并无太大意义

`preventDefault`: 阻止默认行为，如a标签的跳转，checkbox的勾选等

`stopPropagation`: 阻止冒泡

### 5. new A() vs A()

```
function A(name) {
  this.name = name;
	return this;
}

let a1 = new A('Kelvin1');
let a2 = A('Kelvin2');

console.log(a1, a2);
```

对于a1: new关键字会寻找构造函数上原型对象里的constructor属性进行构建当前实例，并把当前对象指向this，若不返回结果则默认返回this。此外`a1 instanceof A`返回true，因为a1的原型链指向A的原型对象。

new一个对象实际上干了三件事:

```
var obj = {};
A.apply(obj, arguments);
obj.__proto__ = A.prototype;
```

对于a2: 必须显式的`return this`，否则返回undefined;此外由于在外部调用，则this默认指向window(browser)/global(node)，a2与A没有任何关系，必然也不是其实例, 它的原型链直接指向了Object的原型；

那么如果怎么让a2成为真正的A的实例呢：

```
let a2 = A.call({}, 'reall a2');
a2.__prop__ = A.proptotype;
```

### 6. Object.create(obj)

Object.create会将新创建的对象的原型链指向obj，所以可以这样实现

```
function create(obj) {
	function T() {}
	T.prototype = obj;
	return new T();
}
```

因此，Object.create常常用在组合继承的方式里，类似

```
Man.prototype = Object.create(Person.prototype);
```

这样的话一旦执行new Man(), 该实例的原型链上必然可以找到基类构造器的原型对象，instanceof的话必然就是true了。

### 7. Object.defineProperty vs Proxy

`Object.defineProperty`: ES6之前，实现对象属性监控的最佳手法，兼容IE，最大的弊端在于一次只能监控已有对象的一个属性，且无法监控数组。

`Proxy`: ES6的产物，算是前者的enhancement，可监控数组变化，且捕捉的行为也比较多，直接捕获的是target本身，所以灵活性很强。（性能未知）

### 8. 防抖和节流

防抖（debounce）：多次连续行为，只执行最后一次（即t时间内没有下一次）。

```
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

```
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

```
function B(name) {
	A.apply(this, arguments)
}
```

- 2.让A的原型对象出现在b的原型链上

```
B.prototype = Object.create(A.prototype);
```
这里可得: `b.__proto__` -> `B.prototype` -> `B.prototype.__proto__` -> `A.prototype`

因此 `b instanceof A` 成立。

- 3.恢复b的构造器

`B.prototype`原本内部是有`constructor`属性（指向Man)，第2步修改原型链时把`constructor`属性给覆盖了，所以需要重置(注：constructor的修改不会影响instanceof的结果)。

```
B.prototype.constructor = B;
```

- 基于以上提炼继承的最佳方案：


```
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

箭头函数：在调用处向上寻找作用域，若找不到则返回window

事件：this指向事件绑定元素(target为事件触发元素，currentTarget才是事件绑定元素);setTimeout依然遵循事件绑定，为全局绑定。


### 11. async vs Promise

若在一个方法内调用`await`，则必须显式的标注该方法为`aysnc`，这是最基本的用法。

- 但执行异步方法时可以直接调用

```
let getData = () => Promise.reject('res');
let fn = async () => await getData();
fn();

//Promise {<fulfilled>: "res"}
```
- 如果不在async里await呢

```
let fn = async () => 'async fn';
fn();

//Promise {<fulfilled>: "async fn"}
```

可以得出：async会返回一个promise，这个promise的结果就是await的结果，所以就算是await里抛了异常，那外部依然可以接住。

- await后面的代码

```
let getData = () => Promise.reject('res');//1
let fn = async () => {
	await getData();
	console.log('======after await=======');//2
};
fn();
```

此代码2处并不会打印，因为await解析出来的promise有异常。

若1处改为：

```
let getData = () => Promise.resolve('res');//1
```

则可以输出log

可是我一不小心手误，将1处写为

```
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

> ps:需要注意的是，尽管await会处理promise，但是如果没有在await之前显式的调用return，那么外部是无法获取到await的结果的。

### 12. Closure

闭包：当前函数f和其周围此法作用域形成依赖关系，导致f可以访问到外部变量，因此形闭包。

优点：

- 1.私有变量

```
function Person() {
	var name = 'Kelvin'
	this.getName = function() {
		return name;
	}
}
```

- 2.柯里化

```
function add(x) {
	return function(y) {
		return x + y;
	}
}
const add1 = add(1);
const add2 = add(2);
```

- 3.缓存(持久化)

```
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

```
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

```
class NumberType {
	static [Symbol.hasInstance](instance) {
		return typeof instance === 'number';
	}
}
```
```
111 instanceof Number; // false

111 instanceof NumberType; // true
```

因此我们可以修改任意构造函数的`[Symbol.hasInstance]`，从而改变`instanceof`的逻辑，上面的代码使用了静态类型，`Babel`转译后其实就是构造函数的属性：

```
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

```
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

```
function isFunction(value) {
	return typeof fn === 'function';
}
```

`isString`

暴力写法：
```
function isString(value) {
	return Object.prototype.toString.call(value) === '[object String]';
}
```

考虑到原型链的安全性，lodash的优化：

```
function isString(value) {
  const type = typeof value
  return type === 'string' || 
	(type === 'object' && value != null && !Array.isArray(value) && Object.prototype.toString.call(value) === '[object String]')
}
```

`isObject`

```
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

```
Function.prototype._call = function(context, ...args) {
	const sym = Symbol('');
	context[sym] = this;
	const result = context[sym](...args);
	delete context[sym];
	return result;
}

```

`apply`


```
Function.prototype._apply = function(context, args) {
	return this._call(context, ...args);
}

```

`bind`

```
Function.prototype._bind = function(context, ...args) {
	return function(...nextArgs) {
		return this._call(context, ...args, ...nextArgs);
	}
}
```

测试：

```
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