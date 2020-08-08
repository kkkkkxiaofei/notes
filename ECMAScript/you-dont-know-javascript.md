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

### 2.xss vs csrf

xss一般主要是html类型的的脚本被上传至服务器，而后其他用户访问到相关资源后会执行该脚本，从而产生数据安全隐患。
措施：检测脚本

csrf一般指A网站里有B网站的广告（第三方），正常情况下，A站点的操作对应的是A'的服务器，而对广告这里，如果后端设置了允许第三方cookie的话，那么在A站点浏览该广告后，会把B站点的cookie带到本地（第三方cookie），但是之后所有请求都应该保持cookie同源策略。此时如果这个广告里有一个攻击脚本，该脚本会模拟用户去访问A'，那这样的话，就会把A站点之前的cookie带过去，就会让A'无以为这是A，从而为此敞开大门，为所欲为。

`措施`:

1.Samesite属性，Strict（只第一方带cookie），Lax(第三方的get会带cookie），None（都带），所以大部分情况将samesite设置为Lax并且请求改为post即可

2.增加身份认证，其实B站点的攻击脚本并不能拿到A请求里的信息，只依赖于cookie，如果可以增加更多的信息来认证client的话也是可以的，比如origin, csrf-token

3.本质上1可以解决很多，但是如果真有攻击脚本的话，应该避免xss，这样也就无法注入其他类似iframe的东西了

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

对于a1: new关键字会创建当前实例，并指向this，若不返回结果则默认返回this。此外`a1 instanceof A`返回true，因为a1的原型链指向A的原型对象。

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