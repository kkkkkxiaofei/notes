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
